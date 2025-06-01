import 'package:sighttrack/barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      Log.e('Error fetching user: $e');
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
      // backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        elevation: 0,
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
                  const SizedBox(height: 24),
                  ModernDarkButton(
                    text: 'Delete Account',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: const Text(
                              'Delete Account',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: const Text(
                              'Are you sure you want to delete your account?',
                              style: TextStyle(fontSize: 16),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await Amplify.DataStore.delete(user!);
                                  await Amplify.Auth.deleteUser();
                                  await Amplify.Auth.signOut();
                                },
                                child: const Text(
                                  'Delete (permanent)',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 5),
      child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // color: Colors.grey[850],
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
            title: 'Age',
            subtitle: user!.age != null ? '${user!.age}' : 'Not set',
            onTap: () => _navigateToEditPage('Age', user!.age?.toString()),
          ),
          _buildDivider(),
          _buildProfileItem(
            title: 'School',
            subtitle: user!.school ?? 'Not set',
            onTap: () => _navigateToEditPage('School', user!.school),
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
          _buildDivider(),
          Consumer<ThemeProvider>(
            builder:
                (context, themeProvider, _) => ListTile(
                  title: Text(
                    'Dark Mode',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  trailing: Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (_) => themeProvider.toggleTheme(),
                      activeColor: Theme.of(context).colorScheme.primary,
                      inactiveTrackColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle:
          subtitle != null
              ? Text(
                subtitle,
                style: Theme.of(context).textTheme.labelMedium,
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
          future: Util.fetchFromS3(user!.profilePicture!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              );
            }
            return CircleAvatar(
              radius: 20,
              backgroundImage:
                  snapshot.hasData ? NetworkImage(snapshot.data!) : null,
              backgroundColor: Colors.grey[700],
              child:
                  snapshot.hasError || !snapshot.hasData
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
            );
          },
        )
        : CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[700],
          child: const Icon(Icons.person, color: Colors.white),
        );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.grey[700],
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
  late FToast fToast;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue ?? '');
    fToast = FToast();
    fToast.init(context);
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
          case 'Age':
            final age = int.tryParse(newValue);
            if (age == null) {
              throw Exception('Invalid age format');
            }
            updatedUser = widget.user.copyWith(age: age);
            break;
          case 'School':
            updatedUser = widget.user.copyWith(school: newValue);
            break;
          default:
            updatedUser = widget.user;
        }
        await Amplify.DataStore.save(updatedUser);
        if (mounted) {
          fToast.showToast(
            child: Util.greenToast('Updated'),
            gravity: ToastGravity.BOTTOM,
            toastDuration: Duration(seconds: 2),
          );
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
      appBar: AppBar(
        title: Text(
          'Edit ${widget.field}',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        elevation: 0,
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
                  labelText: widget.field,
                  // border: OutlineInputBorder(
                  //   borderRadius: BorderRadius.circular(12),
                  //   borderSide: BorderSide.none,
                  // ),
                  // enabledBorder: OutlineInputBorder(
                  //   borderRadius: BorderRadius.circular(12),
                  //   borderSide: BorderSide.none,
                  // ),
                ),
                keyboardType:
                    widget.field == 'Age'
                        ? TextInputType.number
                        : TextInputType.text,
                inputFormatters:
                    widget.field == 'Age'
                        ? [FilteringTextInputFormatter.digitsOnly]
                        : null,
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
                  if (widget.field == 'Age') {
                    if (value == null || value.trim().isEmpty) {
                      return 'Age cannot be empty';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age < 1 || age > 120) {
                      return 'Enter a valid age (1-120)';
                    }
                  }
                  if (widget.field == 'School' &&
                      (value != null && value.trim().isEmpty)) {
                    return 'Enter a valid school';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ModernDarkButton(text: 'Save', onPressed: _saveField),
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
        _locationOffset = _userSettings?.locationOffset ?? false;
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
        updatedSettings = UserSettings(
          userId: _currentUser!.id,
          locationOffset: value,
        );
        await Amplify.DataStore.save(updatedSettings);
        final updatedUser = _currentUser!.copyWith(settings: updatedSettings);
        await Amplify.DataStore.save(updatedUser);
      } else {
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
      appBar: AppBar(
        title: Text(
          'Privacy',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionTitle('Location'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    // color: Colors.grey[850],
                    child: ListTile(
                      title: Text(
                        'Location Offset',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        'Enable to offset your location data for better privacy',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      trailing: Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: _locationOffset ?? false,
                          onChanged: (value) => _updateLocationOffset(value),
                          activeColor: Theme.of(context).colorScheme.primary,
                          inactiveTrackColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
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
      padding: const EdgeInsets.only(bottom: 8, left: 5),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
