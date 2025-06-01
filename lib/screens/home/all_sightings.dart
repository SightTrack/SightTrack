import 'package:sighttrack/barrel.dart';

import 'package:flutter/material.dart';

class AllSightingsScreen extends StatefulWidget {
  const AllSightingsScreen({super.key});

  @override
  State<AllSightingsScreen> createState() => _AllSightingsScreenState();
}

class _AllSightingsScreenState extends State<AllSightingsScreen> {
  List<Sighting> sightings = [];
  bool isLoading = true;
  late StreamSubscription _subscription;

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
      });
    }, onError: (e) => Log.e('Error in DataStore subscription: $e'));
  }

  Future<void> _refreshSightings() async {
    await _fetchAllSightings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Sightings',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20.0),
        ),
      ),
      body: Container(
        color: Colors.grey[100],
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : sightings.isEmpty
                ? const Center(
                  child: Text(
                    'No sightings found',
                    style: TextStyle(fontSize: 16.0, color: Colors.grey),
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _refreshSightings,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: sightings.length,
                    itemBuilder: (context, index) {
                      final sighting = sightings[index];
                      return Material(
                        color: Colors.white,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        ViewSightingScreen(sighting: sighting),
                              ),
                            );
                          },
                          splashColor: Colors.blueGrey.withValues(alpha: 0.1),
                          highlightColor: Colors.grey.withValues(alpha: 0.05),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1.0,
                                ),
                              ),
                              boxShadow: [
                                if (index == 0)
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.05),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2.0,
                                  ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    sighting.species,
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
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
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w400,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2.0),
                                      Text(
                                        DateFormat('MMM dd, HH:mm').format(
                                          sighting.timestamp
                                              .getDateTimeInUtc()
                                              .toLocal(),
                                        ),
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.grey[600],
                                        ),
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
    );
  }
}
