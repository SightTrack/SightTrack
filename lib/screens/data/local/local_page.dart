import 'dart:convert';
import 'package:sighttrack/barrel.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:flutter/services.dart' show rootBundle;

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

  Future<void> _drawCityBoundaryFromGeoJson() async {
    if (_mapboxMap == null) return;

    try {
      final geoJsonStr = await rootBundle.loadString(
        'assets/city_border.geojson',
      );
      final geo = json.decode(geoJsonStr);

      // Extract coordinates for the first polygon feature
      final coordinates =
          geo['features'][0]['geometry']['coordinates'][0] as List;

      // Map GeoJSON points (lon, lat) to mapbox.Position
      final positions =
          coordinates.map<mapbox.Position>((point) {
            final lon = point[0] as double;
            final lat = point[1] as double;
            return mapbox.Position(lon, lat);
          }).toList();

      final polygonManager =
          await _mapboxMap!.annotations.createPolygonAnnotationManager();

      await polygonManager.deleteAll();

      await polygonManager.create(
        mapbox.PolygonAnnotationOptions(
          geometry: mapbox.Polygon(coordinates: [positions]),
          fillColor:
              const Color.fromARGB(51, 0, 0, 255).value, // 20% opacity blue
          fillOutlineColor: const Color(0xFF0000FF).value, // solid blue outline
          // Removed fillOpacity, baked into ARGB
        ),
      );
    } catch (e) {
      debugPrint('Error drawing city boundary: $e');
    }
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

                  await _addMarkersToMap(); // <-- await this
                  await _drawCityBoundaryFromGeoJson(); // <-- await this
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Map error: $e')));
                }
              },
              cameraOptions: mapbox.CameraOptions(
                center: mapbox.Point(
                  coordinates: mapbox.Position(
                    center.longitude, // longitude first
                    center.latitude, // latitude second
                  ),
                ),
                zoom: 10.0,
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
