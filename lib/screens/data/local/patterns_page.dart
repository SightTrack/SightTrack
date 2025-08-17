import 'package:sighttrack/barrel.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:amplify_flutter/amplify_flutter.dart';

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

    // Create point annotations for each sighting
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

    return const latitudelongitude(37.7749, -122.4194);
  }

  Future<void> _resetCameraToUserLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (_mapboxMap != null) {
        await _mapboxMap!.flyTo(
          mapbox.CameraOptions(
            center: mapbox.Point(
              coordinates: mapbox.Position(pos.longitude, pos.latitude),
            ),
            zoom: 1.0,
            bearing: pos.heading,
          ),
          mapbox.MapAnimationOptions(duration: 500),
        );
        debugPrint('Camera reset to user location: (${pos.latitude}, ${pos.longitude})');
      } else {
        debugPrint('MapboxMap is not initialized.');
      }
    } catch (e) {
      debugPrint('Error resetting camera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resetting camera: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _calculateUserCityCenter();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: mapbox.MapWidget(
              key: const ValueKey('mapWidget'),
              onMapCreated: (controller) async {
                try {
                  Util.setupMapbox(controller);
                  _mapboxMap = controller;

                  _addMarkersToMap();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Map error: $e')),
                  );
                }
              },
              cameraOptions: mapbox.CameraOptions(
                center: mapbox.Point(
                  coordinates: mapbox.Position(
                    center.longitude,
                    center.latitude,
                  ),
                ),
                zoom: 1.0,
              ),
              styleUri: Util.mapStyle,
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: FloatingActionButton(
              onPressed: _resetCameraToUserLocation,
              backgroundColor: Colors.grey[850]!.withValues(alpha: 0.9),
              foregroundColor: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(
                  color: Colors.grey[700]!.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              splashColor: Colors.blueAccent.withValues(alpha: 0.2),
              tooltip: 'Reset to Current Location',
              child: Container(
                width: 48,
                height: 48,
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
                child: _isLoading
                    ? Container() // Replaced CircularProgressIndicator with empty Container
                    : _moransIResults.isEmpty
                        ? const Center(
                            child: Text(
                              '',
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
                                            '',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
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
    );
  }
}

class latitudelongitude {
  final double latitude;
  final double longitude;

  const latitudelongitude(this.latitude, this.longitude);
}