import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sighttrack/logging.dart';
import 'dart:io';

import 'package:sighttrack/screens/capture/create_sighting.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  CaptureScreenState createState() => CaptureScreenState();
}

class CaptureScreenState extends State<CaptureScreen> {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  late List<CameraDescription> _cameras;
  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  bool _hasFlash = true;
  bool _isCameraInitialized = false;
  String? _errorMessage;
  bool _isCapturePressed = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Get available cameras
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
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

    // Default to back camera (index 0)
    _selectedCameraIndex = 0;
    await _setupCameraController();
  }

  Future<void> _setupCameraController() async {
    // Reset initialization state
    setState(() {
      _isCameraInitialized = false;
      _errorMessage = null;
    });

    // Dispose of the previous controller if it exists
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }

    // Create a new controller for the selected camera
    _controller = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    // Initialize the controller and wait for completion
    _initializeControllerFuture = _controller!
        .initialize()
        .then((_) {
          Log.i('Camera initialized successfully');
          // Check flash support for the new camera
          _checkFlashSupport();
          // Set flash mode
          _controller!.setFlashMode(_flashMode);
          // Mark as initialized
          setState(() {
            _isCameraInitialized = true;
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

  Future<void> _checkFlashSupport() async {
    try {
      await _controller!.setFlashMode(FlashMode.always);
      setState(() {
        _hasFlash = true;
      });
    } catch (e) {
      Log.e('Flash not supported on this camera: $e');
      setState(() {
        _hasFlash = false;
        _flashMode = FlashMode.off;
      });
    }
  }

  Future<void> _switchCamera() async {
    // Toggle between front and back cameras
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
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

    try {
      await _initializeControllerFuture;
      await _controller!.setFlashMode(_flashMode);
    } catch (e) {
      Log.e('Error setting flash mode: $e');
      setState(() {
        _flashMode = FlashMode.off;
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (!_isCameraInitialized || _controller == null) return;

    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();

      // Navigate to a preview screen with the captured image
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoPreviewScreen(imagePath: image.path),
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
            builder: (context) => PhotoPreviewScreen(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      Log.e('Error picking image from gallery: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen camera preview or error message
          _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Retry initialization
                        _initializeCamera();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : _isCameraInitialized
              ? SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: CameraPreview(_controller!),
              )
              : const Center(child: CircularProgressIndicator()),

          // Top gradient overlay
          if (_isCameraInitialized && _errorMessage == null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          // Bottom gradient overlay
          if (_isCameraInitialized && _errorMessage == null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          // Top-right icon (flash toggle only)
          if (_isCameraInitialized && _errorMessage == null)
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _flashMode == FlashMode.off
                        ? Icons.flash_off
                        : _flashMode == FlashMode.auto
                        ? Icons.flash_auto
                        : Icons.flash_on,
                    color: _hasFlash ? Colors.white : Colors.grey,
                    size: 30,
                  ),
                  onPressed: _hasFlash ? _toggleFlash : null,
                ),
              ),
            ),

          // Bottom controls
          if (_isCameraInitialized && _errorMessage == null)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Album button (unchanged)
                  GestureDetector(
                    onTap: () {
                      _pickFromGallery();
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.withValues(alpha: 0.8),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.photo,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  // Modified Capture button
                  GestureDetector(
                    onTapDown: (_) {
                      setState(() {
                        _isCapturePressed = true;
                      });
                    },
                    onTapUp: (_) {
                      setState(() {
                        _isCapturePressed = false;
                      });
                      _capturePhoto();
                    },
                    onTapCancel: () {
                      setState(() {
                        _isCapturePressed = false;
                      });
                    },
                    child: AnimatedScale(
                      scale: _isCapturePressed ? 0.9 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeInOut,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Flip camera button (unchanged)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.flip_camera_ios,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: _switchCamera,
                    ),
                  ),
                ],
              ),
            ),

          // Timestamp overlay (top-left, placeholder)
          if (_isCameraInitialized && _errorMessage == null)
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  DateTime.now().toString().split('.')[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PhotoPreviewScreen extends StatelessWidget {
  final String imagePath;

  const PhotoPreviewScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error, color: Colors.white, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Error loading image',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              );
            },
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.black,
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => CreateSightingScreen(imagePath: imagePath),
                  ),
                );
              },
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
