import 'package:sighttrack/barrel.dart';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart' as geo;
import 'dart:math' as math;

class AreaCaptureSetup extends StatefulWidget {
  const AreaCaptureSetup({super.key});

  @override
  State<AreaCaptureSetup> createState() => _AreaCaptureSetupState();
}

class _AreaCaptureSetupState extends State<AreaCaptureSetup> {
  mapbox.MapboxMap? _mapboxMap;
  mapbox.CircleAnnotationManager? _circleManager;
  String? _circleAnnotationId;
  bool _isDisposed = false;
  mapbox.Point? _centerPoint;
  final ValueNotifier<double> _radiusMeters = ValueNotifier(300.0);
  double _lastZoom = 15.0;
  bool _isLoading = true;

  int _selectedDuration = 10;
  final List<int> _durations = [1, 5, 10, 30, 60, 120, 300]; // Minutes

  UserSettings? _userSettings;

  @override
  void initState() {
    super.initState();
    _initializeWrapper();

    _isLoading = false;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _circleManager?.deleteAll();
    _mapboxMap = null;
    _radiusMeters.dispose();
    super.dispose();
  }

  Future<void> _initializeWrapper() async {
    final fetchSettings = await Util.getUserSettings();
    setState(() {
      _userSettings = fetchSettings;
    });
  }

  void _onMapCreated(mapbox.MapboxMap mapboxMap) async {
    if (_isDisposed || !mounted) return;
    _mapboxMap = mapboxMap;

    // Hide extra UI stuff
    await mapboxMap.logo.updateSettings(mapbox.LogoSettings(enabled: false));
    await mapboxMap.attribution.updateSettings(
      mapbox.AttributionSettings(enabled: false),
    );
    await mapboxMap.scaleBar.updateSettings(
      mapbox.ScaleBarSettings(enabled: false),
    );

    // Enable location puck
    await mapboxMap.location.updateSettings(
      mapbox.LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        puckBearingEnabled: true,
      ),
    );

    try {
      final geo.Position pos = await _determinePosition();
      if (_isDisposed || !mounted) return;

      _centerPoint = mapbox.Point(
        coordinates: mapbox.Position(pos.longitude, pos.latitude),
      );
      await mapboxMap.setCamera(
        mapbox.CameraOptions(
          center: _centerPoint,
          zoom: 15.0,
          bearing: pos.heading,
        ),
      );

      // Initialize circle manager
      _circleManager =
          await mapboxMap.annotations.createCircleAnnotationManager();
      await _updateCircle(forceUpdate: true);
    } catch (e) {
      debugPrint('Error setting up map: $e');
    }
  }

  Future<void> _updateCircle({bool forceUpdate = false}) async {
    if (_mapboxMap == null ||
        _centerPoint == null ||
        _circleManager == null ||
        _isDisposed ||
        !mounted) {
      return;
    }

    try {
      final cameraState = await _mapboxMap!.getCameraState();
      if (!forceUpdate &&
          cameraState.zoom == _lastZoom &&
          _circleAnnotationId != null) {
        return;
      }
      _lastZoom = cameraState.zoom;

      final double groundResolution =
          156543.03392 *
          math.cos(_centerPoint!.coordinates.lat * math.pi / 180) /
          math.pow(2, cameraState.zoom);
      final double pixelRadius = _radiusMeters.value / groundResolution;

      final options = mapbox.CircleAnnotationOptions(
        geometry: _centerPoint!,
        circleRadius: pixelRadius,
        circleColor: Color(0xFF33AFFF).toARGB32(),
        circleOpacity: 0.3,
        circleStrokeWidth: 1.5,
        circleStrokeColor: Color(0xFF0077FF).toARGB32(),
      );

      if (_circleAnnotationId == null) {
        final annotation = await _circleManager!.create(options);
        _circleAnnotationId = annotation.id;
      } else {
        await _circleManager!.update(
          mapbox.CircleAnnotation(
            id: _circleAnnotationId!,
            geometry: _centerPoint!,
            circleRadius: pixelRadius,
            circleColor: Color(0xFF33AFFF).toARGB32(),
            circleOpacity: 0.3,
            circleStrokeWidth: 1.5,
            circleStrokeColor: Color(0xFF0077FF).toARGB32(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating circle: $e');
      if (e.toString().contains('No manager or annotation found')) {
        _circleAnnotationId = null;
        _circleManager =
            await _mapboxMap!.annotations.createCircleAnnotationManager();
        await _updateCircle(forceUpdate: true);
      }
    }
  }

  Future<geo.Position> _determinePosition() async {
    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }
    if (permission == geo.LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }
    return await geo.Geolocator.getCurrentPosition();
  }

  void _startAreaCapture() async {
    try {
      // Calculate end time: current time + selected duration (in minutes)
      final endTime = DateTime.now().add(Duration(minutes: _selectedDuration));

      // Create UserSettings for new fields
      final updatedSettings = _userSettings!.copyWith(
        isAreaCaptureActive: true,
        areaCaptureEnd: TemporalDateTime(endTime),
      );
      await Amplify.DataStore.save(updatedSettings);
      _userSettings = updatedSettings;

      setState(() {}); // Update UI

      if (!mounted) return;
      Navigator.pushNamed(context, '/ac_home');
    } catch (e) {
      debugPrint('Error starting area capture: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Center(child: Text('Failed to start area capture'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Set your capture area')),
      body:
          _isLoading
              ? CircularProgressIndicator()
              : SingleChildScrollView(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          'Sightings will be captured within this area only',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: mapbox.MapWidget(
                              styleUri: Util.mapStyle,
                              cameraOptions: mapbox.CameraOptions(
                                center: mapbox.Point(
                                  coordinates: mapbox.Position(
                                    -122.4194,
                                    37.7749,
                                  ),
                                ),
                                zoom: 15.0,
                              ),
                              onMapCreated: _onMapCreated,
                              onCameraChangeListener: (_) => _updateCircle(),
                              key: const ValueKey('map'),
                            ),
                          ),
                        ),
                        ValueListenableBuilder<double>(
                          valueListenable: _radiusMeters,
                          builder:
                              (context, radius, _) => SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor:
                                      Theme.of(context).colorScheme.primary,
                                  inactiveTrackColor: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.2),
                                  thumbColor:
                                      Theme.of(context).colorScheme.primary,
                                  overlayColor: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.12),
                                  trackHeight: 4.0,
                                ),
                                child: Slider(
                                  value: radius,
                                  min: 100.0,
                                  max: 2000.0,
                                  onChanged: (newRadius) {
                                    _radiusMeters.value = newRadius;
                                    _updateCircle(forceUpdate: true);
                                  },
                                ),
                              ),
                        ),
                        ValueListenableBuilder<double>(
                          valueListenable: _radiusMeters,
                          builder:
                              (context, _, _) => Text(
                                'Capture radius: ${_radiusMeters.value.toInt()}m',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Session duration',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(width: 20),
                            DropdownButton<int>(
                              value: _selectedDuration,
                              // dropdownColor: Colors.black,
                              // style: TextStyle(color: Colors.white),
                              items:
                                  _durations.map((duration) {
                                    return DropdownMenuItem<int>(
                                      value: duration,
                                      child: Text(
                                        '$duration minutes',
                                        // style: TextStyle(color: Colors.white),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDuration = value!;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        DarkButton(
                          text: 'Start Area Capture',
                          onPressed: _startAreaCapture,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
