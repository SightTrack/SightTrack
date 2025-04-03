import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:sighttrack/models/User.dart';
import 'package:sighttrack/models/UserSettings.dart';
import 'package:sighttrack/screens/profile/profile.dart';
import 'package:sighttrack/screens/profile/profile_picture.dart';
import 'package:sighttrack/widgets/button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? user;
  bool isLoading = true;

  Future<void> fetchCurrentUser() async {
    try {
      final currentUser = await Amplify.Auth.getCurrentUser();
      final userId = currentUser.userId;

      final users = await Amplify.DataStore.query(
        User.classType,
        where: User.ID.eq(userId),
      );

      setState(() {
        if (users.isNotEmpty) {
          user = users.first;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToEditPage(String field, String? currentValue) {
    if (user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditFieldPage(
              field: field,
              currentValue: currentValue,
              user: user!,
            ),
      ),
    ).then((_) => fetchCurrentUser());
  }

  void _navigateToChangeProfilePicture() {
    if (user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeProfilePictureScreen(user: user!),
      ),
    ).then((_) => fetchCurrentUser());
  }

  @override
  void initState() {
    super.initState();
    fetchCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: Colors.grey[100],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : user == null
              ? const Center(child: Text('No profile found'))
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionTitle('Profile'),
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Settings'),
                  _buildSettingsCard(),
                ],
              ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildProfileItem(
            title: 'Profile Picture',
            leading: _buildProfilePicture(),
            onTap: _navigateToChangeProfilePicture,
          ),
          _buildDivider(),
          _buildProfileItem(
            title: 'Username',
            subtitle: user!.display_username,
            onTap:
                () => _navigateToEditPage('Username', user!.display_username),
          ),
          _buildDivider(),
          _buildProfileItem(
            title: 'Email',
            subtitle: user!.email,
            onTap: () => _navigateToEditPage('Email', user!.email),
          ),
          _buildDivider(),
          _buildProfileItem(
            title: 'Country',
            subtitle: user!.country ?? 'Not set',
            onTap: () => _navigateToEditPage('Country', user!.country),
          ),
          _buildDivider(),
          _buildProfileItem(
            title: 'Bio',
            subtitle: user!.bio ?? 'Not set',
            onTap: () => _navigateToEditPage('Bio', user!.bio),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildProfileItem(
            title: 'Privacy',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacySettingsPage(),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required String title,
    String? subtitle,
    Widget? leading,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle:
          subtitle != null
              ? Text(
                subtitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
              : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildProfilePicture() {
    return (user!.profilePicture != null && user!.profilePicture!.isNotEmpty)
        ? FutureBuilder<String?>(
          future: ProfileScreen.loadProfilePicture(user!.profilePicture!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            return CircleAvatar(
              radius: 20,
              backgroundImage:
                  snapshot.hasData ? NetworkImage(snapshot.data!) : null,
              backgroundColor: Colors.grey[300],
              child:
                  snapshot.hasError || !snapshot.hasData
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
            );
          },
        )
        : CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[300],
          child: const Icon(Icons.person, color: Colors.white),
        );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.grey[200],
    );
  }
}

class EditFieldPage extends StatefulWidget {
  final String field;
  final String? currentValue;
  final User user;

  const EditFieldPage({
    super.key,
    required this.field,
    this.currentValue,
    required this.user,
  });

  @override
  State<EditFieldPage> createState() => _EditFieldPageState();
}

class _EditFieldPageState extends State<EditFieldPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _controller;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveField() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isSaving = true);
      try {
        final newValue = _controller.text.trim();
        User updatedUser;
        switch (widget.field) {
          case 'Username':
            updatedUser = widget.user.copyWith(display_username: newValue);
            break;
          case 'Email':
            updatedUser = widget.user.copyWith(email: newValue);
            break;
          case 'Country':
            updatedUser = widget.user.copyWith(country: newValue);
            break;
          case 'Bio':
            updatedUser = widget.user.copyWith(bio: newValue);
            break;
          default:
            updatedUser = widget.user;
        }
        await Amplify.DataStore.save(updatedUser);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Updated')));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Edit ${widget.field}'),
        elevation: 0,
        backgroundColor: Colors.grey[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _controller,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: widget.field,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (widget.field == 'Username' || widget.field == 'Email') {
                    if (value == null || value.trim().isEmpty) {
                      return '${widget.field} cannot be empty';
                    }
                  }
                  if (widget.field == 'Email' &&
                      value != null &&
                      value.trim().isNotEmpty &&
                      !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SightTrackButton(
                text: 'Save',
                onPressed: isSaving ? null : _saveField,
                loading: isSaving,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool? _locationOffset;
  User? _currentUser;
  UserSettings? _userSettings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final currentUser = await Amplify.Auth.getCurrentUser();
      final userId = currentUser.userId;

      final users = await Amplify.DataStore.query(
        User.classType,
        where: User.ID.eq(userId),
      );

      if (users.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final user = users.first;
      final settings = await Amplify.DataStore.query(
        UserSettings.classType,
        where: UserSettings.USERID.eq(userId),
      );

      setState(() {
        _currentUser = user;
        _userSettings = settings.isNotEmpty ? settings.first : null;
        _locationOffset =
            _userSettings?.locationOffset ?? false; // Default to false if null
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
    }
  }

  Future<void> _updateLocationOffset(bool value) async {
    if (_currentUser == null) return;

    try {
      UserSettings updatedSettings;
      if (_userSettings == null) {
        // Create new settings if none exists
        updatedSettings = UserSettings(
          userId: _currentUser!.id,
          locationOffset: value,
        );
        await Amplify.DataStore.save(updatedSettings);
        // Link to User
        final updatedUser = _currentUser!.copyWith(settings: updatedSettings);
        await Amplify.DataStore.save(updatedUser);
      } else {
        // Update existing settings
        updatedSettings = _userSettings!.copyWith(locationOffset: value);
        await Amplify.DataStore.save(updatedSettings);
      }

      setState(() {
        _locationOffset = value;
        _userSettings = updatedSettings;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating setting: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Privacy'),
        elevation: 0,
        backgroundColor: Colors.grey[100],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionTitle('Location'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      title: const Text(
                        'Location Offset',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Enable to offset your location data for better privacy',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      value: _locationOffset ?? false,
                      onChanged: (value) => _updateLocationOffset(value),
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
