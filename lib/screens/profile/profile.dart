import 'package:sighttrack/barrel.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:sighttrack/screens/profile/admin_panel.dart';
import 'dart:ui';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserSettings? _userSettings;
  User? _user;
  String? _cognitoUsername;
  late StreamSubscription _subscription;
  Future<String?>? _profilePictureFuture;
  bool _isLoading = true;
  bool _isAreaCaptureActive = false;

  Future<int>? getTotalSightingNumber() async {
    try {
      final sightings = await Amplify.DataStore.query(
        Sighting.classType,
        where: Sighting.USER.eq(_user!.id),
      );
      return sightings.length;
    } catch (e) {
      Log.e('FETCH ERROR for total sightings: $e');
      return 0;
    }
  }

  Future<void> fetchCurrentUser() async {
    final user = await Util.getUserModel();
    final cognitoUsername = await Util.getCognitoUsername();
    setState(() {
      _user = user;
      _isLoading = false;
      _cognitoUsername = cognitoUsername;

      if (_user!.profilePicture != null && _user!.profilePicture!.isNotEmpty) {
        _profilePictureFuture = Util.fetchFromS3(_user!.profilePicture!);
      }
    });
  }

  Future<void> _initializeWrapper() async {
    final fetchSettings = await Util.getUserSettings();
    setState(() {
      _userSettings = fetchSettings;
      _isAreaCaptureActive = fetchSettings?.isAreaCaptureActive ?? false;
    });
    Amplify.DataStore.observe(UserSettings.classType).listen((event) {
      if (mounted) {
        setState(() {
          _userSettings = event.item;
          _isAreaCaptureActive = _userSettings?.isAreaCaptureActive ?? false;
        });
      }
    });
  }

  void _onVolunteerHoursTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VolunteerHoursScreen()),
    );
  }

  Future<void> _showAdminPanelDialog() async {
    if (context.mounted) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Admin Panel',
        barrierColor: Colors.black.withOpacity(0.3),
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, anim1, anim2) {
          return const SizedBox.shrink();
        },
        transitionBuilder: (context, anim1, anim2, child) {
          return Transform(
            transform: Matrix4.translationValues(
              0.0,
              100 * (1 - anim1.value),
              0.0,
            ),
            child: Opacity(
              opacity: anim1.value,
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(color: Colors.black.withOpacity(0.2)),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: 48,
                        left: 24,
                        right: 24,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 32,
                              horizontal: 24,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.admin_panel_settings,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Admin Panel',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Access advanced admin features.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 28),
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const AdminPanelScreen(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.18),
                                              blurRadius: 16,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.arrow_upward_rounded,
                                            size: 40,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeWrapper();

    fetchCurrentUser();
    _subscription = Amplify.DataStore.observe(User.classType).listen((event) {
      if (_user != null && event.item.id == _user!.id) {
        fetchCurrentUser();
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // backgroundColor: Colors.grey[900],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 26),
            padding: const EdgeInsets.all(12),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      // backgroundColor: Colors.grey[900],
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              )
              : _user == null
              ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No profile found',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ModernDarkButton(
                    text: 'Logout',
                    width: 140,
                    onPressed: () => Amplify.Auth.signOut(),
                  ),
                ],
              )
              : SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Profile Picture & Edit
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey[800]!,
                                        Colors.grey[700]!,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.25,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child:
                                      _profilePictureFuture != null
                                          ? FutureBuilder<String?>(
                                            future: _profilePictureFuture,
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const SizedBox(
                                                  height: 120,
                                                  width: 120,
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 3,
                                                        ),
                                                  ),
                                                );
                                              } else if (snapshot.hasError ||
                                                  !snapshot.hasData) {
                                                return const CircleAvatar(
                                                  radius: 60,
                                                  backgroundColor: Colors.grey,
                                                  child: Icon(
                                                    Icons.person,
                                                    size: 48,
                                                    color: Colors.white,
                                                  ),
                                                );
                                              } else {
                                                return CircleAvatar(
                                                  radius: 60,
                                                  backgroundImage: NetworkImage(
                                                    snapshot.data!,
                                                  ),
                                                );
                                              }
                                            },
                                          )
                                          : const CircleAvatar(
                                            radius: 60,
                                            backgroundColor: Colors.grey,
                                            child: Icon(
                                              Icons.person,
                                              size: 48,
                                              color: Colors.white,
                                            ),
                                          ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 8,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    ChangeProfilePictureScreen(
                                                      user: _user!,
                                                    ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          size: 20,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            // Username & Display Name
                            Text(
                              _user!.display_username,
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _cognitoUsername ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Badges & Stats
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FutureBuilder<bool>(
                                  future: Util.isAdmin(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      );
                                    }
                                    if (snapshot.hasData &&
                                        snapshot.data == true) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          onTap: _showAdminPanelDialog,
                                          child: Chip(
                                            label: Row(
                                              children: const [
                                                Icon(
                                                  Icons.verified_user,
                                                  color: Colors.orange,
                                                  size: 18,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Admin User',
                                                  style: TextStyle(
                                                    color: Colors.orange,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                                if (_isAreaCaptureActive)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Chip(
                                      backgroundColor: Colors.grey[800]!
                                          .withValues(alpha: 0.99),
                                      label: Row(
                                        children: const [
                                          Icon(
                                            Icons.location_on,
                                            color: Colors.green,
                                            size: 18,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Area Capture Active',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                FutureBuilder<int>(
                                  future: getTotalSightingNumber(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      );
                                    }
                                    if (snapshot.hasData) {
                                      return Chip(
                                        label: Row(
                                          children: [
                                            const Icon(
                                              Icons.visibility,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Sightings: ${snapshot.data}',
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium,
                                            ),
                                          ],
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            // Info Rows
                            Card(
                              // color: Colors.grey[850],
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.email, size: 22),
                                    title: Text(
                                      _user!.email,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                    ),
                                  ),
                                  const Divider(height: 1, color: Colors.grey),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.pin_drop,
                                      size: 22,
                                    ),
                                    title: Text(
                                      _user!.country!.isNotEmpty
                                          ? _user!.country!
                                          : 'Location not set',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                    ),
                                  ),
                                  const Divider(height: 1, color: Colors.grey),
                                  ListTile(
                                    leading: Icon(Icons.location_on, size: 22),
                                    title: AutoSizeText(
                                      _user!.bio!.isNotEmpty
                                          ? _user!.bio!
                                          : 'Bio not set',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                      minFontSize: 6,
                                      maxFontSize: 16,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Divider(height: 1, color: Colors.grey),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.volunteer_activism,
                                      size: 22,
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward,
                                      size: 22,
                                    ),
                                    title: Text(
                                      'Volunteer Hours',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                    ),
                                    onTap: _onVolunteerHoursTap,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    // Logout Button at Bottom
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ModernDarkButton(
                          text: 'Logout',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  title: const Text(
                                    'Logout',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Text(
                                    'Are you sure you want to log out?',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                      child: Text(
                                        'Cancel',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.labelMedium,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Amplify.Auth.signOut();
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text(
                                        'Logout',
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
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
