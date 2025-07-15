import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';
import 'package:flutter/services.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = true;
  Map<String, int> _stats = {};
  List<Sighting> _recentSightings = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      final users = await Amplify.DataStore.query(User.classType);
      final sightings = await Amplify.DataStore.query(Sighting.classType);

      final speciesSet = sightings.map((s) => s.species).toSet();
      final totalVolunteerHours = Volunteer.calculateTotalServiceHours(
        sightings,
      );

      final recent =
          sightings..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _stats = {
          'users': users.length,
          'sightings': sightings.length,
          'species': speciesSet.length,
          'hours': totalVolunteerHours.round(),
        };
        _recentSightings = recent.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      Log.e('Error loading dashboard: $e');
      setState(() => _isLoading = false);
    }
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
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Grid
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatCard(
                  'Total Users',
                  '${_stats['users'] ?? 0}',
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Total Sightings',
                  '${_stats['sightings'] ?? 0}',
                  Icons.camera_alt,
                  Colors.green,
                ),
                _buildStatCard(
                  'Species Recorded',
                  '${_stats['species'] ?? 0}',
                  Icons.pets,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Volunteer Hours',
                  '${_stats['hours'] ?? 0}h',
                  Icons.volunteer_activism,
                  Colors.purple,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Recent Activity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Sightings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_recentSightings.isEmpty)
                    const Text('No recent sightings')
                  else
                    Column(
                      children:
                          _recentSightings.map((sighting) {
                            return ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: Text(sighting.species),
                              subtitle: Text(
                                sighting.city ?? 'Unknown location',
                              ),
                              trailing: Text(
                                _formatDateTime(
                                  sighting.timestamp.getDateTimeInUtc(),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _loadDashboardData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Data'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          _exportDashboardReport();
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Export Report'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            // const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _exportDashboardReport() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            title: Text('Exporting Dashboard Report'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating platform analytics report...'),
              ],
            ),
          );
        },
      );

      Log.i('Dashboard export: Starting dashboard report export');

      // Query all data for comprehensive analytics
      final users = await Amplify.DataStore.query(User.classType);
      final sightings = await Amplify.DataStore.query(Sighting.classType);
      final userSettings = await Amplify.DataStore.query(
        UserSettings.classType,
      );

      // Calculate comprehensive statistics
      final speciesSet = sightings.map((s) => s.species).toSet();
      final totalVolunteerHours = Volunteer.calculateTotalServiceHours(
        sightings,
      );

      // Calculate time-based statistics
      final now = DateTime.now();
      final last30Days = now.subtract(const Duration(days: 30));
      final last7Days = now.subtract(const Duration(days: 7));

      final recentSightings30Days =
          sightings
              .where((s) => s.timestamp.getDateTimeInUtc().isAfter(last30Days))
              .length;
      final recentSightings7Days =
          sightings
              .where((s) => s.timestamp.getDateTimeInUtc().isAfter(last7Days))
              .length;

      // Geographic distribution
      final citiesMap = <String, int>{};
      final countriesMap = <String, int>{};
      for (final sighting in sightings) {
        final city = sighting.city ?? 'Unknown City';
        citiesMap[city] = (citiesMap[city] ?? 0) + 1;
      }
      for (final user in users) {
        final country = user.country ?? 'Unknown Country';
        countriesMap[country] = (countriesMap[country] ?? 0) + 1;
      }

      // Species distribution
      final speciesMap = <String, int>{};
      for (final sighting in sightings) {
        speciesMap[sighting.species] = (speciesMap[sighting.species] ?? 0) + 1;
      }

      // User engagement metrics
      final usersWithSightings =
          users.where((u) => sightings.any((s) => s.user?.id == u.id)).length;
      final averageSightingsPerUser =
          users.isNotEmpty ? sightings.length / users.length : 0.0;

      // School distribution
      final schoolsMap = <String, int>{};
      for (final user in users) {
        final school = user.school ?? 'Unknown School';
        schoolsMap[school] = (schoolsMap[school] ?? 0) + 1;
      }

      // Active users (users with settings indicating recent activity)
      final activeUsers =
          userSettings.where((s) => s.isAreaCaptureActive == true).length;

      // Sort data for top lists
      final topSpecies =
          speciesMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      final topCities =
          citiesMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      final topCountries =
          countriesMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      final topSchools =
          schoolsMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      // Create comprehensive export data
      final exportData = {
        'reportInfo': {
          'title': 'SightTrack Platform Analytics Dashboard',
          'generatedAt': DateTime.now().toIso8601String(),
          'reportType': 'Platform Overview',
          'period': 'All Time Data',
        },
        'platformStatistics': {
          'totalUsers': users.length,
          'totalSightings': sightings.length,
          'uniqueSpecies': speciesSet.length,
          'totalVolunteerHours': totalVolunteerHours,
          'activeUsers': activeUsers,
          'usersWithSightings': usersWithSightings,
          'userEngagementRate':
              users.isNotEmpty
                  ? (usersWithSightings / users.length * 100)
                  : 0.0,
          'averageSightingsPerUser': averageSightingsPerUser,
        },
        'recentActivity': {
          'sightingsLast7Days': recentSightings7Days,
          'sightingsLast30Days': recentSightings30Days,
          'dailyAverageLast30Days': recentSightings30Days / 30,
          'dailyAverageLast7Days': recentSightings7Days / 7,
        },
        'geographicDistribution': {
          'totalCountries': countriesMap.length,
          'totalCities': citiesMap.length,
          'topCountries':
              topCountries
                  .take(10)
                  .map((e) => {'country': e.key, 'userCount': e.value})
                  .toList(),
          'topCities':
              topCities
                  .take(10)
                  .map((e) => {'city': e.key, 'sightingCount': e.value})
                  .toList(),
        },
        'biodiversityMetrics': {
          'totalSpeciesRecorded': speciesSet.length,
          'averageSightingsPerSpecies':
              speciesSet.isNotEmpty
                  ? sightings.length / speciesSet.length
                  : 0.0,
          'topSpecies':
              topSpecies
                  .take(10)
                  .map((e) => {'species': e.key, 'sightingCount': e.value})
                  .toList(),
        },
        'educationalMetrics': {
          'totalSchools': schoolsMap.length,
          'topSchoolsByUsers':
              topSchools
                  .take(10)
                  .map((e) => {'school': e.key, 'userCount': e.value})
                  .toList(),
        },
        'recentSightingsDetails':
            _recentSightings
                .map(
                  (sighting) => {
                    'id': sighting.id,
                    'species': sighting.species,
                    'city': sighting.city,
                    'timestamp': sighting.timestamp.format(),
                    'description': sighting.description,
                    'userId': sighting.user?.id,
                  },
                )
                .toList(),
        'systemHealth': {
          'totalDataRecords':
              users.length + sightings.length + userSettings.length,
          'dataIntegrityScore': _calculateDataIntegrityScore(users, sightings),
          'averageRecordsPerDay': _calculateAverageRecordsPerDay(sightings),
        },
      };

      // Convert to pretty JSON string
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Create filename with timestamp
      final timestamp = DateFormat(
        'yyyy-MM-dd_HH-mm-ss',
      ).format(DateTime.now());
      final filename = 'sighttrack_dashboard_report_$timestamp.json';

      // Show export complete dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Export Data'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Successfully exported platform analytics report'),
                  const SizedBox(height: 8),
                  Text(
                    '${users.length} users • ${sightings.length} sightings • ${speciesSet.length} species',
                  ),
                  const SizedBox(height: 8),
                  Text('File: $filename'),
                  const SizedBox(height: 8),
                  Text(
                    'Size: ${(jsonString.length / 1024).toStringAsFixed(1)} KB',
                  ),
                ],
              ),
              actions: [
                DarkButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _copyToClipboard(jsonString);
                  },
                  text: 'Copy to Clipboard',
                ),
                DarkButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showJsonPreview(jsonString, filename);
                  },
                  text: 'Preview',
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }

      Log.i('Dashboard export: Report export completed successfully');
    } catch (e) {
      Log.e('Dashboard export error: $e');

      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  double _calculateDataIntegrityScore(
    List<User> users,
    List<Sighting> sightings,
  ) {
    // Simple data integrity score based on completeness
    int totalFields = 0;
    int completeFields = 0;

    for (final user in users) {
      totalFields += 6; // email, username, school, country, age, bio
      if (user.email.isNotEmpty) completeFields++;
      if (user.display_username.isNotEmpty) completeFields++;
      if (user.school != null && user.school!.isNotEmpty) completeFields++;
      if (user.country != null && user.country!.isNotEmpty) completeFields++;
      if (user.age != null) completeFields++;
      if (user.bio != null && user.bio!.isNotEmpty) completeFields++;
    }

    for (final sighting in sightings) {
      totalFields += 4; // species, city, description, photo
      if (sighting.species.isNotEmpty) completeFields++;
      if (sighting.city != null && sighting.city!.isNotEmpty) completeFields++;
      if (sighting.description != null && sighting.description!.isNotEmpty)
        completeFields++;
      if (sighting.photo.isNotEmpty) completeFields++;
    }

    return totalFields > 0 ? (completeFields / totalFields * 100) : 100.0;
  }

  double _calculateAverageRecordsPerDay(List<Sighting> sightings) {
    if (sightings.isEmpty) return 0.0;

    final oldestSighting = sightings
        .map((s) => s.timestamp.getDateTimeInUtc())
        .reduce((a, b) => a.isBefore(b) ? a : b);

    final daysSinceOldest = DateTime.now().difference(oldestSighting).inDays;
    return daysSinceOldest > 0
        ? sightings.length / daysSinceOldest
        : sightings.length.toDouble();
  }

  void _copyToClipboard(String content) async {
    try {
      await Clipboard.setData(ClipboardData(text: content));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dashboard report copied to clipboard'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      Log.e('Error copying to clipboard: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showJsonPreview(String jsonString, String filename) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        filename,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        jsonString,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _copyToClipboard(jsonString);
                      },
                      child: const Text('Copy All'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
