import 'package:sighttrack/barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

enum CameraMode { photo, portrait }

enum CameraAspectRatio { ratio16_9, ratio4_3, ratio1_1 }

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

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
  bool _hasFlash = true;
  bool _isCameraInitialized = false;
  String? _errorMessage;
  bool _isCapturePressed = false;
  late String _currentTime;
  Timer? _timer;
  FToast? _fToast;

  // Professional controls
  CameraMode _currentMode = CameraMode.photo;
  CameraAspectRatio _aspectRatio = CameraAspectRatio.ratio4_3;
  bool _showGrid = false;
  bool _showLevel = false;
  bool _showHistogram = false;
  bool _showProControls = false;
  bool _isHDREnabled = false;
  bool _isRawEnabled = false;
  int _timerSeconds = 0; // 0 = off, 3, 5, 10

  // Portrait mode controls
  double _portraitBlurIntensity = 0.5;
  bool _portraitModeEnabled = false;

  // Manual controls
  double _currentZoomLevel = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentExposureOffset = 0.0;
  double _minAvailableExposure = 0.0;
  double _maxAvailableExposure = 0.0;
  double _currentISO = 100;
  double _minISO = 50;
  double _maxISO = 3200;
  bool _isManualMode = false;

  // Focus controls
  Offset? _focusPoint;
  bool _showFocusBox = false;
  bool _isExposureLocked = false;
  late AnimationController _focusAnimationController;
  late Animation<double> _focusAnimation;
  Timer? _focusTimer;

  // UI Animation
  late AnimationController _uiAnimationController;
  late AnimationController _modeAnimationController;
  bool _showUI = true;
  Timer? _hideUITimer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now().toString().split('.')[0];
    _startTimer();
    _initializeCamera();
    _fToast = FToast();
    _fToast!.init(context);

    // Initialize animations
    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _focusAnimation = Tween<double>(begin: 1.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _focusAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _uiAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _uiAnimationController.forward();

    _modeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now().toString().split('.')[0];
      });
    });
  }

  void _startHideUITimer() {
    _hideUITimer?.cancel();
    _hideUITimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showUI) {
        setState(() {
          _showUI = false;
        });
        _uiAnimationController.reverse();
      }
    });
  }

  void _showUIControls() {
    _hideUITimer?.cancel();
    if (!_showUI) {
      setState(() {
        _showUI = true;
      });
      _uiAnimationController.forward();
    }
    _startHideUITimer();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        // For iOS Simulator testing - show mock camera
        if (kDebugMode) {
          setState(() {
            _isCameraInitialized = true;
            _cameras = []; // Keep empty for simulator
            // Set mock values for controls
            _maxAvailableZoom = 5.0;
            _minAvailableZoom = 1.0;
            _currentZoomLevel = 1.0;
            _maxAvailableExposure = 2.0;
            _minAvailableExposure = -2.0;
            _currentExposureOffset = 0.0;
            _hasFlash = false;
            _flashMode = FlashMode.off;
          });
          return;
        }
        setState(() {
          _errorMessage = 'No cameras available on this device.';
        });
        return;
      }
      Log.i('Found ${_cameras.length} cameras');
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

    // Skip camera controller setup for simulator testing
    if (_cameras.isEmpty && kDebugMode) {
      setState(() {
        _isCameraInitialized = true;
        _portraitModeEnabled = _currentMode == CameraMode.portrait;
      });
      return;
    }

    final isBackCamera =
        _cameras[_selectedCameraIndex].lensDirection ==
        CameraLensDirection.back;
    final resolutionPreset =
        isBackCamera ? ResolutionPreset.high : ResolutionPreset.medium;

    _controller = CameraController(
      _cameras[_selectedCameraIndex],
      resolutionPreset,
      enableAudio: false,
      imageFormatGroup:
          _isRawEnabled ? ImageFormatGroup.jpeg : ImageFormatGroup.jpeg,
    );

    _initializeControllerFuture = _controller!
        .initialize()
        .then((_) async {
          Log.i('Camera initialized successfully');
          await _setupCameraProperties();
          setState(() {
            _isCameraInitialized = true;
            _portraitModeEnabled =
                _currentMode == CameraMode.portrait && isBackCamera;
          });
        })
        .catchError((e) {
          Log.e('Error initializing camera: $e');
          setState(() {
            _isCameraInitialized = false;
            _errorMessage = 'Failed to initialize camera: $e';
          });
        });
  }

  Future<void> _setupCameraProperties() async {
    // Skip for simulator testing
    if (_cameras.isEmpty && kDebugMode) return;

    _maxAvailableZoom = await _controller!.getMaxZoomLevel();
    _minAvailableZoom = await _controller!.getMinZoomLevel();
    _currentZoomLevel = _minAvailableZoom;

    _maxAvailableExposure = await _controller!.getMaxExposureOffset();
    _minAvailableExposure = await _controller!.getMinExposureOffset();
    _currentExposureOffset = 0.0;

    await _checkFlashSupport();
    await _controller!.setFlashMode(_flashMode);

    try {
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setExposureMode(ExposureMode.auto);
    } catch (e) {
      Log.w('Could not set focus/exposure mode: $e');
    }
  }

  Future<void> _checkFlashSupport() async {
    // Skip for simulator testing
    if (_cameras.isEmpty && kDebugMode) {
      setState(() {
        _hasFlash = false;
        _flashMode = FlashMode.off;
      });
      return;
    }

    try {
      await _controller!.setFlashMode(FlashMode.always);
      setState(() {
        _hasFlash = true;
      });
    } catch (e) {
      setState(() {
        _hasFlash = false;
        _flashMode = FlashMode.off;
      });
    }
  }

  // Mode switching with swipe gesture
  void _switchMode(CameraMode mode) {
    if (_currentMode != mode) {
      _modeAnimationController.forward().then((_) {
        setState(() {
          _currentMode = mode;
          // Safe camera access check
          if (_cameras.isNotEmpty) {
            final isBackCamera =
                _cameras[_selectedCameraIndex].lensDirection ==
                CameraLensDirection.back;
            _portraitModeEnabled = mode == CameraMode.portrait && isBackCamera;
          } else {
            _portraitModeEnabled = mode == CameraMode.portrait;
          }
        });
        _modeAnimationController.reverse();
        HapticFeedback.selectionClick();
        _setupCameraController();
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    const sensitivity = 8.0;
    if (details.primaryVelocity! > sensitivity) {
      // Swipe right - switch to previous mode
      if (_currentMode == CameraMode.portrait) {
        _switchMode(CameraMode.photo);
      }
    } else if (details.primaryVelocity! < -sensitivity) {
      // Swipe left - switch to next mode
      if (_currentMode == CameraMode.photo) {
        _switchMode(CameraMode.portrait);
      }
    }
  }

  // Professional controls
  void _toggleGrid() {
    setState(() {
      _showGrid = !_showGrid;
    });
    HapticFeedback.lightImpact();
  }

  void _toggleLevel() {
    setState(() {
      _showLevel = !_showLevel;
    });
    HapticFeedback.lightImpact();
  }

  void _toggleHistogram() {
    setState(() {
      _showHistogram = !_showHistogram;
    });
    HapticFeedback.lightImpact();
  }

  void _cycleTimer() {
    setState(() {
      switch (_timerSeconds) {
        case 0:
          _timerSeconds = 3;
          break;
        case 3:
          _timerSeconds = 5;
          break;
        case 5:
          _timerSeconds = 10;
          break;
        case 10:
          _timerSeconds = 0;
          break;
      }
    });
    HapticFeedback.lightImpact();
  }

  void _cycleAspectRatio() {
    setState(() {
      switch (_aspectRatio) {
        case CameraAspectRatio.ratio4_3:
          _aspectRatio = CameraAspectRatio.ratio16_9;
          break;
        case CameraAspectRatio.ratio16_9:
          _aspectRatio = CameraAspectRatio.ratio1_1;
          break;
        case CameraAspectRatio.ratio1_1:
          _aspectRatio = CameraAspectRatio.ratio4_3;
          break;
      }
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _switchCamera() async {
    // Skip for simulator testing
    if (_cameras.isEmpty && kDebugMode) {
      HapticFeedback.lightImpact();
      return;
    }

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    HapticFeedback.lightImpact();
    await _setupCameraController();
  }

  Future<void> _toggleFlash() async {
    if (!_hasFlash) return;

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

    // Skip for simulator testing
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

  Future<void> _setZoomLevel(double zoomLevel) async {
    // Skip for simulator testing
    if (_cameras.isEmpty && kDebugMode) {
      setState(() {
        _currentZoomLevel = zoomLevel.clamp(1.0, 5.0); // Mock zoom range
      });
      return;
    }

    try {
      await _controller!.setZoomLevel(zoomLevel);
      setState(() {
        _currentZoomLevel = zoomLevel;
      });
    } catch (e) {
      Log.e('Error setting zoom level: $e');
    }
  }

  Future<void> _setExposureOffset(double exposureOffset) async {
    // Skip for simulator testing
    if (_cameras.isEmpty && kDebugMode) {
      setState(() {
        _currentExposureOffset = exposureOffset.clamp(
          -2.0,
          2.0,
        ); // Mock exposure range
      });
      return;
    }

    try {
      await _controller!.setExposureOffset(exposureOffset);
      setState(() {
        _currentExposureOffset = exposureOffset;
      });
    } catch (e) {
      Log.e('Error setting exposure offset: $e');
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _showUIControls();
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final newZoomLevel = (_currentZoomLevel * details.scale).clamp(
      _minAvailableZoom,
      _maxAvailableZoom,
    );
    _setZoomLevel(newZoomLevel);
  }

  Future<void> _onTapToFocus(TapDownDetails details) async {
    if (!_isCameraInitialized) return;

    _showUIControls();
    HapticFeedback.lightImpact();

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localOffset = renderBox.globalToLocal(details.globalPosition);

    final double x = localOffset.dx / renderBox.size.width;
    final double y = localOffset.dy / renderBox.size.height;

    setState(() {
      _focusPoint = localOffset;
      _showFocusBox = true;
    });

    _focusAnimationController.reset();
    _focusAnimationController.forward();

    // Skip for simulator testing
    if (_cameras.isEmpty && kDebugMode) {
      _focusTimer?.cancel();
      _focusTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showFocusBox = false;
          });
        }
      });
      return;
    }

    try {
      await _controller!.setFocusPoint(Offset(x, y));
      await _controller!.setExposurePoint(Offset(x, y));
    } catch (e) {
      Log.e('Error setting focus point: $e');
    }

    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(seconds: 2), () {
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

    // Timer countdown
    if (_timerSeconds > 0) {
      for (int i = _timerSeconds; i > 0; i--) {
        // Show countdown overlay
        await Future.delayed(const Duration(seconds: 1));
        HapticFeedback.lightImpact();
      }
    }

    try {
      // Mock capture for simulator testing
      if (_cameras.isEmpty && kDebugMode) {
        // Create a mock image path for testing
        const mockImagePath = 'simulator_test_image.jpg';

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PhotoPreviewScreen(
                  imagePath: mockImagePath,
                  isPortraitMode: _currentMode == CameraMode.portrait,
                  portraitBlurIntensity: _portraitBlurIntensity,
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
                isPortraitMode: _currentMode == CameraMode.portrait,
                portraitBlurIntensity: _portraitBlurIntensity,
              ),
        ),
      );
    } catch (e) {
      Log.e('Error capturing photo: $e');
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
                ),
          ),
        );
      }
    } catch (e) {
      Log.e('Error picking image from gallery: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusTimer?.cancel();
    _hideUITimer?.cancel();
    _focusAnimationController.dispose();
    _uiAnimationController.dispose();
    _modeAnimationController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _showUIControls,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: Stack(
          children: [
            // Camera Preview
            _buildCameraPreview(),

            // Portrait Mode Effects
            if (_currentMode == CameraMode.portrait && _portraitModeEnabled)
              _buildPortraitModeOverlay(),

            // Grid Overlay
            if (_showGrid && _isCameraInitialized) _buildGridOverlay(),

            // Focus Box (moved after portrait overlay to ensure visibility)
            _buildFocusBox(),

            // Level Indicator
            if (_showLevel && _isCameraInitialized) _buildLevelIndicator(),

            // Histogram
            if (_showHistogram && _isCameraInitialized) _buildHistogram(),

            // Top Controls
            _buildTopControls(),

            // Professional Controls Panel
            if (_showProControls) _buildProControlsPanel(),

            // Mode Selector
            _buildModeSelector(),

            // Bottom Controls
            _buildBottomControls(),

            // Camera Info Overlay
            _buildCameraInfoOverlay(),

            // Zoom Level Indicator
            _buildZoomIndicator(),

            // Portrait Mode Controls
            if (_currentMode == CameraMode.portrait && _portraitModeEnabled)
              _buildPortraitControls(),
          ],
        ),
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

    return AnimatedBuilder(
      animation: _modeAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 - (_modeAnimationController.value * 0.05),
          child: GestureDetector(
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onTapDown: _onTapToFocus,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: _buildAspectRatioPreview(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAspectRatioPreview() {
    double aspectRatio;
    switch (_aspectRatio) {
      case CameraAspectRatio.ratio16_9:
        aspectRatio = 16 / 9;
        break;
      case CameraAspectRatio.ratio4_3:
        aspectRatio = 4 / 3;
        break;
      case CameraAspectRatio.ratio1_1:
        aspectRatio = 1 / 1;
        break;
    }

    // Mock camera preview for simulator testing
    if (_cameras.isEmpty && kDebugMode) {
      return Center(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
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
                    _currentMode == CameraMode.portrait
                        ? Icons.portrait
                        : Icons.camera_alt,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'SIMULATOR PREVIEW',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentMode == CameraMode.portrait
                        ? 'Portrait Mode'
                        : 'Photo Mode',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.previewSize?.height ?? 100,
              height: _controller!.value.previewSize?.width ?? 100,
              child: CameraPreview(_controller!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.red,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Camera Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 160,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _errorMessage = null;
                    _isCameraInitialized = false;
                  });
                  await _initializeCamera();
                  if (_errorMessage != null) {
                    _fToast!.showToast(child: Util.redToast('No camera found'));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
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
      color: const Color(0xFF1A1A1A),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF007AFF), strokeWidth: 3),
            SizedBox(height: 24),
            Text(
              'Initializing Camera...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridOverlay() {
    return CustomPaint(size: Size.infinite, painter: GridPainter());
  }

  Widget _buildFocusBox() {
    if (!_showFocusBox || _focusPoint == null) return const SizedBox.shrink();

    return Positioned(
      left: _focusPoint!.dx - 40,
      top: _focusPoint!.dy - 40,
      child: AnimatedBuilder(
        animation: _focusAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _focusAnimation.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFFD700), width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  // Corner brackets
                  ...List.generate(4, (index) {
                    final positions = [
                      {'top': 0.0, 'left': 0.0},
                      {'top': 0.0, 'right': 0.0},
                      {'bottom': 0.0, 'left': 0.0},
                      {'bottom': 0.0, 'right': 0.0},
                    ];
                    final borders = [
                      const Border(
                        top: BorderSide(color: Color(0xFFFFD700), width: 2),
                        left: BorderSide(color: Color(0xFFFFD700), width: 2),
                      ),
                      const Border(
                        top: BorderSide(color: Color(0xFFFFD700), width: 2),
                        right: BorderSide(color: Color(0xFFFFD700), width: 2),
                      ),
                      const Border(
                        bottom: BorderSide(color: Color(0xFFFFD700), width: 2),
                        left: BorderSide(color: Color(0xFFFFD700), width: 2),
                      ),
                      const Border(
                        bottom: BorderSide(color: Color(0xFFFFD700), width: 2),
                        right: BorderSide(color: Color(0xFFFFD700), width: 2),
                      ),
                    ];

                    return Positioned(
                      top: positions[index]['top'],
                      left: positions[index]['left'],
                      right: positions[index]['right'],
                      bottom: positions[index]['bottom'],
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(border: borders[index]),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLevelIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 100,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Container(width: 2, height: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildHistogram() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      right: 20,
      child: Container(
        width: 100,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: CustomPaint(
          size: const Size(100, 60),
          painter: HistogramPainter(),
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return AnimatedBuilder(
      animation: _uiAnimationController,
      builder: (context, child) {
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Transform.translate(
            offset: Offset(0, -120 * (1 - _uiAnimationController.value)),
            child: Container(
              height: MediaQuery.of(context).padding.top + 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Back Button
                      _buildTopButton(
                        icon: Icons.arrow_back_ios_new,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      // Settings Toggle
                      _buildTopButton(
                        icon: Icons.tune,
                        onPressed:
                            () => setState(
                              () => _showProControls = !_showProControls,
                            ),
                        isActive: _showProControls,
                      ),
                      const SizedBox(width: 12),
                      // Flash Toggle
                      _buildTopButton(
                        icon:
                            _flashMode == FlashMode.off
                                ? Icons.flash_off
                                : _flashMode == FlashMode.auto
                                ? Icons.flash_auto
                                : Icons.flash_on,
                        onPressed: _toggleFlash,
                        isActive: _flashMode != FlashMode.off,
                        isDisabled: !_hasFlash,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
    bool isDisabled = false,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color:
            isActive
                ? const Color(0xFF007AFF)
                : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Icon(
              icon,
              color:
                  isDisabled
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProControlsPanel() {
    return Positioned(
      left: MediaQuery.of(context).size.width / 2 - 140,
      top: MediaQuery.of(context).padding.top + 80,
      bottom: 200,
      child: Container(
        width: 280,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Advanced Controls',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _showProControls = false),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            // Controls
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProControlRow(
                      'Grid',
                      Icons.grid_3x3,
                      _showGrid,
                      _toggleGrid,
                    ),
                    _buildProControlRow(
                      'Level',
                      Icons.straighten,
                      _showLevel,
                      _toggleLevel,
                    ),
                    _buildProControlRow(
                      'Histogram',
                      Icons.bar_chart,
                      _showHistogram,
                      _toggleHistogram,
                    ),
                    _buildProControlRow(
                      'HDR',
                      Icons.hdr_on,
                      _isHDREnabled,
                      () => setState(() => _isHDREnabled = !_isHDREnabled),
                    ),
                    _buildProControlRow(
                      'RAW',
                      Icons.photo_camera,
                      _isRawEnabled,
                      () => setState(() => _isRawEnabled = !_isRawEnabled),
                    ),
                    const SizedBox(height: 20),
                    _buildTimerControl(),
                    const SizedBox(height: 20),
                    _buildAspectRatioControl(),
                    const SizedBox(height: 20),
                    _buildManualControls(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProControlRow(
    String title,
    IconData icon,
    bool isEnabled,
    VoidCallback onToggle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const Spacer(),
          Switch(
            value: isEnabled,
            onChanged: (_) => onToggle(),
            activeColor: const Color(0xFF007AFF),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Timer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children:
              [0, 3, 5, 10].map((seconds) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () => setState(() => _timerSeconds = seconds),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              _timerSeconds == seconds
                                  ? const Color(0xFF007AFF)
                                  : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            seconds == 0 ? 'Off' : '${seconds}s',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildAspectRatioControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aspect Ratio',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children:
              CameraAspectRatio.values.map((ratio) {
                String label;
                switch (ratio) {
                  case CameraAspectRatio.ratio16_9:
                    label = '16:9';
                    break;
                  case CameraAspectRatio.ratio4_3:
                    label = '4:3';
                    break;
                  case CameraAspectRatio.ratio1_1:
                    label = '1:1';
                    break;
                }

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () => setState(() => _aspectRatio = ratio),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              _aspectRatio == ratio
                                  ? const Color(0xFF007AFF)
                                  : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildManualControls() {
    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Manual Mode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Switch(
              value: _isManualMode,
              onChanged: (value) => setState(() => _isManualMode = value),
              activeColor: const Color(0xFF007AFF),
            ),
          ],
        ),
        if (_isManualMode) ...[
          const SizedBox(height: 16),
          _buildManualSlider(
            'ISO',
            _currentISO,
            _minISO,
            _maxISO,
            (value) => setState(() => _currentISO = value),
          ),
          const SizedBox(height: 12),
          _buildManualSlider(
            'Exposure',
            _currentExposureOffset,
            _minAvailableExposure,
            _maxAvailableExposure,
            _setExposureOffset,
          ),
          const SizedBox(height: 12),
          _buildManualSlider(
            'Zoom',
            _currentZoomLevel,
            _minAvailableZoom,
            _maxAvailableZoom,
            _setZoomLevel,
          ),
        ],
      ],
    );
  }

  Widget _buildManualSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const Spacer(),
            Text(
              label == 'ISO'
                  ? value.toInt().toString()
                  : value.toStringAsFixed(1),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF007AFF),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
            thumbColor: const Color(0xFF007AFF),
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return AnimatedBuilder(
      animation: _uiAnimationController,
      builder: (context, child) {
        return Positioned(
          bottom: 160 + MediaQuery.of(context).padding.bottom,
          left: 0,
          right: 0,
          child: Transform.translate(
            offset: Offset(0, 80 * (1 - _uiAnimationController.value)),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      CameraMode.values.map((mode) {
                        String label;
                        switch (mode) {
                          case CameraMode.photo:
                            label = 'PHOTO';
                            break;
                          case CameraMode.portrait:
                            label = 'PORTRAIT';
                            break;
                        }

                        return GestureDetector(
                          onTap: () => _switchMode(mode),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _currentMode == mode
                                      ? const Color(0xFF007AFF)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight:
                                    _currentMode == mode
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomControls() {
    return AnimatedBuilder(
      animation: _uiAnimationController,
      builder: (context, child) {
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Transform.translate(
            offset: Offset(0, 140 * (1 - _uiAnimationController.value)),
            child: Container(
              height: 140 + MediaQuery.of(context).padding.bottom,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery Button
                    _buildBottomButton(
                      icon: Icons.photo_library,
                      onPressed: _pickFromGallery,
                    ),

                    // Capture Button
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(40),
                          onTapDown:
                              (_) => setState(() => _isCapturePressed = true),
                          onTapUp:
                              (_) => setState(() => _isCapturePressed = false),
                          onTapCancel:
                              () => setState(() => _isCapturePressed = false),
                          onTap: () {
                            print('Capture button tapped!');
                            HapticFeedback.mediumImpact();
                            _capturePhoto();
                          },
                          child: AnimatedScale(
                            scale: _isCapturePressed ? 0.95 : 1.0,
                            duration: const Duration(milliseconds: 100),
                            child: SizedBox(
                              width: 80,
                              height: 80,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(77),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 70,
                                    height: 70,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          _currentMode == CameraMode.portrait
                                              ? Colors.red
                                              : const Color(0xFF007AFF),
                                    ),
                                    child: SizedBox(
                                      width: 70,
                                      height: 70,
                                      child: Center(
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              color: Colors.transparent,
                                            ),
                                            Icon(
                                              _currentMode ==
                                                      CameraMode.portrait
                                                  ? Icons.portrait
                                                  : Icons.camera_alt,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Timer indicator overlay
                                  if (_timerSeconds > 0)
                                    IgnorePointer(
                                      ignoring: true,
                                      child: Positioned(
                                        top: 5,
                                        right: 5,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFFFFD700),
                                          ),
                                          child: Center(
                                            child: Text(
                                              _timerSeconds.toString(),
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Camera Switch Button
                    _buildBottomButton(
                      icon: Icons.flip_camera_ios,
                      onPressed: _switchCamera,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
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
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(child: Icon(icon, color: Colors.white, size: 24)),
        ),
      ),
    );
  }

  Widget _buildCameraInfoOverlay() {
    if (!_isCameraInitialized || !_showUI) return const SizedBox.shrink();

    // Safe camera access for simulator
    String cameraType = 'Camera';
    if (_cameras.isNotEmpty) {
      final camera = _cameras[_selectedCameraIndex];
      final isBack = camera.lensDirection == CameraLensDirection.back;
      cameraType = '${isBack ? 'Back' : 'Front'} Camera';
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 1,
      left: MediaQuery.of(context).size.width / 2 - 100,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              cameraType,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_isManualMode) ...[
              Text(
                'ISO ${_currentISO.toInt()}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 9,
                ),
              ),
              Text(
                'EV ${_currentExposureOffset >= 0 ? '+' : ''}${_currentExposureOffset.toStringAsFixed(1)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 9,
                ),
              ),
            ],
            Text(
              _currentTime,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 8,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomIndicator() {
    if (!_isCameraInitialized || _currentZoomLevel <= _minAvailableZoom) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 220 + MediaQuery.of(context).padding.bottom,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: _showUI ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Text(
              '${_currentZoomLevel.toStringAsFixed(1)}x',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitModeOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center:
                _focusPoint != null
                    ? Alignment(
                      (_focusPoint!.dx / MediaQuery.of(context).size.width) *
                              2 -
                          1,
                      (_focusPoint!.dy / MediaQuery.of(context).size.height) *
                              2 -
                          1,
                    )
                    : Alignment.center,
            radius: 0.8,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: _portraitBlurIntensity * 0.3),
            ],
            stops: const [0.3, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitControls() {
    return Positioned(
      left: 20,
      top: MediaQuery.of(context).size.height * 0.4,
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.blur_on, color: Colors.white, size: 16),
            const SizedBox(height: 8),
            RotatedBox(
              quarterTurns: -1,
              child: SizedBox(
                width: 80,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF007AFF),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                    thumbColor: const Color(0xFF007AFF),
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 4,
                    ),
                  ),
                  child: Slider(
                    value: _portraitBlurIntensity,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) {
                      setState(() {
                        _portraitBlurIntensity = value;
                      });
                      HapticFeedback.lightImpact();
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'f/${(1.4 + (_portraitBlurIntensity * 4.6)).toStringAsFixed(1)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painters
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..strokeWidth = 0.5;

    // Vertical lines
    final verticalSpacing = size.width / 3;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(verticalSpacing * i, 0),
        Offset(verticalSpacing * i, size.height),
        paint,
      );
    }

    // Horizontal lines
    final horizontalSpacing = size.height / 3;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(0, horizontalSpacing * i),
        Offset(size.width, horizontalSpacing * i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HistogramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..strokeWidth = 1;

    // Simulate histogram data
    final random = [0.2, 0.4, 0.8, 0.6, 0.3, 0.7, 0.5, 0.9, 0.4, 0.2];
    final barWidth = size.width / random.length;

    for (int i = 0; i < random.length; i++) {
      final barHeight = size.height * random[i];
      canvas.drawRect(
        Rect.fromLTWH(
          i * barWidth,
          size.height - barHeight,
          barWidth - 1,
          barHeight,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PhotoPreviewScreen extends StatelessWidget {
  final String imagePath;
  final bool isPortraitMode;
  final double portraitBlurIntensity;

  const PhotoPreviewScreen({
    super.key,
    required this.imagePath,
    required this.isPortraitMode,
    required this.portraitBlurIntensity,
  });

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
                File(imagePath),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  // Show mock preview for simulator testing
                  if (kDebugMode && imagePath == 'simulator_test_image.jpg') {
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
                              isPortraitMode
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
                              isPortraitMode
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
              if (isPortraitMode)
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(
                          alpha: portraitBlurIntensity * 0.2,
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
                            isPortraitMode ? 'Portrait' : 'Photo',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isPortraitMode)
                            Text(
                              'f/${(1.4 + (portraitBlurIntensity * 4.6)).toStringAsFixed(1)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
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
              height: 100 + MediaQuery.of(context).padding.bottom,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                CreateSightingScreen(imagePath: imagePath),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  label: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
