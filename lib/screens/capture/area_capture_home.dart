import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sighttrack/logging.dart';
import 'package:sighttrack/models/Sighting.dart';
import 'package:sighttrack/models/UserSettings.dart';
import 'package:sighttrack/util.dart';

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
  Future<void>? _initializeCameraFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWrapper();
    _initializeCamera();
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
      _initializeCamera();
    }
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

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.first;
      _cameraController = CameraController(camera, ResolutionPreset.high);
      _initializeCameraFuture = _cameraController!.initialize();
      setState(() {});
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _startTimer() {
    if (_timer?.isActive ?? false) return;
    if (_userSettings?.isAreaCaptureActive == true &&
        _userSettings?.areaCaptureEnd != null) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _updateTimeRemaining(),
      );
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  Future<void> _takePhoto() async {
    try {
      await _initializeCameraFuture;
      final photo = await _cameraController!.takePicture();
      final position = await _getCurrentPosition();
      final now = DateTime.now();
      final key = 'sightings/$now.jpg';
      final sighting = Sighting(
        species: await _getSpeciesName(photo.path).then((value) => value),
        photo: key,
        latitude: position?.latitude ?? 0.0,
        longitude: position?.longitude ?? 0.0,
        displayLatitude: position?.latitude ?? 0.0,
        displayLongitude: position?.longitude ?? 0.0,
        timestamp: TemporalDateTime(now),
        description: 'Captured during area capture session',
      );
      setState(() {
        _sessionSightings.add({'sighting': sighting, 'localPath': photo.path});
      });
      Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(photo.path),
        path: StoragePath.fromString(key),
      );
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

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
      return;
    }

    final minutes = difference.inMinutes;
    final seconds = difference.inSeconds % 60;
    setState(
      () => _timeRemaining = '$minutes:${seconds.toString().padLeft(2, '0')}',
    );
  }

  Future<void> _saveSessionSightings() async {
    for (var entry in _sessionSightings) {
      await Amplify.DataStore.save(entry['sighting'] as Sighting);
    }
  }

  Future<String> _getSpeciesName(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final requestBody = jsonEncode({'image': base64Image});

      final response =
          await Amplify.API
              .post(
                '/analyze',
                body: HttpPayload.json(requestBody),
                headers: {'Content-Type': 'application/json'},
              )
              .response;

      final responseBody = jsonDecode(response.decodeBody());
      final labels =
          (responseBody['labels'] as List)
              .map((label) => label['Name'] as String)
              .toList();

      Log.i('Lambda response: $labels');
      return labels[0];
    } on ApiException catch (e) {
      Log.e('API call to /analyze failed (method: POST): $e');
      return 'Unknown';
    } catch (e) {
      Log.e('Unexpected error in Lambda invocation: $e');
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Center(
                  child: Text(
                    'Area Capture',
                    style: TextStyle(color: Colors.white, fontSize: 25),
                  ),
                ),
                const SizedBox(height: 20),
                _userSettings == null
                    ? const CircularProgressIndicator()
                    : Text(
                      'Time Remaining: $_timeRemaining',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                const SizedBox(height: 20),
                _cameraController == null || _initializeCameraFuture == null
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                      height: 600,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FutureBuilder<void>(
                          future: _initializeCameraFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              return CameraPreview(_cameraController!);
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _takePhoto,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor: Colors.white,
                    splashFactory: InkRipple.splashFactory,
                    foregroundColor: Colors.teal,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _sessionSightings.length,
                  itemBuilder: (context, index) {
                    final localPath =
                        _sessionSightings[index]['localPath'] as String;
                    return Image.file(File(localPath), fit: BoxFit.cover);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
