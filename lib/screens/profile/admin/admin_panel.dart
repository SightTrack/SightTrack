import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';
import 'package:sighttrack/screens/profile/admin/admin_dashboard.dart';
import 'package:sighttrack/screens/profile/admin/user_management.dart';
import 'package:sighttrack/screens/profile/admin/sighting_moderation.dart';
import 'package:sighttrack/screens/profile/admin/volunteer_hours_management.dart';
import 'package:sighttrack/screens/profile/admin/analytics_screen.dart';
import 'package:sighttrack/screens/profile/admin/admin_settings.dart';
import 'package:sighttrack/screens/profile/admin/manage_reports.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isAdmin = false;

  final List<AdminNavItem> _navItems = [
    AdminNavItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
      screen: const AdminDashboard(),
    ),
    AdminNavItem(
      icon: Icons.people,
      label: 'Users',
      screen: const UserManagementScreen(),
    ),
    AdminNavItem(
      icon: Icons.camera_alt,
      label: 'Sightings',
      screen: const SightingModerationScreen(),
    ),
    AdminNavItem(
      icon: Icons.report_problem,
      label: 'Reports',
      screen: const ManageReportsScreen(),
    ),
    AdminNavItem(
      icon: Icons.access_time,
      label: 'Volunteer Hours',
      screen: const VolunteerHoursManagementScreen(),
    ),
    AdminNavItem(
      icon: Icons.analytics,
      label: 'Analytics',
      screen: const AnalyticsScreen(),
    ),
    AdminNavItem(
      icon: Icons.settings,
      label: 'Settings',
      screen: const AdminSettingsScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await Util.isAdmin();
      setState(() {
        _isAdmin = isAdmin;
        _isLoading = false;
      });

      if (!isAdmin) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access denied. Admin privileges required.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Log.e('Error checking admin status: $e');
      setState(() {
        _isLoading = false;
        _isAdmin = false;
      });
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAdmin) {
      return const Scaffold(body: Center(child: Text('Access Denied')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Admin Panel - ${_navItems[_selectedIndex].label}',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Row(
        children: [
          // Navigation Rail
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            extended: MediaQuery.of(context).size.width > 1000,
            selectedIconTheme: const IconThemeData(color: Colors.red),
            selectedLabelTextStyle: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
            destinations:
                _navItems
                    .map(
                      (item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        label: Text(
                          item.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
          ),

          // Vertical Divider
          // const VerticalDivider(thickness: 1, width: 1),

          // Main Content
          Expanded(child: _navItems[_selectedIndex].screen),
        ],
      ),
    );
  }
}

class AdminNavItem {
  final IconData icon;
  final String label;
  final Widget screen;

  AdminNavItem({required this.icon, required this.label, required this.screen});
}
