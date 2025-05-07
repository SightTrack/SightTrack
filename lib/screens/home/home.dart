import 'package:sighttrack/barrel.dart';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart' as geo;

class AnnotationClickListener extends mapbox.OnCircleAnnotationClickListener {
  // Callback function to handle annotation click events

  final void Function(mapbox.CircleAnnotation) onAnnotationClick;

  AnnotationClickListener({required this.onAnnotationClick});

  @override
  void onCircleAnnotationClick(mapbox.CircleAnnotation annotation) {
    onAnnotationClick(annotation);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isUserInteracting = false;
  Timer? _interactionTimer;
  mapbox.MapboxMap? _mapboxMap;
  List<Sighting> _sightings = [];
  mapbox.CircleAnnotationManager? _circleAnnotationManager;
  bool _mapLoaded = false;
  final Map<String, Sighting> _annotationSightingMap = {};
  late AnnotationClickListener _annotationClickListener;
  bool _isNavigating = false;
  UserSettings? _userSettings;
  bool _isAreaCaptureActive = false;

  @override
  void initState() {
    super.initState();
    _initializeWrapper();

    _annotationClickListener = AnnotationClickListener(
      onAnnotationClick: (annotation) {
        if (_isNavigating) return; // Skip if already navigating
        _isNavigating = true;
        final sighting = _annotationSightingMap[annotation.id];
        if (sighting != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewSightingScreen(sighting: sighting),
            ),
          ).then((_) {
            _isNavigating = false;
          });
        } else {
          _isNavigating = false;
        }
      },
    );
    _initializeAmplify();
  }

  Future<void> _initializeWrapper() async {
    final fetchSettings = await Util.getUserSettings();
    setState(() {
      _userSettings = fetchSettings;
      _isAreaCaptureActive = fetchSettings?.isAreaCaptureActive ?? false;
    });
    Amplify.DataStore.observe(UserSettings.classType).listen((event) {
      if (mounted) {
        setState(() {
          _userSettings = event.item;
          _isAreaCaptureActive = _userSettings?.isAreaCaptureActive ?? false;
        });
      }
    });
  }

  Future<void> _fetchSightings() async {
    try {
      final subscription = Amplify.DataStore.observeQuery(
        Sighting.classType,
      ).listen((event) {
        final sightings = event.items;
        if (mounted) {
          setState(() => _sightings = sightings);
          if (_mapLoaded) _addSightingsToMap();
        }
      });

      subscription.onDone(() => Log.i('Sightings subscription closed'));
    } catch (e) {
      Log.e('Fetch error: $e');
    }
  }

  Future<void> _addSightingsToMap() async {
    if (_mapboxMap == null || _circleAnnotationManager == null) return;

    await _circleAnnotationManager!.deleteAll();
    _annotationSightingMap.clear();

    final options = <mapbox.CircleAnnotationOptions>[];
    for (final sighting in _sightings) {
      options.add(
        mapbox.CircleAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(
              sighting.displayLongitude ?? sighting.longitude,
              sighting.displayLatitude ?? sighting.latitude,
            ),
          ),
          circleRadius: 10,
          circleColor: Color.fromARGB(255, 255, 234, 0).toARGB32(),
          circleBlur: 1,
        ),
      );
    }

    final createdAnnotations = await _circleAnnotationManager!.createMulti(
      options,
    );

    for (int i = 0; i < createdAnnotations.length; i++) {
      _annotationSightingMap[createdAnnotations[i]!.id] = _sightings[i];
    }
  }

  void onMapCreated(mapbox.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    await _mapboxMap!.logo.updateSettings(mapbox.LogoSettings(enabled: false));
    await _mapboxMap!.attribution.updateSettings(
      mapbox.AttributionSettings(enabled: false),
    );
    await _mapboxMap!.scaleBar.updateSettings(
      mapbox.ScaleBarSettings(enabled: false),
    );

    await _mapboxMap!.location.updateSettings(
      mapbox.LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        puckBearingEnabled: true,
      ),
    );

    try {
      final geo.Position pos = await Util.getCurrentPosition();
      await _mapboxMap!.setCamera(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(pos.longitude, pos.latitude),
          ),
          zoom: 1.0,
          bearing: pos.heading,
        ),
      );
    } catch (e) {
      debugPrint('Error getting user location: $e');
    }

    geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) async {
      if (!_isUserInteracting && _mapboxMap != null) {
        await _mapboxMap!.flyTo(
          mapbox.CameraOptions(
            center: mapbox.Point(
              coordinates: mapbox.Position(
                position.longitude,
                position.latitude,
              ),
            ),
            bearing: position.heading,
          ),
          mapbox.MapAnimationOptions(duration: 500),
        );
      }
    });

    _circleAnnotationManager =
        await _mapboxMap!.annotations.createCircleAnnotationManager();
    _circleAnnotationManager!.addOnCircleAnnotationClickListener(
      _annotationClickListener,
    );
    _mapLoaded = true;
    _addSightingsToMap();
  }

  void _onUserInteraction() {
    _isUserInteracting = true;
    _interactionTimer?.cancel();
    _interactionTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isUserInteracting = false);
      }
    });
  }

  Future<void> _resetCameraToUserLocation() async {
    try {
      final geo.Position pos = await Util.getCurrentPosition();
      if (_mapboxMap != null) {
        await _mapboxMap!.flyTo(
          mapbox.CameraOptions(
            center: mapbox.Point(
              coordinates: mapbox.Position(pos.longitude, pos.latitude),
            ),
            zoom: 10.0,
            bearing: pos.heading,
          ),
          mapbox.MapAnimationOptions(duration: 500),
        );
      }
    } catch (e) {
      debugPrint('Error resetting camera: $e');
    }
  }

  Future<void> _initializeAmplify() async {
    try {
      await Amplify.DataStore.stop();
      await Amplify.DataStore.start();
      Amplify.DataStore.observe(Sighting.classType).listen((event) {
        _fetchSightings();
      });
      _fetchSightings();
    } catch (e) {
      Log.e('Amplify initialization error: $e');
    }
  }

  @override
  void dispose() {
    _interactionTimer?.cancel();
    _circleAnnotationManager?.deleteAll();
    _circleAnnotationManager = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Listener(
            onPointerDown: (_) => _onUserInteraction(),
            child: mapbox.MapWidget(
              styleUri: Util.mapStyle,
              onMapCreated: onMapCreated,
            ),
          ),
          if (_isAreaCaptureActive)
            Positioned(
              top: 64,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.grey, Colors.teal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Area Capture Mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 50.0,
            left: 16.0,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/all_sightings');
              },
              backgroundColor: Colors.grey[850]!.withValues(alpha: 0.9),
              foregroundColor: Colors.white,
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(
                  color: Colors.grey[700]!.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              splashColor: Colors.blueAccent.withValues(alpha: 0.2),
              heroTag: 'topLeftFAB',
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.list, size: 24, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _resetCameraToUserLocation,
        backgroundColor: Colors.grey[850]!.withValues(alpha: 0.9),
        foregroundColor: Colors.white,
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(
            color: Colors.grey[700]!.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        splashColor: Colors.blueAccent.withValues(alpha: 0.2),
        heroTag: 'locationFAB',
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.my_location, size: 24, color: Colors.white),
        ),
      ),
    );
  }
}

extension ColorExtension on Color {
  int toARGB32() {
    return (alpha << 24) | (red << 16) | (green << 8) | blue;
  }
}
