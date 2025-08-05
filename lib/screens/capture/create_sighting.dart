import 'package:sighttrack/barrel.dart';
import 'package:core_ui/core_ui.dart';

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
  bool _isManualSpeciesCorrected = false;

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
      _isManualSpeciesCorrected =
          false; // Reset flag when AI species are loaded
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

  Future<String?> _showCustomSpeciesDialog(BuildContext context) async {
    final textController = TextEditingController();
    final theme = Theme.of(context);

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isProcessing = false;

            Future<void> processSpecies() async {
              final inputSpecies = textController.text.trim();
              if (inputSpecies.isEmpty) return;

              setState(() {
                isProcessing = true;
              });

              try {
                // Use CV service to autocorrect the manual input
                final cvInstance = ComputerVisionInstance();
                final correctedSpecies = await cvInstance
                    .startManualAutocorrection(inputSpecies);

                if (correctedSpecies != 'NONE' && correctedSpecies.isNotEmpty) {
                  Navigator.of(context).pop(correctedSpecies);
                } else {
                  // If autocorrection fails, use the original input
                  Navigator.of(context).pop(inputSpecies);
                }
              } catch (e) {
                Log.e('Error during species autocorrection: $e');
                // If error occurs, use the original input
                Navigator.of(context).pop(inputSpecies);
              }
            }

            return AlertDialog(
              title: Text(
                'Enter Species Name',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Type the species name (AI will help correct any errors):',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    autofocus: true,
                    enabled: !isProcessing,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'e.g., Red-tailed Hawk',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty && !isProcessing) {
                        processSpecies();
                      }
                    },
                  ),
                  if (isProcessing) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'AI is correcting species name...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isProcessing ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color:
                          isProcessing
                              ? theme.colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              )
                              : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      isProcessing
                          ? null
                          : () {
                            final species = textController.text.trim();
                            if (species.isNotEmpty) {
                              processSpecies();
                            }
                          },
                  child:
                      isProcessing
                          ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          )
                          : Text(
                            'Add',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ],
            );
          },
        );
      },
    );
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
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: ExpandableLocalImage(
        imagePath: widget.imagePath,
        height: 200,
        width: double.infinity,
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 2),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 2 * pi,
                  child: const Icon(
                    Icons.psychology_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                );
              },
            ),
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
            letterSpacing: 0.15,
          ),
        ),
        const SizedBox(height: 16),
        ExpandableLocalImage(
          imagePath: widget.imagePath,
          height: 200,
          width: double.infinity,
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

        // Species Dropdown with custom option
        DropdownButtonFormField<String>(
          key: ValueKey(
            _selectedSpecies,
          ), // Force rebuild when selected species changes
          value:
              (identifiedSpecies?.contains(_selectedSpecies) ?? false)
                  ? _selectedSpecies
                  : null,
          decoration: InputDecoration(
            labelText: 'Species*',
            prefixIcon: Icon(
              Icons.pets_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
          style: theme.textTheme.bodyLarge,
          dropdownColor: theme.colorScheme.surface,
          isExpanded: true,
          hint:
              _selectedSpecies != null &&
                      !(identifiedSpecies?.contains(_selectedSpecies) ?? false)
                  ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedSpecies!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                  : null,
          items: [
            // AI identified species
            ...(identifiedSpecies?.map((String species) {
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
                []),
            // Custom option
            DropdownMenuItem<String>(
              value: 'custom',
              child: Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Enter custom species...',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (String? newValue) async {
            if (newValue == 'custom') {
              final customSpecies = await _showCustomSpeciesDialog(context);
              if (customSpecies != null && customSpecies.isNotEmpty) {
                setState(() {
                  _selectedSpecies = customSpecies;
                  _isManualSpeciesCorrected = true;
                });
              } else {
                // If user cancels or enters empty string, revert to current selection
                setState(() {
                  // Force a rebuild to reset the dropdown state
                });
              }
            } else {
              setState(() {
                _selectedSpecies = newValue;
                _isManualSpeciesCorrected = false;
              });
            }
          },
          validator: (value) {
            if (_selectedSpecies == null || _selectedSpecies!.isEmpty) {
              return 'Please select or enter a species';
            }
            return null;
          },
        ),

        // Show custom species indicator
        if (_selectedSpecies != null &&
            !(identifiedSpecies?.contains(_selectedSpecies) ?? false))
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Row(
              children: [
                Icon(
                  _isManualSpeciesCorrected
                      ? Icons.auto_fix_high_outlined
                      : Icons.edit_outlined,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  _isManualSpeciesCorrected
                      ? 'Auto-corrected species name'
                      : 'Custom species entered',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
          child: Text(_selectedSpecies!),
        ),
        const SizedBox(height: 16),

        // Description Field
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText:
                'Describe the behavior, habitat, or any interesting details you observed...',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.all(16),
            alignLabelWithHint: true,
          ),
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
          maxLines: 4,
          minLines: 3,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),

        // Date & Time Field
        TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Date & Time*',
            prefixIcon: Icon(
              Icons.schedule_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            suffixIcon: Icon(
              Icons.keyboard_arrow_down,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
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
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
              color: theme.colorScheme.surface,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
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
                  Icons.edit_outlined,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Location Offset Status
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                (_userSettings?.locationOffset ?? false)
                    ? Icons.shuffle_outlined
                    : Icons.gps_fixed_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                (_userSettings?.locationOffset ?? false)
                    ? 'Location offset: ON'
                    : 'Location offset: OFF',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Flexible(
          flex: 1,
          child: DarkButton(
            text: 'Cancel',
            width: double.infinity,
            height: 56,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          flex: 2,
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
      ],
    );
  }
}
