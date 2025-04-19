import 'package:sighttrack/barrel.dart';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
  late FToast fToast;

  @override
  void initState() {
    super.initState();
    _initializeWrapper();
    _initializeCamera();
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
    if (_userSettings?.isAreaCaptureActive == true) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _updateTimeRemaining(),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      await _initializeCameraFuture;
      final photo = await _cameraController!.takePicture();
      final position = await Util.getCurrentPosition();
      final now = DateTime.now();
      final key = 'sightings/$now.jpg';
      final sighting = Sighting(
        species: await Util.doAWSRekognitionCall(
          photo.path,
        ).then((value) => value[0]),
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
      fToast.showToast(
        child: Util.redToast('You\'re camera isn\'t working'),
        gravity: ToastGravity.BOTTOM,
        toastDuration: Duration(seconds: 3),
      );
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
                    ? Padding(
                      padding: const EdgeInsets.all(80.0),
                      child: const Center(child: CircularProgressIndicator()),
                    )
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
