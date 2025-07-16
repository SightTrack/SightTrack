import 'package:sighttrack/barrel.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocalView extends StatefulWidget {
  const LocalView({super.key});

  @override
  State<LocalView> createState() => _LocalViewState();
}

class _LocalViewState extends State<LocalView> {
  bool _isLoading = true;
  List<Sighting> _sightings = [];
  Map<String, double> _moransIResults = {};
  DateTime? _startTimeFilter;
  mapbox.MapboxMap? _mapboxMap;

  @override
  void initState() {
    super.initState();
    _startTimeFilter = DateTime.now().subtract(const Duration(days: 30));
  }

  Future<void> _drawCityBoundaryForCity(String cityName) async {
  if (_mapboxMap == null) {
    debugPrint('MapboxMap is not initialized.');
    return;
  }

  try {
    final geoJsonStr = await rootBundle.loadString('assets/city_border.geojson');
    final geo = json.decode(geoJsonStr);

    // cityName = 'NEW YORK'; 

    final features = geo['features'] as List;

    // Normalize and trim the input city name for robust case-insensitive comparison
    final lowerCaseCityName = cityName.toLowerCase().trim();
    debugPrint('Searching for city (normalized input from placemarks): "$lowerCaseCityName"');

    // Find the city feature by name, specifically checking 'properties.name'
    // This now performs a case-insensitive and trimmed comparison
    final cityFeature = features.firstWhere(
      (f) {
        final props = f['properties'] ?? {};
        // ONLY check the 'name' property. Default to empty string if not found.
        final namePropertyRaw = (props['NAME'] ?? '');
        final namePropertyNormalized = namePropertyRaw.toString().toLowerCase().trim();

        // Debugging print to see what city names are being checked in the GeoJSON
        //debugPrint('  Checking GeoJSON feature name (properties.name): "$namePropertyNormalized" against "$lowerCaseCityName"');

        return namePropertyNormalized == lowerCaseCityName;
      },
      orElse: () => null, // Return null if no matching feature is found
    );

    if (cityFeature == null) {
      debugPrint('City "$cityName" (normalized to "$lowerCaseCityName") not found in GeoJSON using "properties.name".');
      return;
    }

    // Ensure the geometry and coordinates exist and are in the expected format
    if (cityFeature['geometry'] == null ||
        cityFeature['geometry']['coordinates'] == null ||
        !(cityFeature['geometry']['coordinates'] is List) ||
        (cityFeature['geometry']['coordinates'] as List).isEmpty) {
      debugPrint('Invalid geometry or coordinates for city "$cityName".');
      return;
    }

    // The GeoJSON 'Polygon' type typically has coordinates structured as
    // [[[lon, lat], [lon, lat], ...]] for a single exterior ring.
    // This code assumes a single exterior ring at index 0.
    final coordinates = cityFeature['geometry']['coordinates'][0] as List;

    final positions = coordinates.map<mapbox.Position>((point) {
      final lon = point[0] as double;
      final lat = point[1] as double;
      return mapbox.Position(lon, lat);
    }).toList();

    // Create a PolygonAnnotationManager if it doesn't already exist or get an existing one.
    // In a real application, you might want to manage this manager more globally
    // to avoid recreating it on every call.
    final polygonManager = await _mapboxMap!.annotations.createPolygonAnnotationManager();

    // Clear existing annotations if you only want to show one city boundary at a time
    // await polygonManager.deleteAll(); // Uncomment if you want to clear previous boundaries

    await polygonManager.create(
      mapbox.PolygonAnnotationOptions(
        geometry: mapbox.Polygon(coordinates: [positions]),
        // Use ARGB hex values for colors (e.g., 0xAARRGGBB)
        fillColor: const Color(0x000000FF).value,
        fillOutlineColor: const Color(0xff08948c).value, // Opaque blue outline
      ),
    );
    
    debugPrint('City boundary for "$cityName" drawn successfully.');
  } catch (e) {
    debugPrint('Error drawing city boundary: $e');
    // You might want to show a user-friendly message here in a real app
  }
}



Future<String?> _getCurrentCityName() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission not granted');
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      print(placemarks.first.locality);
      return placemarks.first.locality; // Returns the city name
    }
  } catch (e) {
    debugPrint('Error getting city name: $e');
  }

  return null;
}





  Future<void> _addMarkersToMap() async {
    if (_mapboxMap == null) return;

    final annotationManager =
        await _mapboxMap!.annotations.createPointAnnotationManager();


    await annotationManager.deleteAll();

    for (var sighting in _sightings) {
      await annotationManager.create(
        mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(sighting.longitude, sighting.latitude),
          ),
          textField: sighting.species,
          textOffset: [0, -2],
          textColor: Colors.white.toARGB32(),
          iconImage: 'marker',
          iconSize: 1.0,
        ),
      );
    }
  }

  latitudelongitude _calculateUserCityCenter() {
    final validSightings =
        _sightings.where((s) {
          return s.latitude.isFinite &&
              s.longitude.isFinite &&
              s.latitude >= -90.0 &&
              s.latitude <= 90.0 &&
              s.longitude >= -180.0 &&
              s.longitude <= 180.0 &&
              s.city != null &&
              s.city!.isNotEmpty;
        }).toList();

    if (validSightings.isNotEmpty) {
      final citySighting = validSightings.first;
      return latitudelongitude(citySighting.latitude, citySighting.longitude);
    }

    // Default to San Francisco coords if no valid city found
    return const latitudelongitude(37.7749, -122.4194);
  }

  @override
  Widget build(BuildContext context) {
    final center = _calculateUserCityCenter();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            mapbox.MapWidget(
              key: const ValueKey('mapWidget'),
              onMapCreated: (controller) async {
  try {
    Util.setupMapbox(controller);
    _mapboxMap = controller;

    await _addMarkersToMap();

    final cityName = await _getCurrentCityName();
    if (cityName != null) {
      await _drawCityBoundaryForCity(cityName);
    } else {
      debugPrint('Could not determine user city.');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Map error: $e')),
    );
  }
},
              cameraOptions: mapbox.CameraOptions(
                center: mapbox.Point(
                  coordinates: mapbox.Position(
                    center.longitude, // longitude first
                    center.latitude, // latitude second
                  ),
                ),
                zoom: 3.0,
              ),
              styleUri: Util.mapStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class latitudelongitude {
  final double latitude;
  final double longitude;

  const latitudelongitude(this.latitude, this.longitude);
}
