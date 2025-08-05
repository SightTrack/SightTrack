import 'package:sighttrack/barrel.dart';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:http/http.dart' as http;

class MapPickerScreen extends StatefulWidget {
  final geo.Position? initialPosition;

  const MapPickerScreen({super.key, this.initialPosition});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  mapbox.MapboxMap? _mapboxMap;
  geo.Position? _selectedPosition;
  final String hintText = 'Search for a location...';

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final token = dotenv.env['MAPBOX_TOKEN'];
      if (token == null) {
        Log.e('Mapbox token not found');
        return;
      }

      final encodedQuery = Uri.encodeComponent(query.trim());
      final url =
          'https://api.mapbox.com/geocoding/v5/mapbox.places/$encodedQuery.json?access_token=$token&limit=1';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;

        if (features.isNotEmpty) {
          final feature = features.first;
          final coordinates = feature['center'] as List;
          final longitude = coordinates[0] as double;
          final latitude = coordinates[1] as double;
          final placeName = feature['place_name'] as String;

          // Update the selected position
          setState(() {
            _selectedPosition = geo.Position(
              longitude: longitude,
              latitude: latitude,
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

          // Move the map to the searched location
          if (_mapboxMap != null) {
            await _mapboxMap!.flyTo(
              mapbox.CameraOptions(
                center: mapbox.Point(
                  coordinates: mapbox.Position(longitude, latitude),
                ),
                zoom: 15.0,
              ),
              mapbox.MapAnimationOptions(duration: 1000),
            );
          }

          Log.i('Location found: $placeName at $latitude, $longitude');
        } else {
          Log.w('No results found for: $query');
        }
      } else {
        Log.e('Geocoding API error: ${response.statusCode}');
      }
    } catch (e) {
      Log.e('Error searching location: $e');
    }
  }

  Future<void> _resetToUserLocation() async {
    try {
      final position = await Util.getCurrentPosition();

      // Update the selected position
      setState(() {
        _selectedPosition = position;
      });

      // Move the map to the user's current location
      if (_mapboxMap != null) {
        await _mapboxMap!.flyTo(
          mapbox.CameraOptions(
            center: mapbox.Point(
              coordinates: mapbox.Position(
                position.longitude,
                position.latitude,
              ),
            ),
            zoom: 15.0,
          ),
          mapbox.MapAnimationOptions(duration: 1000),
        );
      }

      Log.i(
        'Reset to user location: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      Log.e('Error getting user location: $e');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to get your location: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onMapCreated(mapbox.MapboxMap mapboxMap) async {
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

    if (_selectedPosition != null) {
      await _mapboxMap!.setCamera(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(
              _selectedPosition!.longitude,
              _selectedPosition!.latitude,
            ),
          ),
          zoom: 15.0,
        ),
      );
    }
  }

  void _onCameraChange(mapbox.CameraChangedEventData eventData) async {
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
      appBar: AppBar(title: const Text('Select Location')),
      body: Stack(
        children: [
          // Map widget
          Positioned.fill(
            child: mapbox.MapWidget(
              styleUri: Util.mapStyle,
              onMapCreated: _onMapCreated,
              onCameraChangeListener: _onCameraChange,
              cameraOptions: mapbox.CameraOptions(
                center: mapbox.Point(
                  coordinates: mapbox.Position(
                    // Default is San Francisco
                    _selectedPosition?.longitude ?? -122.4194,
                    _selectedPosition?.latitude ?? 37.7749,
                  ),
                ),
                zoom: 15.0,
              ),
            ),
          ),
          // Search bar and reset button at the top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Search bar (takes most of the space)
                Expanded(
                  child: STSearchBar(
                    hintText: hintText,
                    onSearchChanged: _searchLocation,
                  ),
                ),
                const SizedBox(width: 8),
                // Reset button
                Container(
                  height: 48, // Match the search bar height
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _resetToUserLocation,
                    icon: const Icon(Icons.my_location, color: Colors.white),
                    tooltip: 'Go to my location',
                  ),
                ),
              ],
            ),
          ),
          // Center pin
          const Center(
            child: Icon(Icons.location_pin, color: Colors.red, size: 40),
          ),
          // Continue button at the bottom
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
                  onPressed: () {
                    Log.i(
                      'Custom location set, returning: ${_selectedPosition?.latitude}, ${_selectedPosition?.longitude}',
                    );
                    Navigator.pop(context, _selectedPosition);
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
