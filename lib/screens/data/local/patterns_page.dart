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
  List<Sighting> individualsightings = [];
  List<Sighting> filteredSightings = [];
  DateTime? _startTimeFilter;
  mapbox.MapboxMap? _mapboxMap;
  String _searchQuery = '';
  String? _selectedSpecies; // Track selected species
  List<String> _uniqueSpecies = []; // Store unique species
  mapbox.CircleAnnotationManager? _annotationManager; // Store annotation manager

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

      // Collect unique species from _sightings
      _uniqueSpecies = _sightings
          .map((s) => s.species)
          .where((species) => species != null)
          .toSet()
          .cast<String>()
          .toList();

      // Set default selected species if available
      if (_uniqueSpecies.isNotEmpty) {
        _selectedSpecies = _uniqueSpecies.first;
        _updateFilteredSightings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching sightings: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  void _updateFilteredSightings() {
    if (_selectedSpecies != null) {
      filteredSightings = _sightings
          .where((sighting) => sighting.species == _selectedSpecies)
          .toList();
    } else {
      filteredSightings = _sightings;
    }
    _addMarkersToMap();
  }

  void _addMarkersToMap() async {
    if (_mapboxMap == null) return;

    // Create or reuse annotation manager
    if (_annotationManager == null) {
      _annotationManager = await _mapboxMap?.annotations.createCircleAnnotationManager();
    }

    // Clear all existing annotations
    await _annotationManager?.deleteAll();

    // Define color shades based on sighting age
    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));
    final sixMonthsAgo = now.subtract(const Duration(days: 180));
    final nineMonthsAgo = now.subtract(const Duration(days: 270));
    final threeMonthsAgo = now.subtract(const Duration(days: 90));

    // Create point annotations for filtered sightings with dynamic colors
    for (var sighting in filteredSightings) {
      if (sighting.timestamp == null) continue; // Skip if timestamp is null

      // Convert TemporalDateTime to DateTime for comparison
      DateTime sightingDateTime = DateTime.parse(sighting.timestamp.toString());

      // Determine color based on age
      Color markerColor;
      if (sightingDateTime.isBefore(oneYearAgo)) {
        markerColor = const Color.fromARGB(255, 69, 52, 1); // Dark yellow
      } else if (sightingDateTime.isBefore(nineMonthsAgo)) {
        markerColor = const Color.fromARGB(255, 117, 93, 1); // Medium yellow
      } else if (sightingDateTime.isBefore(sixMonthsAgo)) {
        markerColor = const Color.fromARGB(255, 221, 177, 2); // Medium yellow
      } else if (sightingDateTime.isBefore(threeMonthsAgo)) {
        markerColor = const Color.fromARGB(255, 251, 222, 104); // Medium yellow
      } else {
        markerColor = const Color.fromARGB(255, 246, 240, 178); // Bright yellow
      }

      await _annotationManager?.create(
        mapbox.CircleAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(
              sighting.displayLongitude ?? sighting.longitude,
              sighting.displayLatitude ?? sighting.latitude,
            ),
          ),
          circleRadius: 8,
          circleColor: markerColor.toARGB32(),
          circleBlur: 0.6,
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
            zoom: 3.0,
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

    // Filter species based on search query
    final filteredSpecies = _searchQuery.isEmpty
        ? _uniqueSpecies
        : _uniqueSpecies
            .where((species) =>
                species.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

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
                  // Initialize annotation manager when map is created
                  _annotationManager = await _mapboxMap?.annotations.createCircleAnnotationManager();
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
                ),
                child: _isLoading
                    ? Container()
                    : filteredSightings.isEmpty
                      ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No sightings found'
                              : 'No sightings match your search',
                          style: TextStyle(fontSize: 16.0, color: Colors.grey),
                        ),
                      )
                    : _uniqueSpecies.isEmpty
                        ? const Center(
                            child: Text('Species Filter'),
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
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox.shrink(),
                                    ],
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15.0,
                                    vertical: 8.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Species Filter',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        decoration: InputDecoration(
                                          hintText: 'Search species...',
                                          prefixIcon: Icon(Icons.search),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(
                                              color: Colors.black,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: const Color.fromARGB(255, 32, 28, 28),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _searchQuery = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Column(
                                  children: filteredSpecies.map((species) {
                                    return RadioListTile<String>(
                                      title: Text(species),
                                      value: species,
                                      groupValue: _selectedSpecies,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedSpecies = value;
                                          _updateFilteredSightings();
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
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

// Extension to convert Color to ARGB32 format for Mapbox
extension ColorExtension on Color {
  int toARGB32() {
    return (alpha << 24) | (red << 16) | (green << 8) | blue;
  }
}