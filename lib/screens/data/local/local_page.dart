import 'package:sighttrack/barrel.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

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
                  isTimeClaimed: s.isTimeClaimed,
                ),
              )
              .toList();

      final startTimeTemporal =
          _startTimeFilter != null ? TemporalDateTime(_startTimeFilter!) : null;

      _moransIResults = SpatialAutocorrelation.analyzeBiodiversityHotspots(
        sightings: _sightings,
        maxDistanceKm: 10.0,
        startTime: startTimeTemporal,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching sightings: $e')));
      }
    }
    setState(() => _isLoading = false);
  }

  void _addMarkersToMap() async {
    if (_mapboxMap == null) return;

    final annotationManager =
        await _mapboxMap?.annotations.createPointAnnotationManager();

    await annotationManager?.deleteAll();

    for (var sighting in _sightings) {
      await annotationManager?.create(
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
  final validSightings = _sightings.where((s) {
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

  // Default to London coords if no valid city found
const defaultLat = 37.7749;
const defaultLon = -122.4194;
  return const latitudelongitude(defaultLat, defaultLon);
}


  @override
  Widget build(BuildContext context) {
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
                    _calculateUserCityCenter().longitude,
                    _calculateUserCityCenter().latitude,
                  ),
                ),
                zoom: 12.0, // Zoom in to city level
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
                            builder: (context) => const ViewStatisticsPage(),
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
                      start: DateTime.now().subtract(const Duration(days: 30)),
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
                            rangeSelectionBackgroundColor:
                                theme.colorScheme.primary.withAlpha(128),
                            backgroundColor: theme.colorScheme.surface,
                            headerBackgroundColor: theme.colorScheme.primary,
                            headerForegroundColor: theme.colorScheme.onSurface,
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
                  ),
                  child: _isLoading
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
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 22),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.grey[600]!.withAlpha(51),
                                            borderRadius:
                                                BorderRadius.circular(2),
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
                                            horizontal: 15.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Biodiversity Scores',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.help),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const AboutBiodiversityScreen(),
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
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final species =
                                          _moransIResults.keys.elementAt(index);
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
                                        title: Text(species),
                                        subtitle: Text(
                                          'Score: ${moransI.toStringAsFixed(2)} ($distribution)',
                                        ),
                                      );
                                    },
                                    childCount: _moransIResults.length,
                                  ),
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

class latitudelongitude {
  final double latitude;
  final double longitude;

  const latitudelongitude(this.latitude, this.longitude);
}
