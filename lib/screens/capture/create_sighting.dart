import 'package:sighttrack/barrel.dart';

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:sighttrack/screens/capture/change_sighting_location.dart';
import 'package:sighttrack/services/cv.dart';

class CreateSightingScreen extends StatefulWidget {
  final String imagePath;
  final bool isAreaCapture;

  const CreateSightingScreen({
    super.key,
    required this.imagePath,
    this.isAreaCapture = false,
  });

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
  bool _isSaving = false;
  FToast? _toast;
  bool _isIdentifying = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initializerWrapper();
    _toast = FToast();
    _toast!.init(context);
  }

  Future<void> _initializerWrapper() async {
    // Use the new CV service
    final cvInstance = ComputerVisionInstance();

    List<String> species = await cvInstance.startImageIdentification(
      widget.imagePath,
    );

    setState(() {
      _isIdentifying = false;
    });

    // if (rekognitionResponse.isNotEmpty) {
    //   // Filter images that are not animals or plants
    //   if (!rekognitionResponse.contains('animal') &&
    //       !rekognitionResponse.contains('plant')) {
    //     _toast!.showToast(
    //       child: Util.redToast(
    //         'Please make sure the image is\n of an animal or plant',
    //       ),
    //       gravity: ToastGravity.CENTER,
    //       toastDuration: const Duration(seconds: 3),
    //     );
    //     if (mounted) {
    //       Navigator.pop(context);
    //     }
    //     return;
    //   }
    setState(() {
      identifiedSpecies = species;
      _selectedSpecies = species[0];
    });
    // }

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

    if (!context.mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
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
    if (_isSaving) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
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

        // Proceed with creating the sighting
        final sightingId = UUID.getUUID();
        final fileExtension = widget.imagePath.split('.').last;
        final s3Key = 'photos/$sightingId.$fileExtension';

        // For area capture, we don't upload to S3 yet or save to datastore
        if (!widget.isAreaCapture) {
          await Amplify.Storage.uploadFile(
            localFile: AWSFile.fromPath(widget.imagePath),
            path: StoragePath.fromString(s3Key),
            onProgress: (progress) {
              Log.i('Upload progress: ${progress.fractionCompleted}');
            },
          ).result;
          Log.i('Image uploaded to S3 with key: $s3Key');
        }

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
          city: await Util.getCityName(
            _selectedLocation!.latitude,
            _selectedLocation!.longitude,
          ),
          displayLatitude: displayLat,
          displayLongitude: displayLng,
          timestamp: TemporalDateTime(_selectedDateTime),
          description: _descriptionController.text,
          user: currentUser,
          isTimeClaimed: false,
        );

        if (widget.isAreaCapture) {
          // For area capture, return the sighting data and image path
          final sightingData = {
            'sighting': sighting,
            'localPath': widget.imagePath,
          };

          if (mounted) {
            Navigator.pop(context, sightingData);
          }
        } else {
          // For regular capture, save to datastore and navigate home
          await Amplify.DataStore.save(sighting);
          Log.i('Sighting saved. ID: $sightingId');

          if (!mounted) return;
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } catch (e) {
        Log.e('Error saving sighting: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving sighting: $e')));
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isAreaCapture ? 'Add to Area Capture' : 'Create Sighting',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      backgroundColor: theme.colorScheme.surface,
      body:
          _isIdentifying
              ? _buildLoadingUI(theme)
              : GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Section with modern card design
                        _buildImageSection(theme),
                        const SizedBox(height: 24),

                        // Form Fields Section
                        _buildFormSection(theme),
                        const SizedBox(height: 24),

                        // Location Section
                        _buildLocationSection(theme),
                        const SizedBox(height: 24),

                        // Action Buttons
                        _buildActionButtons(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildLoadingUI(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          const SizedBox(height: 60),

          // Image preview section
          _buildLoadingImagePreview(theme),

          const SizedBox(height: 60),

          // Animated loading states
          Expanded(child: _buildAnimatedLoadingStates(theme)),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLoadingImagePreview(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.file(
            File(widget.imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                child: Icon(
                  Icons.image,
                  size: 60,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLoadingStates(ThemeData theme) {
    return _buildIdentifyingLoadingState(theme);
  }

  Widget _buildIdentifyingLoadingState(ThemeData theme) {
    return Container(
      key: const ValueKey('identifying'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated AI brain icon
          TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 2),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * 2 * pi,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          // Main loading text with typewriter effect
          _buildTypewriterText(
            'Identifying Image...',
            theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ) ??
                const TextStyle(),
            theme,
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            'AI is analyzing the visual features',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTypewriterText(String text, TextStyle style, ThemeData theme) {
    return TweenAnimationBuilder<int>(
      duration: Duration(milliseconds: text.length * 50),
      tween: IntTween(begin: 0, end: text.length),
      builder: (context, value, child) {
        return Text(
          text.substring(0, value),
          style: style,
          textAlign: TextAlign.center,
        );
      },
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Captured Image',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showImageDialog(context),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Error loading image',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
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
      ],
    );
  }

  Widget _buildFormSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sighting Details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),

        // Species Dropdown
        DropdownButtonFormField<String>(
          value: _selectedSpecies,
          decoration: InputDecoration(
            labelText: 'Species*',
            prefixIcon: Icon(
              Icons.pets,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          style: theme.textTheme.bodyLarge,
          dropdownColor: theme.colorScheme.surface,
          isExpanded: true,
          items:
              identifiedSpecies?.map((String species) {
                return DropdownMenuItem<String>(
                  value: species,
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      species,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
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

        // Description Field
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText:
                  'Describe the behavior, habitat, or any interesting details you observed...',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              // prefixIcon: Padding(
              //   padding: const EdgeInsets.only(top: 12.0),
              //   child: Icon(
              //     Icons.edit_note,
              //     color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              //   ),
              // ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              alignLabelWithHint: true,
            ),
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
            maxLines: 4,
            minLines: 3,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        const SizedBox(height: 16),

        // Date & Time Field
        TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Date & Time*',
            prefixIcon: Icon(
              Icons.schedule,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          style: theme.textTheme.bodyLarge,
          onTap: () => _selectDateTime(context),
          controller: TextEditingController(
            text: DateFormat('MMMM d, yyyy, h:mm a').format(_selectedDateTime),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        // Location Display/Picker
        GestureDetector(
          onTap: () => _openMapPicker(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedLocation != null
                        ? 'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}'
                        : 'Fetching location...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.edit_location_alt,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Location Offset Status
        Row(
          children: [
            Icon(
              (_userSettings?.locationOffset ?? false)
                  ? Icons.shuffle
                  : Icons.gps_fixed,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              (_userSettings?.locationOffset ?? false)
                  ? 'Location offset: ON'
                  : 'Location offset: OFF',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: DarkButton(
            text:
                _isSaving
                    ? (widget.isAreaCapture ? 'Adding...' : 'Saving...')
                    : (widget.isAreaCapture
                        ? 'Add to Session'
                        : 'Save Sighting'),
            width: double.infinity,
            height: 56,
            onPressed: _isSaving ? () {} : _saveSighting,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DarkButton(
            text: 'Cancel',
            width: double.infinity,
            height: 56,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  void _showImageDialog(BuildContext context) {
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
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
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
                                Icons.error_outline,
                                color: Colors.white,
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
                Positioned(
                  right: 12,
                  top: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
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
  }
}
