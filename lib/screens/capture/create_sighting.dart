import 'package:sighttrack/barrel.dart';

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:sighttrack/screens/capture/map_picker.dart';

class CreateSightingScreen extends StatefulWidget {
  final String imagePath;

  const CreateSightingScreen({super.key, required this.imagePath});

  @override
  State<CreateSightingScreen> createState() => _CreateSightingScreenState();
}

class _CreateSightingScreenState extends State<CreateSightingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  geo.Position? _selectedLocation;
  String? _selectedSpecies;
  List<String>? identifiedSpecies;
  UserSettings? _userSettings;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initializerWrapper();
  }

  Future<void> _initializerWrapper() async {
    List<String>? temp = await Util.doAWSRekognitionCall(widget.imagePath);
    if (temp.isNotEmpty) {
      setState(() {
        identifiedSpecies = temp;
        _selectedSpecies = temp[0];
      });
    }

    final fetchSettings = await Util.getUserSettings();
    setState(() {
      _userSettings = fetchSettings;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      geo.Position position = await Util.getCurrentPosition();
      setState(() {
        _selectedLocation = position;
        Log.i(
          'Initial location set: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}',
        );
      });
    } catch (e) {
      Log.e('Error getting location: $e');
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (pickedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _saveSighting() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Get the current authenticated user
        final authUser = await Amplify.Auth.getCurrentUser();
        final userId = authUser.userId;

        // Search DataStore for the user based on Cognito id
        final users = await Amplify.DataStore.query(
          User.classType,
          where: User.ID.eq(userId),
        );

        User currentUser;
        if (users.isEmpty) {
          // User not found, create a new one (For good practice, shouldn't have to be run)
          final userAttributes = await Amplify.Auth.fetchUserAttributes();
          final emailAttribute = userAttributes.firstWhere(
            (attr) => attr.userAttributeKey.toString() == 'email',
            orElse: () => throw Exception('Email not found in user attributes'),
          );
          final email = emailAttribute.value;

          currentUser = User(
            id: userId,
            display_username: email,
            email: email,
            // Optional fields are defaulted to null
          );
          await Amplify.DataStore.save(currentUser);
          Log.i('Created new user: ${currentUser.id}');
        } else {
          currentUser = users.first;
          Log.i('Found existing user: ${currentUser.id}');
        }

        // Proceed with saving the sighting
        final sightingId = UUID.getUUID();
        final fileExtension = widget.imagePath.split('.').last;
        final s3Key = 'photos/$sightingId.$fileExtension';

        await Amplify.Storage.uploadFile(
          localFile: AWSFile.fromPath(widget.imagePath),
          path: StoragePath.fromString(s3Key),
          onProgress: (progress) {
            Log.i('Upload progress: ${progress.fractionCompleted}');
          },
        ).result;
        Log.i('Image uploaded to S3 with key: $s3Key');

        final settings = await Util.getUserSettings();
        final shouldOffset = settings?.locationOffset ?? false;
        double? displayLat;
        double? displayLng;

        if (shouldOffset) {
          final random = Random();
          const offsetRange = 0.001;
          final latOffset =
              (random.nextDouble() * offsetRange * 2) - offsetRange;
          final lngOffset =
              (random.nextDouble() * offsetRange * 2) - offsetRange;
          displayLat = _selectedLocation!.latitude + latOffset;
          displayLng = _selectedLocation!.longitude + lngOffset;
        }

        final sighting = Sighting(
          id: sightingId,
          species: _selectedSpecies!,
          photo: s3Key,
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
          displayLatitude: displayLat,
          displayLongitude: displayLng,
          timestamp: TemporalDateTime(_selectedDateTime),
          description: _descriptionController.text,
          user: currentUser,
        );

        await Amplify.DataStore.save(sighting);
        Log.i('Sighting saved. ID: $sightingId');

        if (!mounted) return;
        Navigator.popUntil(context, (route) => route.isFirst);
      } catch (e) {
        Log.e('Error saving sighting: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving sighting: $e')));
        }
      }
    }
  }

  Future<void> _openMapPicker(BuildContext context) async {
    final geo.Position? newLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MapPickerScreen(initialPosition: _selectedLocation),
      ),
    );
    if (newLocation != null) {
      Log.i(
        'New location from picker: ${newLocation.latitude}, ${newLocation.longitude}',
      );
      setState(() {
        _selectedLocation = newLocation;
      });
    } else {
      Log.w('No new location returned from picker');
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Sighting'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) {
                        return Dialog(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          insetPadding: const EdgeInsets.all(16),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.9,
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.9,
                            ),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Image.file(
                                  File(widget.imagePath),
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.error,
                                            color: Colors.red,
                                            size: 48,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Error loading image',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black54,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Error loading image',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: _selectedSpecies,
                  decoration: InputDecoration(
                    labelText: 'Species*',
                    labelStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.greenAccent,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: Colors.grey[850],
                  items:
                      identifiedSpecies?.map((String species) {
                        return DropdownMenuItem<String>(
                          value: species,
                          child: Text(species),
                        );
                      }).toList() ??
                      [],
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSpecies = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a species';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Provide details about the sighting',
                    labelStyle: const TextStyle(color: Colors.white),
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.greenAccent,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date & Time*',
                    suffixIcon: const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                    ),
                    labelStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.greenAccent,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onTap: () => _selectDateTime(context),
                  controller: TextEditingController(
                    text: DateFormat(
                      'MMMM d, yyyy, h:mm a',
                    ).format(_selectedDateTime),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _openMapPicker(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedLocation != null
                                ? 'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}'
                                : 'Fetching location...',
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.map, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _userSettings?.locationOffset ?? false
                      ? 'Location offset is ON'
                      : 'Location offset is OFF',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _saveSighting,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save', style: TextStyle(fontSize: 16)),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
