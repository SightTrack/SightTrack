import 'package:sighttrack/barrel.dart';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class LocalView extends StatefulWidget {
  const LocalView({super.key});

  @override
  State<LocalView> createState() => _LocalViewState();
}

class _LocalViewState extends State<LocalView> {
  List<Sighting> _sightings = [];
  Map<String, double> _moransIResults = {};
  bool _isLoading = true;
  DateTime? _startTimeFilter;
  mapbox.MapboxMap? _mapboxMap;

  @override
  void initState() {
    super.initState();
    _startTimeFilter = DateTime.now().subtract(const Duration(days: 30));
    _fetchSightings();
  }

  Future<void> _fetchSightings() async {
    setState(() => _isLoading = true);
    try {
      final sightings = await Amplify.DataStore.query(Sighting.classType);
      _sightings =
          sightings
              .map(
                (s) => Sighting(
                  id: s.id,
                  species: s.species,
                  photo: s.photo,
                  latitude: s.latitude,
                  longitude: s.longitude,
                  city: s.city,
                  displayLatitude: s.displayLatitude,
                  displayLongitude: s.displayLongitude,
                  timestamp: s.timestamp,
                  description: s.description,
                  user: s.user,
                ),
              )
              .toList();

      // Convert _startTimeFilter (DateTime) to TemporalDateTime
      final startTimeTemporal =
          _startTimeFilter != null ? TemporalDateTime(_startTimeFilter!) : null;

      // Calculate Moran's I for each species
      _moransIResults = SpatialAutocorrelation.analyzeBiodiversityHotspots(
        sightings: _sightings,
        maxDistanceKm: 10.0, // Consider sightings within 10 km
        startTime: startTimeTemporal,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching sightings: $e')));
    }
    setState(() => _isLoading = false);
  }

  void _addMarkersToMap() async {
    if (_mapboxMap == null) return;

    final annotationManager =
        await _mapboxMap?.annotations.createPointAnnotationManager();

    await annotationManager?.deleteAll();

    // Create point annotations for each sighting
    for (var sighting in _sightings) {
      await annotationManager?.create(
        mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(sighting.longitude, sighting.latitude),
          ),
          textField: sighting.species,
          textOffset: [0, -2],
          textColor: Colors.white.value,
          iconImage: 'marker',
          iconSize: 1.0,
        ),
      );
    }
  }

  LatLng _calculateMapCenter() {
    // Filter out invalid or null sightings
    final validSightings =
        _sightings.where((s) {
          if (!s.latitude.isFinite || !s.longitude.isFinite) {
            Log.e(
              'NON-FINITE COORDS: ID=${s.id}, Lat=${s.latitude}, Lon=${s.longitude}',
            );
            return false;
          }
          if (s.latitude < -90.0 ||
              s.latitude > 90.0 ||
              s.longitude < -180.0 ||
              s.longitude > 180.0) {
            Log.e(
              'OUT OF RANGE COORDS: ID=${s.id}, Lat=${s.latitude}, Lon=${s.longitude}',
            );
            return false;
          }
          return true;
        }).toList();
    Log.i('SIGHTINGS PROCESSED ${validSightings.length}/${_sightings.length}');

    const gridSize = 0.05; // Clustering sensitivity
    final clusters = <String, List<LatLng>>{};

    for (final s in validSightings) {
      final lat = s.latitude;
      final lon = s.longitude;
      final gridLat = (lat / gridSize).round() * gridSize;
      final gridLon = (lon / gridSize).round() * gridSize;
      final key = '${gridLat}_$gridLon';

      clusters.putIfAbsent(key, () => []).add(LatLng(lat, lon));
    }

    // Find the cluster with the most sightings
    List<LatLng> largestCluster = [];
    clusters.forEach((key, cluster) {
      if (cluster.length > largestCluster.length) {
        largestCluster = cluster;
      }
    });

    // Calculate the center of the largest cluster
    double avgLat =
        largestCluster.fold(0.0, (sum, point) => sum + point.latitude) /
        largestCluster.length;
    double avgLon =
        largestCluster.fold(0.0, (sum, point) => sum + point.longitude) /
        largestCluster.length;

    // Validatation
    if (!avgLat.isFinite ||
        !avgLon.isFinite ||
        avgLat < -90.0 ||
        avgLat > 90.0 ||
        avgLon < -180.0 ||
        avgLon > 180.0) {
      Log.e('INVALID CLUSTER CENTER: Lat=$avgLat, Lon=$avgLon');
      const defaultLat = 51.5074;
      const defaultLon = -0.1278;
      return const LatLng(defaultLat, defaultLon);
    }

    return LatLng(avgLat, avgLon);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        height: 300,
                        child: mapbox.MapWidget(
                          onMapCreated: (controller) async {
                            Util.setupMapbox(controller);

                            _mapboxMap = controller;
                            _addMarkersToMap();
                          },
                          cameraOptions: mapbox.CameraOptions(
                            center: mapbox.Point(
                              coordinates: mapbox.Position(
                                _calculateMapCenter().longitude,
                                _calculateMapCenter().latitude,
                              ),
                            ),
                            zoom: 1.0,
                          ),
                          styleUri: Util.mapStyle,
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: Colors.grey[850],
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              initialDateRange: DateTimeRange(
                                start: DateTime.now().subtract(
                                  const Duration(days: 30),
                                ),
                                end: DateTime.now(),
                              ),
                            );
                            if (picked != null) {
                              setState(() {
                                _startTimeFilter = picked.start;
                                _fetchSightings();
                              });
                            }
                          },
                          child: const Icon(
                            Icons.timelapse,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  Expanded(
                    child:
                        _moransIResults.isEmpty
                            ? const Center(
                              child: Text(
                                'No sightings found for the selected period.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                            : ListView.builder(
                              itemCount: _moransIResults.length,
                              itemBuilder: (context, index) {
                                final species = _moransIResults.keys.elementAt(
                                  index,
                                );
                                final moransI = _moransIResults[species]!;
                                String distribution;
                                if (moransI > 0.3) {
                                  distribution = 'Clustered';
                                } else if (moransI < -0.3) {
                                  distribution = 'Dispersed';
                                } else {
                                  distribution = 'Random';
                                }
                                return ListTile(
                                  title: Text(
                                    species,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    'Moran\'s I: ${moransI.toStringAsFixed(2)} ($distribution)',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}
