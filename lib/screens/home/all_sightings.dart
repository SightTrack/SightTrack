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
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: filteredSightings.length,
                          itemBuilder: (context, index) {
                            final sighting = filteredSightings[index];
                            return Material(
                              // color: Colors.white,
                              child: InkWell(
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
                                splashColor: Colors.blueGrey.withValues(
                                  alpha: 0.1,
                                ),
                                highlightColor: Colors.grey.withValues(
                                  alpha: 0.05,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 12.0,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade200,
                                        width: 0.1,
                                      ),
                                    ),
                                    boxShadow: [
                                      // if (index == 0)
                                      //   BoxShadow(
                                      //     color: Colors.grey.withValues(alpha: 0.05),
                                      //     offset: const Offset(0, 1),
                                      //     blurRadius: 2.0,
                                      //   ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          sighting.species,
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              sighting.user?.display_username ??
                                                  'Unknown',
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2.0),
                                            Text(
                                              DateFormat(
                                                'MMM dd, HH:mm',
                                              ).format(
                                                sighting.timestamp
                                                    .getDateTimeInUtc()
                                                    .toLocal(),
                                              ),
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
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
