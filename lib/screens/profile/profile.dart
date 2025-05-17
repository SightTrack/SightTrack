import 'package:sighttrack/barrel.dart';

import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserSettings? _userSettings;
  User? userDatastore;
  String? cognitoUsername;
  late StreamSubscription subscription;
  Future<String?>? _profilePictureFuture;
  bool isLoading = true;
  bool _isAreaCaptureActive = false;

  Future<int>? getTotalSightingNumber() async {
    try {
      final sightings = await Amplify.DataStore.query(
        Sighting.classType,
        where: Sighting.USER.eq(userDatastore!.id),
      );
      return sightings.length;
    } catch (e) {
      Log.e('FETCH ERROR for total sightings: $e');
      return 0;
    }
  }

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
            _profilePictureFuture = Util.fetchFromS3(
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
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 26, color: Colors.grey),
            padding: const EdgeInsets.all(12),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      backgroundColor: Colors.grey[900],
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
                        color: Colors.white,
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
                                    Colors.white,
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
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Admin User',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.redAccent,
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
                            color: Colors.white,
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
                            color: Colors.white,
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
                          color: Colors.white,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 48),
                    FutureBuilder<int>(
                      future: getTotalSightingNumber(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          );
                        }
                        if (snapshot.hasData) {
                          return Text(
                            'Has ${snapshot.data} Sightings',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 40),
                    BlackButton(
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
                              content: const Text(
                                'Are you sure you want to log out?',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color.fromARGB(255, 96, 95, 95),
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
