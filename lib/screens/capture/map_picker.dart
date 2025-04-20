import 'package:sighttrack/barrel.dart';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapPickerScreen extends StatefulWidget {
  final geo.Position? initialPosition;

  const MapPickerScreen({super.key, this.initialPosition});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  MapboxMap? _mapboxMap;
  geo.Position? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    await _mapboxMap!.logo.updateSettings(LogoSettings(enabled: false));
    await _mapboxMap!.attribution.updateSettings(
      AttributionSettings(enabled: false),
    );
    await _mapboxMap!.scaleBar.updateSettings(ScaleBarSettings(enabled: false));

    await _mapboxMap!.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        puckBearingEnabled: true,
      ),
    );

    if (_selectedPosition != null) {
      await _mapboxMap!.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(
              _selectedPosition!.longitude,
              _selectedPosition!.latitude,
            ),
          ),
          zoom: 15.0,
        ),
      );
    }
  }

  void _onCameraChange(CameraChangedEventData eventData) async {
    if (_mapboxMap != null) {
      final cameraState = await _mapboxMap!.getCameraState();
      setState(() {
        _selectedPosition = geo.Position(
          longitude: cameraState.center.coordinates.lng as double,
          latitude: cameraState.center.coordinates.lat as double,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          MapWidget(
            styleUri: Util.mapStyle,
            onMapCreated: _onMapCreated,
            onCameraChangeListener: _onCameraChange,
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(
                  // Default is San Francisco
                  _selectedPosition?.longitude ?? -122.4194,
                  _selectedPosition?.latitude ?? 37.7749,
                ),
              ),
              zoom: 15.0,
            ),
          ),
          const Center(
            child: Icon(Icons.location_pin, color: Colors.red, size: 40),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                Log.i(
                  'Custom location set, returning: ${_selectedPosition?.latitude}, ${_selectedPosition?.longitude}',
                );
                Navigator.pop(context, _selectedPosition);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirm Location',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
