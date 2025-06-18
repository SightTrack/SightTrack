import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  bool _isLoading = true;
  List<User> _users = [];
  List<User> _filteredUsers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);
      final users = await Amplify.DataStore.query(User.classType);
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      Log.e('Error loading users: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers =
            _users.where((user) {
              return user.display_username.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  (user.email.toLowerCase().contains(query.toLowerCase()) ??
                      false) ||
                  (user.country?.toLowerCase().contains(query.toLowerCase()) ??
                      false);
            }).toList();
      }
    });
  }

  Future<void> _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete User'),
            content: Text(
              'Are you sure you want to delete ${user.display_username}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await Amplify.DataStore.delete(user);
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.display_username} deleted')),
          );
        }
      } catch (e) {
        Log.e('Error deleting user: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Error deleting user')));
        }
      }
    }
  }

  void _showUserDetails(User user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(user.display_username),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${user.email ?? 'Not provided'}'),
                Text('Country: ${user.country ?? 'Not provided'}'),
                Text('Bio: ${user.bio ?? 'No bio'}'),
                Text('Created: ${user.createdAt?.format() ?? 'Unknown'}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          // color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'User Management',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text('${_filteredUsers.length} users'),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _filterUsers,
              ),
            ],
          ),
        ),

        // User List
        Expanded(
          child:
              _filteredUsers.isEmpty
                  ? const Center(child: Text('No users found'))
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(user.display_username[0].toUpperCase()),
                          ),
                          title: Text(user.display_username),
                          subtitle: Text(user.email ?? 'No email'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'view':
                                  _showUserDetails(user);
                                  break;
                                case 'delete':
                                  _deleteUser(user);
                                  break;
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Text('View Details'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete User'),
                                  ),
                                ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
