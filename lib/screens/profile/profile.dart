import 'dart:async';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:flutter/material.dart';
import 'package:sighttrack/logging.dart';
import 'package:sighttrack/models/User.dart';
import 'package:sighttrack/models/UserSettings.dart';
import 'package:sighttrack/util.dart';
import 'package:sighttrack/widgets/button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();

  static Future<String> loadProfilePicture(String path) async {
    try {
      final result =
          await Amplify.Storage.getUrl(
            path: StoragePath.fromString(path),
            options: const StorageGetUrlOptions(
              pluginOptions: S3GetUrlPluginOptions(
                validateObjectExistence: true,
                expiresIn: Duration(hours: 2),
              ),
            ),
          ).result;
      return result.url.toString();
    } catch (e) {
      Log.e('Error loading profile picture: $e');
      rethrow;
    }
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? userDatastore;
  String? cognitoUsername;
  bool isLoading = true;
  late StreamSubscription subscription;
  Future<String?>? _profilePictureFuture;
  UserSettings? _userSettings;
  bool _isAreaCaptureActive = false;

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
          userDatastore = users.first;
          if (userDatastore!.profilePicture != null &&
              userDatastore!.profilePicture!.isNotEmpty) {
            _profilePictureFuture = ProfileScreen.loadProfilePicture(
              userDatastore!.profilePicture!,
            );
          }
        }
        isLoading = false;
        cognitoUsername = currentUser.username;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Log.e('Error fetching user: $e');
    }
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

  @override
  void initState() {
    super.initState();
    _initializeWrapper();

    fetchCurrentUser();
    subscription = Amplify.DataStore.observe(User.classType).listen((event) {
      if (userDatastore != null && event.item.id == userDatastore!.id) {
        fetchCurrentUser();
      }
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 26, color: Colors.grey),
            padding: const EdgeInsets.all(12),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              )
              : userDatastore == null
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
                  SightTrackButton(
                    text: 'Logout',
                    width: 140,
                    onPressed: () => Amplify.Auth.signOut(),
                  ),
                ],
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28.0,
                  vertical: 40.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
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
                                      child: Center(
                                        child: CircularProgressIndicator(
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
                    const SizedBox(height: 28),
                    Text(
                      cognitoUsername ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userDatastore!.display_username,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FutureBuilder<bool>(
                          future: Util.isAdmin(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.grey,
                                  ),
                                ),
                              );
                            }
                            if (snapshot.hasData && snapshot.data == true) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Admin User',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        if (_isAreaCaptureActive)
                          Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Area Capture Active',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.email, size: 22, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          userDatastore!.email,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.pin_drop,
                          size: 22,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          userDatastore!.country!.isNotEmpty
                              ? userDatastore!.country!
                              : 'Location not set',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        userDatastore!.bio!.isNotEmpty
                            ? userDatastore!.bio!
                            : 'No bio',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 48),
                    SightTrackButton(
                      text: 'Logout',
                      width: 140,
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
                              content: const Text(
                                'Are you sure you want to log out?',
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
                  ],
                ),
              ),
    );
  }
}
