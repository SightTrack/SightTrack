import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';
import 'package:flutter/services.dart';

class VolunteerHoursManagementScreen extends StatefulWidget {
  const VolunteerHoursManagementScreen({super.key});

  @override
  State<VolunteerHoursManagementScreen> createState() =>
      _VolunteerHoursManagementScreenState();
}

class _VolunteerHoursManagementScreenState
    extends State<VolunteerHoursManagementScreen> {
  bool _isLoading = true;
  List<User> _users = [];
  Map<String, double> _userHours = {};
  Map<String, int> _userSightings = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final users = await Amplify.DataStore.query(User.classType);
      final sightings = await Amplify.DataStore.query(Sighting.classType);

      final userHours = <String, double>{};
      final userSightings = <String, int>{};

      for (final user in users) {
        final userSightingsList =
            sightings.where((s) => s.user?.id == user.id).toList();
        final hours = Volunteer.calculateTotalServiceHours(userSightingsList);

        userHours[user.id] = hours;
        userSightings[user.id] = userSightingsList.length;
      }

      setState(() {
        _users = users;
        _userHours = userHours;
        _userSightings = userSightings;
        _isLoading = false;
      });
    } catch (e) {
      Log.e('Error loading volunteer data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetUserHours(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Volunteer Hours'),
            content: Text(
              'Are you sure you want to reset volunteer hours for ${user.display_username}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reset'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        final userSightings = await Amplify.DataStore.query(
          Sighting.classType,
          where: Sighting.USER.eq(user.id),
        );

        for (final sighting in userSightings) {
          final updatedSighting = sighting.copyWith(isTimeClaimed: false);
          await Amplify.DataStore.save(updatedSighting);
        }

        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hours reset for ${user.display_username}')),
          );
        }
      } catch (e) {
        Log.e('Error resetting hours: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error resetting hours')),
          );
        }
      }
    }
  }

  void _exportReport() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            title: Text('Exporting Volunteer Report'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating volunteer hours report...'),
              ],
            ),
          );
        },
      );

      Log.i('Volunteer export: Starting volunteer hours report export');

      // Get all sightings to calculate detailed hours
      final allSightings = await Amplify.DataStore.query(Sighting.classType);

      // Calculate detailed statistics
      final totalHours = _userHours.values.fold(
        0.0,
        (sum, hours) => sum + hours,
      );
      final totalSightings = _userSightings.values.fold(
        0,
        (sum, count) => sum + count,
      );
      final activeVolunteers = _userHours.values.where((h) => h > 0).length;
      final averageHoursPerVolunteer =
          activeVolunteers > 0 ? totalHours / activeVolunteers : 0.0;

      // Create detailed user volunteer data
      final userVolunteerData =
          _users.map((user) {
            final userSightingsList =
                allSightings.where((s) => s.user?.id == user.id).toList();
            final hours = _userHours[user.id] ?? 0.0;
            final sightingsCount = _userSightings[user.id] ?? 0;

            // Get recent activity
            final recentSightings =
                userSightingsList
                    .where(
                      (s) => s.timestamp.getDateTimeInUtc().isAfter(
                        DateTime.now().subtract(const Duration(days: 30)),
                      ),
                    )
                    .length;

            return {
              'userId': user.id,
              'displayUsername': user.display_username,
              'email': user.email,
              'school': user.school,
              'country': user.country,
              'age': user.age,
              'volunteerHours': hours,
              'totalSightings': sightingsCount,
              'recentSightings30Days': recentSightings,
              'averageHoursPerSighting':
                  sightingsCount > 0 ? hours / sightingsCount : 0.0,
              'lastActivity':
                  userSightingsList.isNotEmpty
                      ? userSightingsList
                          .map((s) => s.timestamp.getDateTimeInUtc())
                          .reduce((a, b) => a.isAfter(b) ? a : b)
                          .toIso8601String()
                      : null,
            };
          }).toList();

      // Sort by volunteer hours (descending)
      userVolunteerData.sort(
        (a, b) => (b['volunteerHours'] as double).compareTo(
          a['volunteerHours'] as double,
        ),
      );

      // Create export data structure
      final exportData = {
        'reportInfo': {
          'title': 'SightTrack Volunteer Hours Report',
          'generatedAt': DateTime.now().toIso8601String(),
          'reportPeriod': 'All Time',
          'totalUsers': _users.length,
          'activeVolunteers': activeVolunteers,
        },
        'summary': {
          'totalVolunteerHours': totalHours,
          'totalSightings': totalSightings,
          'averageHoursPerVolunteer': averageHoursPerVolunteer,
          'averageHoursPerSighting':
              totalSightings > 0 ? totalHours / totalSightings : 0.0,
          'topVolunteerHours':
              userVolunteerData.isNotEmpty
                  ? userVolunteerData.first['volunteerHours']
                  : 0.0,
          'recentActivity30Days': userVolunteerData.fold(
            0,
            (sum, user) => sum + (user['recentSightings30Days'] as int),
          ),
        },
        'volunteerRankings':
            userVolunteerData.take(10).toList(), // Top 10 volunteers
        'allVolunteers': userVolunteerData,
        'hoursBySchool': _calculateHoursBySchool(userVolunteerData),
        'hoursByCountry': _calculateHoursByCountry(userVolunteerData),
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
      final filename = 'volunteer_hours_report_$timestamp.json';

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
                  Text('Successfully exported volunteer hours report'),
                  const SizedBox(height: 8),
                  Text(
                    '${_users.length} volunteers • ${totalHours.toStringAsFixed(1)} hours',
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
                ModernDarkButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _copyToClipboard(jsonString);
                  },
                  text: 'Copy to Clipboard',
                ),
                ModernDarkButton(
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

      Log.i('Volunteer export: Report export completed successfully');
    } catch (e) {
      Log.e('Volunteer export error: $e');

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

  Map<String, double> _calculateHoursBySchool(
    List<Map<String, dynamic>> userData,
  ) {
    final hoursBySchool = <String, double>{};
    for (final user in userData) {
      final school = user['school'] as String? ?? 'Unknown School';
      final hours = user['volunteerHours'] as double;
      hoursBySchool[school] = (hoursBySchool[school] ?? 0.0) + hours;
    }
    return hoursBySchool;
  }

  Map<String, double> _calculateHoursByCountry(
    List<Map<String, dynamic>> userData,
  ) {
    final hoursByCountry = <String, double>{};
    for (final user in userData) {
      final country = user['country'] as String? ?? 'Unknown Country';
      final hours = user['volunteerHours'] as double;
      hoursByCountry[country] = (hoursByCountry[country] ?? 0.0) + hours;
    }
    return hoursByCountry;
  }

  void _copyToClipboard(String content) async {
    try {
      await Clipboard.setData(ClipboardData(text: content));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Volunteer report copied to clipboard'),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalHours = _userHours.values.fold(0.0, (sum, hours) => sum + hours);
    final totalSightings = _userSightings.values.fold(
      0,
      (sum, count) => sum + count,
    );

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _exportReport,
                    icon: const Icon(Icons.download),
                    label: const Text('Export Report'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Summary Cards
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Total Hours',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${totalHours.toStringAsFixed(1)}h',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Total Sightings',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              '$totalSightings',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Active Volunteers',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${_userHours.values.where((h) => h > 0).length}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // User List
        Expanded(
          child:
              _users.isEmpty
                  ? const Center(child: Text('No users found'))
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final hours = _userHours[user.id] ?? 0.0;
                      final sightingsCount = _userSightings[user.id] ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(user.display_username[0].toUpperCase()),
                          ),
                          title: Text(user.display_username),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${hours.toStringAsFixed(1)} volunteer hours',
                              ),
                              Text('$sightingsCount sightings'),
                            ],
                          ),
                          trailing:
                              hours > 0
                                  ? IconButton(
                                    onPressed: () => _resetUserHours(user),
                                    icon: const Icon(
                                      Icons.refresh,
                                      color: Colors.orange,
                                    ),
                                    tooltip: 'Reset Hours',
                                  )
                                  : null,
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
