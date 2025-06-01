import 'package:flutter/material.dart';

import 'package:sighttrack/barrel.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class GlobalView extends StatefulWidget {
  const GlobalView({super.key});

  @override
  State<GlobalView> createState() => _GlobalViewState();
}

class _GlobalViewState extends State<GlobalView> {
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
      body: SafeArea(
        child: Stack(
          children: [
            Stack(
              children: [
                mapbox.MapWidget(
                  key: const ValueKey('mapWidget'),
                  onMapCreated: (controller) async {
                    try {
                      Util.setupMapbox(controller);
                      _mapboxMap = controller;
                      _addMarkersToMap();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error initializing map: $e')),
                      );
                    }
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
                Positioned(
                  top: 20,
                  left: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 45, 45, 45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        child: ModernDarkButton(
                          text: 'View Statistics',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const ViewStatisticsPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
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
                        builder: (context, child) {
                          final theme = Theme.of(context);
                          return Theme(
                            data: theme.copyWith(
                              colorScheme: theme.colorScheme.copyWith(
                                surface: theme.colorScheme.surface,
                                onSurface: theme.colorScheme.onSurface,
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.colorScheme.primary,
                                ),
                              ),
                              datePickerTheme: DatePickerThemeData(
                                rangeSelectionBackgroundColor: theme
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.5),
                                backgroundColor: theme.colorScheme.surface,
                                headerBackgroundColor:
                                    theme.colorScheme.primary,
                                headerForegroundColor:
                                    theme.colorScheme.onSurface,
                                surfaceTintColor: Colors.transparent,
                              ),
                              dialogTheme: DialogThemeData(
                                backgroundColor: theme.colorScheme.surface,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _startTimeFilter = picked.start;
                          _fetchSightings();
                        });
                      }
                    },
                    child: const Icon(Icons.timelapse, color: Colors.white),
                  ),
                ),
              ],
            ),
            DraggableScrollableSheet(
              initialChildSize: 0.15,
              minChildSize: 0.15,
              maxChildSize: 0.8,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: Colors.black.withValues(alpha: 50),
                    //     blurRadius: 10,
                    //     offset: const Offset(0, -2),
                    //   ),
                    // ],
                  ),
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _moransIResults.isEmpty
                          ? const Center(
                            child: Text(
                              'No sightings found for the selected period.',
                            ),
                          )
                          : CustomScrollView(
                            controller: scrollController,
                            slivers: [
                              SliverToBoxAdapter(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 22,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[600]!.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox.shrink(),
                                    ],
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Biodiversity Scores',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.help),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          AboutBiodiversityScreen(),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final species = _moransIResults.keys
                                      .elementAt(index);
                                  final moransI =
                                      _moransIResults[species] ?? 0.0;
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
                                      style: const TextStyle(),
                                    ),
                                    subtitle: Text(
                                      'Score: ${moransI.toStringAsFixed(2)} ($distribution)',
                                      style: const TextStyle(),
                                    ),
                                  );
                                }, childCount: _moransIResults.length),
                              ),
                            ],
                          ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}
