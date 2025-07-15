import 'package:sighttrack/barrel.dart';

import 'package:flutter/material.dart';

class AreaCaptureHome extends StatefulWidget {
  const AreaCaptureHome({super.key});

  @override
  State<AreaCaptureHome> createState() => _AreaCaptureHomeState();
}

class _AreaCaptureHomeState extends State<AreaCaptureHome>
    with WidgetsBindingObserver {
  UserSettings? _userSettings;
  String _timeRemaining = '';
  Timer? _timer;
  List<Map<String, dynamic>> _sessionSightings = [];
  CameraController? _cameraController;
  late FToast fToast;
  bool _isProcessingImage = false;

  @override
  void initState() {
    super.initState();
    _initializeWrapper();
    WidgetsBinding.instance.addObserver(this);

    fToast = FToast();
    fToast.init(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initializeWrapper();
    }
  }

  Future<void> _stopAreaCapture() async {
    await _saveSessionSightings();
    setState(() => _timeRemaining = '');
    _timer?.cancel();
    final deactivatedSettings = _userSettings!.copyWith(
      isAreaCaptureActive: false,
      areaCaptureEnd: null,
    );
    await Amplify.DataStore.save(deactivatedSettings);
    _userSettings = deactivatedSettings;
    _sessionSightings.clear();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _initializeWrapper() async {
    _userSettings = await Util.getUserSettings();
    setState(() {
      _startTimer();
    });
    if (_userSettings != null && _userSettings?.isAreaCaptureActive == false) {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  void _startTimer() {
    if (_timer?.isActive ?? false) return;
    if (_userSettings?.isAreaCaptureActive == true) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _updateTimeRemaining(),
      );
    }
  }

  // Future<void> _takePhoto() async {
  //   try {
  //     await _initializeCameraFuture;
  //     final photo = await _cameraController!.takePicture();
  //     final position = await Util.getCurrentPosition();
  //     final now = DateTime.now();
  //     final key = 'photos/${UUID.getUUID()}.jpg';
  //     final sighting = Sighting(
  //       species: await Util.doAWSRekognitionCall(
  //         photo.path,
  //       ).then((value) => value[0]),
  //       photo: key,
  //       latitude: position.latitude,
  //       longitude: position.longitude,
  //       displayLatitude: position.latitude,
  //       displayLongitude: position.longitude,
  //       city: await Util.getCityName(position.latitude, position.longitude),
  //       timestamp: TemporalDateTime(now),
  //       description: 'Captured during area capture session',
  //       isTimeClaimed: false,
  //     );
  //     setState(() {
  //       _sessionSightings.add({'sighting': sighting, 'localPath': photo.path});
  //     });
  //     Amplify.Storage.uploadFile(
  //       localFile: AWSFile.fromPath(photo.path),
  //       path: StoragePath.fromString(key),
  //     );
  //   } catch (e) {
  //     fToast.showToast(
  //       child: Util.redToast('You\'re camera isn\'t working'),
  //       gravity: ToastGravity.BOTTOM,
  //       toastDuration: Duration(seconds: 3),
  //     );
  //   }
  // }

  Future<void> _updateTimeRemaining() async {
    if (_userSettings?.areaCaptureEnd == null) {
      setState(() => _timeRemaining = '');
      _timer?.cancel();
      return;
    }

    final endTime = _userSettings!.areaCaptureEnd!.getDateTimeInUtc();
    final now = DateTime.now().toUtc();
    final difference = endTime.difference(now);

    if (difference.isNegative) {
      _stopAreaCapture();
      return;
    }

    final minutes = difference.inMinutes;
    final seconds = difference.inSeconds % 60;
    setState(
      () => _timeRemaining = '$minutes:${seconds.toString().padLeft(2, '0')}',
    );
  }

  Future<void> _saveSessionSightings() async {
    try {
      final user = await Util.getUserModel();

      for (var entry in _sessionSightings) {
        Sighting sighting = entry['sighting'] as Sighting;
        final updatedSighting = sighting.copyWith(user: user);
        await Amplify.DataStore.save(updatedSighting);
      }
    } catch (e) {
      Log.e('AC SAVE ERROR: $e');
      rethrow;
    }
  }

  Future<void> _addSightingToSession(Map<String, dynamic> sightingData) async {
    if (!mounted) return;

    setState(() {
      _isProcessingImage = true;
    });

    try {
      // Extract sighting and local path from the data
      final sighting = sightingData['sighting'] as Sighting;
      final localPath = sightingData['localPath'] as String;

      // Add to session sightings
      if (mounted) {
        setState(() {
          _sessionSightings.add({'sighting': sighting, 'localPath': localPath});
          _isProcessingImage = false;
        });
      }

      // Upload to S3
      Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(localPath),
        path: StoragePath.fromString(sighting.photo),
      );

      // Show success feedback
      if (mounted) {
        try {
          fToast.init(context);
          fToast.showToast(
            child: Util.greenToast('Sighting added to session!'),
            gravity: ToastGravity.BOTTOM,
            toastDuration: Duration(seconds: 2),
          );
        } catch (e) {
          // Fallback - just log if toast fails
          Log.d('Toast failed: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
        });
      }
      Log.e('Error adding sighting to session: $e');
      if (mounted) {
        try {
          fToast.init(context);
          fToast.showToast(
            child: Util.redToast('Failed to add sighting to session'),
            gravity: ToastGravity.BOTTOM,
            toastDuration: Duration(seconds: 3),
          );
        } catch (toastError) {
          // Fallback - just log if toast fails
          Log.d('Toast failed: $toastError');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 40,
                        child: Stack(
                          children: [
                            // Centered title
                            Center(
                              child: Text(
                                'Area Capture',
                                style:
                                    Theme.of(context).textTheme.headlineLarge,
                              ),
                            ),
                            // Right-aligned info icon
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: IconButton(
                                icon: Icon(
                                  Icons.stop_circle_outlined,
                                  size: 28,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () async {
                                  final shouldStop = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(
                                          'Stop Area Capture',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        content: Text(
                                          'Are you sure you want to stop the area capture session? All captured photos will be saved.',
                                          // style:
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                            child: Text(
                                              'Stop',
                                              style: TextStyle(
                                                color: Colors.redAccent,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (shouldStop == true) {
                                    await _stopAreaCapture();
                                  }
                                },
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints.tightFor(
                                  width: 40,
                                  height: 40,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      // Timer Container
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child:
                            _userSettings == null
                                ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        // valueColor: AlwaysStoppedAnimation<
                                        //   Color
                                        // >(Colors.white.withValues(alpha: 0.7)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Loading...',
                                      style: TextStyle(
                                        // color: Colors.white.withValues(
                                        //   alpha: 0.7,
                                        // ),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                )
                                : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      color: Colors.blue.withValues(alpha: 0.8),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Time Remaining: ',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                    ),
                                    Text(
                                      _timeRemaining,
                                      // style: const TextStyle(
                                      //   color: Colors.blue,
                                      //   fontSize: 18,
                                      //   fontWeight: FontWeight.w600,
                                      //   fontFeatures: [
                                      //     FontFeature.tabularFigures(),
                                      //   ],
                                      // ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: Colors.blue),
                                    ),
                                  ],
                                ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Photos Section
                if (_sessionSightings.isEmpty && !_isProcessingImage)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'No photos captured yet',
                          style: TextStyle(
                            // color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap "Take Photo" below to start capturing',
                          style: TextStyle(
                            // color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header
                        Row(
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              // color: Colors.white.withValues(alpha: 0.9),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Session Photos',
                              style: TextStyle(
                                // color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${_sessionSightings.length}',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (_isProcessingImage) ...[
                              const Spacer(),
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Processing...',
                                style: TextStyle(
                                  color: Colors.blue.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Photo Grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1,
                              ),
                          itemCount:
                              _sessionSightings.length +
                              (_isProcessingImage ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Show loading placeholder if processing
                            if (_isProcessingImage &&
                                index == _sessionSightings.length) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white.withValues(
                                                  alpha: 0.7,
                                                ),
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Processing',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final localPath =
                                _sessionSightings[index]['localPath'] as String;
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      File(localPath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          color: Colors.grey.withValues(
                                            alpha: 0.2,
                                          ),
                                          child: Icon(
                                            Icons.broken_image,
                                            color: Colors.white.withValues(
                                              alpha: 0.5,
                                            ),
                                            size: 24,
                                          ),
                                        );
                                      },
                                    ),
                                    // Gradient overlay
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.3),
                                          ],
                                          stops: const [0.5, 1.0],
                                        ),
                                      ),
                                    ),
                                    // Index number
                                    Positioned(
                                      bottom: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.7,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Take Photo Button
                DarkButton(
                  text: 'Take Photo',
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CaptureScreen(isAreaCapture: true),
                      ),
                    );

                    // Handle the returned sighting data
                    if (result != null && result is Map<String, dynamic>) {
                      await _addSightingToSession(result);
                    }
                  },
                ),

                const SizedBox(height: 34),

                // Info Section
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      // color: Colors.amber.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AutoSizeText(
                        'Please don\'t restart or exit the app while in area capture mode to avoid losing your photos',
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
