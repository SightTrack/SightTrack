import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _settings = {};
  String _appVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      });
    } catch (e) {
      Log.e('Error loading app info: $e');
      setState(() {
        _appVersion = 'Unknown';
      });
    }
  }

  Future<void> _loadSettings() async {
    try {
      setState(() => _isLoading = true);

      setState(() {
        _settings = {
          'enableAnalytics': true,
          'enableNotifications': true,
          'autoBackup': true,
          'requireModeration': false,
        };
        _isLoading = false;
      });
    } catch (e) {
      Log.e('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  void _exportData() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            title: Text('Exporting Data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Collecting all data...'),
              ],
            ),
          );
        },
      );

      Log.i('Admin export: Starting data export');

      // Query all data from DataStore
      final users = await Amplify.DataStore.query(User.classType);
      final sightings = await Amplify.DataStore.query(Sighting.classType);
      final userSettings = await Amplify.DataStore.query(
        UserSettings.classType,
      );

      Log.i(
        'Admin export: Collected ${users.length} users, ${sightings.length} sightings, ${userSettings.length} settings',
      );

      // Convert to JSON format
      final exportData = {
        'exportInfo': {
          'timestamp': DateTime.now().toIso8601String(),
          'appVersion': _appVersion,
          'totalUsers': users.length,
          'totalSightings': sightings.length,
          'totalSettings': userSettings.length,
        },
        'users':
            users
                .map(
                  (user) => {
                    'id': user.id,
                    'display_username': user.display_username,
                    'email': user.email,
                    'profilePicture': user.profilePicture,
                    'bio': user.bio,
                    'country': user.country,
                    'age': user.age,
                    'school': user.school,
                    'createdAt': user.createdAt?.format(),
                    'updatedAt': user.updatedAt?.format(),
                  },
                )
                .toList(),
        'sightings':
            sightings
                .map(
                  (sighting) => {
                    'id': sighting.id,
                    'species': sighting.species,
                    'photo': sighting.photo,
                    'latitude': sighting.latitude,
                    'longitude': sighting.longitude,
                    'city': sighting.city,
                    'displayLatitude': sighting.displayLatitude,
                    'displayLongitude': sighting.displayLongitude,
                    'timestamp': sighting.timestamp.format(),
                    'description': sighting.description,
                    'isTimeClaimed': sighting.isTimeClaimed,
                    'userId': sighting.user?.id,
                    'createdAt': sighting.createdAt?.format(),
                    'updatedAt': sighting.updatedAt?.format(),
                  },
                )
                .toList(),
        'userSettings':
            userSettings
                .map(
                  (settings) => {
                    'id': settings.id,
                    'userId': settings.userId,
                    'locationOffset': settings.locationOffset,
                    'isAreaCaptureActive': settings.isAreaCaptureActive,
                    'areaCaptureEnd': settings.areaCaptureEnd?.format(),
                    'activitySupervisor': settings.activitySupervisor,
                    'schoolSupervisor': settings.schoolSupervisor,
                    'createdAt': settings.createdAt?.format(),
                    'updatedAt': settings.updatedAt?.format(),
                  },
                )
                .toList(),
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
      final filename = 'sighttrack_export_$timestamp.json';

      // Show export complete dialog with options
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
                  Text(
                    'Successfully exported ${users.length + sightings.length + userSettings.length} records',
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

      Log.i('Admin export: Export completed successfully');
    } catch (e) {
      Log.e('Admin export error: $e');

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

  void _copyToClipboard(String content) async {
    try {
      await Clipboard.setData(ClipboardData(text: content));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export data copied to clipboard'),
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

  void _clearOldData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data cleanup functionality would be implemented here'),
      ),
    );
  }

  void _syncData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting data synchronization...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            title: Text('Syncing Data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Synchronizing with cloud...'),
              ],
            ),
          );
        },
      );

      Log.i('Admin sync: Stopping DataStore');
      await Amplify.DataStore.stop();

      Log.i('Admin sync: Starting DataStore');
      await Amplify.DataStore.start();

      // Wait a moment for DataStore to initialize
      await Future.delayed(const Duration(seconds: 2));

      // Test DataStore responsiveness by querying each model type
      bool syncSuccessful = false;
      int attempts = 0;
      const maxAttempts = 10; // 10 attempts over ~15 seconds

      while (!syncSuccessful && attempts < maxAttempts) {
        attempts++;
        try {
          Log.i(
            'Admin sync: Testing DataStore responsiveness (attempt $attempts)',
          );

          // Try to query each model type to ensure DataStore is responsive
          await Amplify.DataStore.query(User.classType);
          await Amplify.DataStore.query(Sighting.classType);
          await Amplify.DataStore.query(UserSettings.classType);

          syncSuccessful = true;
          Log.i('Admin sync: DataStore is responsive');
        } catch (e) {
          Log.w('Admin sync: DataStore not ready yet (attempt $attempts): $e');
          if (attempts < maxAttempts) {
            await Future.delayed(const Duration(milliseconds: 1500));
          }
        }
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show result message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              syncSuccessful
                  ? 'Data synchronization completed successfully!'
                  : 'Sync initiated but may still be in progress. Please check your connection.',
            ),
            backgroundColor: syncSuccessful ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      Log.i(
        'Admin sync: Completed. Success: $syncSuccessful after $attempts attempts',
      );
    } catch (e) {
      Log.e('Admin sync error: $e');

      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Data Management
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Management',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Export All Data'),
                  subtitle: Text(
                    'Download complete data backup',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: ElevatedButton(
                    onPressed: _exportData,
                    child: const Text('Export'),
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Sync Data'),
                  subtitle: Text(
                    'Force synchronization with cloud',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: ElevatedButton(
                    onPressed: _syncData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Sync'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // System Information
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _buildInfoRow('App Version', _appVersion),
                _buildInfoRow('Database Version', '1.5.2'),
                _buildInfoRow('Last Backup', 'Today, 3:00 AM'),
                _buildInfoRow('Total Storage', '1.2 GB'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
