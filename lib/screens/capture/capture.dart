import 'package:sighttrack/barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_cropper/image_cropper.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key, this.isAreaCapture = false});

  final bool isAreaCapture;

  @override
  CaptureScreenState createState() => CaptureScreenState();
}

class CaptureScreenState extends State<CaptureScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  late List<CameraDescription> _cameras;
  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  bool _isCameraInitialized = false;
  String? _errorMessage;
  FToast? _fToast;

  // Camera settings
  double _currentZoomLevel = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;

  // Focus
  Offset? _focusPoint;
  bool _showFocusBox = false;
  late AnimationController _focusAnimationController;
  late Animation<double> _focusScaleAnimation;
  late Animation<double> _focusOpacityAnimation;
  Timer? _focusTimer;

  // Capture button animations
  late AnimationController _captureButtonController;
  late Animation<double> _captureButtonScaleAnimation;
  late Animation<double> _captureButtonGlowAnimation;
  bool _isCaptureButtonPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _fToast = FToast();
    _fToast!.init(context);

    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _focusScaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _focusAnimationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _focusOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _focusAnimationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _captureButtonController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _captureButtonScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _captureButtonController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    _captureButtonGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _captureButtonController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (kDebugMode) {
          setState(() {
            _isCameraInitialized = true;
            _cameras = [];
            _maxAvailableZoom = 5.0;
            _minAvailableZoom = 1.0;
            _currentZoomLevel = 1.0;
          });
          return;
        }
        setState(() {
          _errorMessage = 'No cameras available on this device.';
        });
        return;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to access cameras: $e';
      });
      return;
    }

    _selectedCameraIndex = 0;
    await _setupCameraController();
  }

  Future<void> _setupCameraController() async {
    setState(() {
      _isCameraInitialized = false;
      _errorMessage = null;
    });

    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }

    if (_cameras.isEmpty && kDebugMode) {
      setState(() {
        _isCameraInitialized = true;
      });
      return;
    }

    _controller = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!
        .initialize()
        .then((_) async {
          _maxAvailableZoom = await _controller!.getMaxZoomLevel();
          _minAvailableZoom = await _controller!.getMinZoomLevel();
          _currentZoomLevel = _minAvailableZoom;

          setState(() {
            _isCameraInitialized = true;
          });
        })
        .catchError((e) {
          setState(() {
            _isCameraInitialized = false;
            _errorMessage = 'Failed to initialize camera: $e';
          });
        });
  }

  Future<void> _switchCamera() async {
    if (_cameras.isEmpty && kDebugMode) {
      HapticFeedback.lightImpact();
      return;
    }

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    HapticFeedback.lightImpact();
    await _setupCameraController();
  }

  Future<void> _toggleFlash() async {
    setState(() {
      if (_flashMode == FlashMode.off) {
        _flashMode = FlashMode.auto;
      } else if (_flashMode == FlashMode.auto) {
        _flashMode = FlashMode.always;
      } else {
        _flashMode = FlashMode.off;
      }
    });

    HapticFeedback.lightImpact();

    if (_cameras.isEmpty && kDebugMode) return;

    try {
      await _initializeControllerFuture;
      await _controller!.setFlashMode(_flashMode);
    } catch (e) {
      setState(() {
        _flashMode = FlashMode.off;
      });
    }
  }

  Future<void> _onTapToFocus(TapUpDetails details) async {
    if (!_isCameraInitialized) return;

    HapticFeedback.lightImpact();

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localOffset = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      _focusPoint = localOffset;
      _showFocusBox = true;
    });

    _focusAnimationController.reset();
    _focusAnimationController.forward();

    if (_cameras.isEmpty && kDebugMode) {
      _focusTimer?.cancel();
      _focusTimer = Timer(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _showFocusBox = false;
          });
        }
      });
      return;
    }

    try {
      final double x = localOffset.dx / renderBox.size.width;
      final double y = localOffset.dy / renderBox.size.height;
      await _controller!.setFocusPoint(Offset(x, y));
      await _controller!.setExposurePoint(Offset(x, y));
    } catch (e) {
      // Handle focus error
    }

    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _showFocusBox = false;
        });
      }
    });
  }

  Future<void> _capturePhoto() async {
    if (!_isCameraInitialized) return;

    HapticFeedback.mediumImpact();

    try {
      if (_cameras.isEmpty && kDebugMode) {
        const mockImagePath = 'simulator_test_image.jpg';
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PhotoPreviewScreen(
                  imagePath: mockImagePath,
                  isPortraitMode: false,
                  portraitBlurIntensity: 0.5,
                  isAreaCapture: widget.isAreaCapture,
                ),
          ),
        );
        return;
      }

      await _initializeControllerFuture;
      final image = await _controller!.takePicture();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PhotoPreviewScreen(
                imagePath: image.path,
                isPortraitMode: false,
                portraitBlurIntensity: 0.5,
                isAreaCapture: widget.isAreaCapture,
              ),
        ),
      );
    } catch (e) {
      // Handle capture error
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (image != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PhotoPreviewScreen(
                  imagePath: image.path,
                  isPortraitMode: false,
                  portraitBlurIntensity: 0.5,
                  isAreaCapture: widget.isAreaCapture,
                ),
          ),
        );
      }
    } catch (e) {
      // Handle gallery error
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (!_isCameraInitialized) return;

    final newZoomLevel = (_currentZoomLevel * details.scale).clamp(
      _minAvailableZoom,
      _maxAvailableZoom,
    );

    if (_cameras.isEmpty && kDebugMode) {
      setState(() {
        _currentZoomLevel = newZoomLevel.clamp(1.0, 5.0);
      });
      return;
    }

    _controller!.setZoomLevel(newZoomLevel);
    setState(() {
      _currentZoomLevel = newZoomLevel;
    });
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _focusAnimationController.dispose();
    _captureButtonController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          _buildCameraPreview(),

          // Focus Box
          _buildFocusBox(),

          // Top Controls
          _buildTopControls(),

          // Bottom Controls
          _buildBottomControls(),

          // Zoom Indicator
          if (_currentZoomLevel > _minAvailableZoom) _buildZoomIndicator(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (!_isCameraInitialized) {
      return _buildLoadingState();
    }

    return GestureDetector(
      onTapUp: _onTapToFocus,
      onScaleUpdate: _onScaleUpdate,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: _buildPreviewContent(),
      ),
    );
  }

  Widget _buildPreviewContent() {
    if (_cameras.isEmpty && kDebugMode) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withValues(alpha: 0.3),
              Colors.purple.withValues(alpha: 0.3),
              Colors.pink.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt,
                color: Colors.white.withValues(alpha: 0.8),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'CAMERA PREVIEW',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller!.value.previewSize?.height ?? 100,
        height: _controller!.value.previewSize?.width ?? 100,
        child: CameraPreview(_controller!),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Camera Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      ),
    );
  }

  Widget _buildFocusBox() {
    if (!_showFocusBox || _focusPoint == null) return const SizedBox.shrink();

    return Positioned(
      left: _focusPoint!.dx - 30,
      top: _focusPoint!.dy - 30,
      child: AnimatedBuilder(
        animation: _focusAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _focusScaleAnimation.value,
            child: Opacity(
              opacity: _focusOpacityAnimation.value,
              child: SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  children: [
                    // Top-left corner
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Color(0xFFFFD60A),
                              width: 1.5,
                            ),
                            left: BorderSide(
                              color: Color(0xFFFFD60A),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Top-right corner
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Color(0xFFFFD60A),
                              width: 1.5,
                            ),
                            right: BorderSide(
                              color: Color(0xFFFFD60A),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Bottom-left corner
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFFFD60A),
                              width: 1.5,
                            ),
                            left: BorderSide(
                              color: Color(0xFFFFD60A),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Bottom-right corner
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFFFD60A),
                              width: 1.5,
                            ),
                            right: BorderSide(
                              color: Color(0xFFFFD60A),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Close Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),

              // Flash Button
              GestureDetector(
                onTap: _toggleFlash,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _flashMode == FlashMode.off
                        ? Icons.flash_off
                        : _flashMode == FlashMode.auto
                        ? Icons.flash_auto
                        : Icons.flash_on,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 140 + MediaQuery.of(context).padding.bottom,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gallery Button
              GestureDetector(
                onTap: _pickFromGallery,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),

              // Capture Button
              GestureDetector(
                onTapDown: (_) {
                  setState(() {
                    _isCaptureButtonPressed = true;
                  });
                  _captureButtonController.forward();
                  HapticFeedback.lightImpact();
                },
                onTapUp: (_) {
                  setState(() {
                    _isCaptureButtonPressed = false;
                  });
                  _captureButtonController.reverse();
                },
                onTapCancel: () {
                  setState(() {
                    _isCaptureButtonPressed = false;
                  });
                  _captureButtonController.reverse();
                },
                onTap: _capturePhoto,
                child: AnimatedBuilder(
                  animation: _captureButtonController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 - (_captureButtonScaleAnimation.value * 0.1),
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                              offset: const Offset(0, 3),
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(
                                alpha:
                                    0.1 +
                                    (_captureButtonGlowAnimation.value * 0.2),
                              ),
                              blurRadius: 12,
                              spreadRadius: 3,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white70,
                            border: Border.all(color: Colors.white, width: 6),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  _isCaptureButtonPressed
                                      ? Colors.grey[300]
                                      : Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Camera Switch Button
              GestureDetector(
                onTap: _switchCamera,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoomIndicator() {
    return Positioned(
      bottom: 180,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            '${_currentZoomLevel.toStringAsFixed(1)}x',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class PhotoPreviewScreen extends StatefulWidget {
  final String imagePath;
  final bool isPortraitMode;
  final double portraitBlurIntensity;
  final bool isAreaCapture;

  const PhotoPreviewScreen({
    super.key,
    required this.imagePath,
    required this.isPortraitMode,
    required this.portraitBlurIntensity,
    required this.isAreaCapture,
  });

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  String _currentImagePath = '';
  bool _isSimulatorImage = false;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.imagePath;
    _isSimulatorImage =
        kDebugMode && widget.imagePath == 'simulator_test_image.jpg';
  }

  Future<void> _cropImage() async {
    if (_isSimulatorImage) return;

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _currentImagePath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          IOSUiSettings(
            title: 'Crop Photo',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            aspectRatioPickerButtonHidden: false,
            aspectRatioLockDimensionSwapEnabled: false,
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: true,
            hidesNavigationBar: false,
            rectX: 0,
            rectY: 0,
            rectWidth: 0,
            rectHeight: 0,
            showActivitySheetOnDone: false,
            showCancelConfirmationDialog: false,
          ),
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
            backgroundColor: Colors.black,
            activeControlsWidgetColor: const Color(0xFFFFD60A),
            dimmedLayerColor: Colors.black.withValues(alpha: 0.8),
            cropFrameColor: Colors.white,
            cropGridColor: Colors.white.withValues(alpha: 0.5),
            cropFrameStrokeWidth: 2,
            cropGridStrokeWidth: 1,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _currentImagePath = croppedFile.path;
        });
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      // Handle cropping error
      debugPrint('Error cropping image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Image Display with Portrait Mode Effects
          Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(_currentImagePath),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  // Show mock preview for simulator testing
                  if (kDebugMode &&
                      widget.imagePath == 'simulator_test_image.jpg') {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.withValues(alpha: 0.4),
                            Colors.purple.withValues(alpha: 0.4),
                            Colors.pink.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.isPortraitMode
                                  ? Icons.portrait
                                  : Icons.camera_alt,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'SIMULATOR CAPTURE',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.isPortraitMode
                                  ? 'Portrait Mode Preview'
                                  : 'Photo Preview',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Container(
                    color: const Color(0xFF1A1A1A),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Error loading image',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Portrait Mode Overlay Effect
              if (widget.isPortraitMode)
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(
                          alpha: widget.portraitBlurIntensity * 0.2,
                        ),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
            ],
          ),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.isPortraitMode ? 'Portrait' : 'Photo',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.isPortraitMode)
                            Text(
                              'f/${(1.4 + (widget.portraitBlurIntensity * 4.6)).toStringAsFixed(1)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      // Crop Button (only show for real images)
                      if (!_isSimulatorImage)
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _cropImage,
                              borderRadius: BorderRadius.circular(12),
                              child: const Center(
                                child: Icon(
                                  Icons.crop,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Action Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 32,
                left: 20,
                right: 20,
              ),
              child: Center(
                child: DarkButton(
                  width: 150,
                  text: 'Continue',
                  onPressed: () async {
                    final String finalImagePath;

                    if (widget.imagePath == 'simulator_test_image.jpg') {
                      // For debug mode, copy the asset to a temporary file
                      finalImagePath = await Util.copyAssetToTempFile(
                        'assets/test/canada_goose.jpg',
                      );
                    } else {
                      finalImagePath = _currentImagePath;
                    }

                    if (!context.mounted) return;
                    if (!widget.isAreaCapture) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CreateSightingScreen(
                                imagePath: finalImagePath,
                              ),
                        ),
                      );
                    } else {
                      // For area capture, navigate to CreateSightingScreen
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CreateSightingScreen(
                                imagePath: finalImagePath,
                                isAreaCapture: true,
                              ),
                        ),
                      );

                      // Pop back to CaptureScreen, then to AreaCaptureHome with the result
                      if (result != null && context.mounted) {
                        Navigator.of(context).pop(); // Pop PhotoPreviewScreen
                        Navigator.of(
                          context,
                        ).pop(result); // Pop CaptureScreen with sighting data
                      } else if (context.mounted) {
                        Navigator.of(context).pop(); // Pop PhotoPreviewScreen
                        Navigator.of(
                          context,
                        ).pop(); // Pop CaptureScreen without result
                      }
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
