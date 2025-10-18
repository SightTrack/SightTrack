import 'package:sighttrack/barrel.dart';

import 'package:flutter/material.dart';

class AllSightingsScreen extends StatefulWidget {
  const AllSightingsScreen({super.key});

  @override
  State<AllSightingsScreen> createState() => _AllSightingsScreenState();
}

class _AllSightingsScreenState extends State<AllSightingsScreen> {
  List<Sighting> sightings = [];
  List<Sighting> filteredSightings = [];
  bool isLoading = true;
  late StreamSubscription _subscription;
  String _searchQuery = '';
  final Map<String, String> _imageUrlCache = {}; // Cache for S3 URLs

  @override
  void initState() {
    super.initState();
    _fetchAllSightings();
    _setupSubscription();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filterSightings();
    });
  }

  void _filterSightings() {
    if (_searchQuery.isEmpty) {
      filteredSightings = List.from(sightings);
    } else {
      filteredSightings =
          sightings.where((sighting) {
            final species = sighting.species.toLowerCase();
            final username =
                (sighting.user?.display_username ?? '').toLowerCase();
            return species.contains(_searchQuery) ||
                username.contains(_searchQuery);
          }).toList();
    }
  }

  Future<void> _fetchAllSightings() async {
    try {
      final result = await Amplify.DataStore.query(Sighting.classType);
      setState(() {
        sightings =
            result..sort(
              (a, b) => b.timestamp.getDateTimeInUtc().compareTo(
                a.timestamp.getDateTimeInUtc(),
              ),
            );
        _filterSightings();
        isLoading = false;
      });
    } catch (e) {
      Log.e('Error fetching sightings: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _setupSubscription() {
    _subscription = Amplify.DataStore.observe(Sighting.classType).listen((
      event,
    ) {
      if (!mounted) return;
      setState(() {
        if (event.eventType == EventType.delete) {
          sightings.removeWhere((s) => s.id == event.item.id);
        } else if (event.eventType == EventType.create) {
          sightings.add(event.item);
          sightings.sort(
            (a, b) => b.timestamp.getDateTimeInUtc().compareTo(
              a.timestamp.getDateTimeInUtc(),
            ),
          );
        } else if (event.eventType == EventType.update) {
          final index = sightings.indexWhere((s) => s.id == event.item.id);
          if (index != -1) {
            sightings[index] = event.item;
            sightings.sort(
              (a, b) => b.timestamp.getDateTimeInUtc().compareTo(
                a.timestamp.getDateTimeInUtc(),
              ),
            );
          }
        }
        _filterSightings();
      });
    }, onError: (e) => Log.e('Error in DataStore subscription: $e'));
  }

  Future<void> _refreshSightings() async {
    await _fetchAllSightings();
  }

  Future<String> _getImageUrl(String photoKey) async {
    // Check if URL is already in cache
    if (_imageUrlCache.containsKey(photoKey)) {
      return _imageUrlCache[photoKey]!;
    }

    // If not in cache, fetch from S3 and cache it
    try {
      final url = await Util.fetchFromS3(photoKey);
      _imageUrlCache[photoKey] = url;
      return url;
    } catch (e) {
      Log.e('Error fetching image URL: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('All Sightings')),
      body: Column(
        children: [
          // Fixed search bar
          STSearchBar(
            hintText: 'Search by species or user...',
            onSearchChanged: _onSearchChanged,
          ),
          // Sightings list
          Expanded(
            child: Container(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredSightings.isEmpty
                      ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No sightings found'
                              : 'No sightings match your search',
                          style: TextStyle(fontSize: 16.0, color: Colors.grey),
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _refreshSightings,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(1),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 1.0,
                                crossAxisSpacing: 1,
                                mainAxisSpacing: 1,
                              ),
                          itemCount: filteredSightings.length,
                          itemBuilder: (context, index) {
                            final sighting = filteredSightings[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ViewSightingScreen(
                                          sighting: sighting,
                                        ),
                                  ),
                                );
                              },
                              child: Hero(
                                tag: 'sighting-${sighting.id}',
                                child: Container(
                                  color: Colors.grey[200],
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      FutureBuilder<String>(
                                        future: _getImageUrl(sighting.photo),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          }
                                          if (snapshot.hasError ||
                                              !snapshot.hasData) {
                                            return const Center(
                                              child: Icon(Icons.error),
                                            );
                                          }
                                          return Image.network(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                            cacheWidth:
                                                300, // Optimize memory usage for grid
                                            frameBuilder: (
                                              context,
                                              child,
                                              frame,
                                              wasSynchronouslyLoaded,
                                            ) {
                                              if (wasSynchronouslyLoaded) {
                                                return child;
                                              }
                                              return AnimatedOpacity(
                                                opacity: frame == null ? 0 : 1,
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                curve: Curves.easeOut,
                                                child:
                                                    frame == null
                                                        ? Container(
                                                          color:
                                                              Colors.grey[300],
                                                        )
                                                        : child,
                                              );
                                            },
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return const Center(
                                                child: Icon(Icons.error),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                            vertical: 4.0,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Colors.black.withOpacity(0.7),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                          child: Text(
                                            sighting.species,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
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
