import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';
import 'package:sighttrack/screens/profile/edit_sighting.dart';

class YourSightingsScreen extends StatefulWidget {
  const YourSightingsScreen({super.key});

  @override
  State<YourSightingsScreen> createState() => _YourSightingsScreenState();
}

class _YourSightingsScreenState extends State<YourSightingsScreen> {
  List<Sighting> _sightings = [];
  List<Sighting> _filteredSightings = [];
  bool _isLoading = true;
  late StreamSubscription _subscription;
  String _searchQuery = '';
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      _currentUser = await Util.getUserModel();
      if (_currentUser != null) {
        await _fetchUserSightings();
        _setupSubscription();
      }
    } catch (e) {
      Log.e('Error initializing data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserSightings() async {
    try {
      final sightings = await Amplify.DataStore.query(
        Sighting.classType,
        where: Sighting.USER.eq(_currentUser!.id),
      );

      // Sort by creation date (most recent first)
      sightings.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

      setState(() {
        _sightings = sightings;
        _filteredSightings = sightings;
        _isLoading = false;
      });
    } catch (e) {
      Log.e('Error fetching user sightings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setupSubscription() {
    _subscription = Amplify.DataStore.observe(Sighting.classType).listen((
      event,
    ) {
      if (event.item.user?.id == _currentUser?.id) {
        _fetchUserSightings();
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filterSightings();
    });
  }

  void _filterSightings() {
    if (_searchQuery.isEmpty) {
      _filteredSightings = List.from(_sightings);
    } else {
      _filteredSightings =
          _sightings.where((sighting) {
            final species = sighting.species.toLowerCase();
            final city = (sighting.city ?? '').toLowerCase();
            return species.contains(_searchQuery) ||
                city.contains(_searchQuery);
          }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Sightings'), elevation: 0),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              )
              : Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search your sightings...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  // Stats Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    '${_sightings.length}',
                                    style:
                                        Theme.of(
                                          context,
                                        ).textTheme.headlineSmall,
                                  ),
                                  const Text('Total Sightings'),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    '${_sightings.map((s) => s.species).toSet().length}',
                                    style:
                                        Theme.of(
                                          context,
                                        ).textTheme.headlineSmall,
                                  ),
                                  const Text('Unique Species'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sightings List
                  Expanded(
                    child:
                        _filteredSightings.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'No sightings yet'
                                        : 'No sightings match your search',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'Start capturing wildlife to see your sightings here!'
                                        : 'Try adjusting your search terms',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _filteredSightings.length,
                              itemBuilder: (context, index) {
                                final sighting = _filteredSightings[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    title: Text(
                                      sighting.species,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sighting.city ?? 'Unknown location',
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDateTime(
                                            sighting.createdAt!
                                                .getDateTimeInUtc(),
                                          ),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Edit Sighting',
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 20,
                                          ),
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        EditSightingScreen(
                                                          sighting: sighting,
                                                        ),
                                              ),
                                            );

                                            // Refresh the sightings list if the edit was successful
                                            if (result == true) {
                                              _fetchUserSightings();
                                            }
                                          },
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                        ),
                                      ],
                                    ),
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
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    final hour = dateTime.hour;
    final minute = dateTime.minute;

    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '$month $day, $year at $displayHour:${minute.toString().padLeft(2, '0')} $amPm';
  }
}
