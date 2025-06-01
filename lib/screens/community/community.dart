import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';
import 'package:sighttrack/screens/community/user_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  List<User> _globalUsers = [];
  List<User> _schoolUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;
  StreamSubscription? _userSubscription;
  OverlayEntry? _overlayEntry; // For the enlarged user preview

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
    _setupRealTimeUpdates();
  }

  @override
  void dispose() {
    _removeEnlargedPreview(); // Ensure overlay is removed when screen is disposed
    _userSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _removeEnlargedPreview() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showEnlargedPreview(
    BuildContext context,
    User user,
    Offset tapPosition,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // No background
      builder: (context) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: 260,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.grey[900]?.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(blurRadius: 24, offset: const Offset(0, 8)),
                ],
              ),
              child: Stack(
                children: [
                  // Close button
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 24,
                      ),
                      splashRadius: 20,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  // Avatar centered
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 8,
                      ), // For spacing below close button
                      _buildLargeProfilePicture(user),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLargeProfilePicture(User user) {
    return (user.profilePicture != null && user.profilePicture!.isNotEmpty)
        ? FutureBuilder<String?>(
          future: Util.fetchFromS3(user.profilePicture!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF39FF14),
                ),
              );
            }
            return CircleAvatar(
              radius: 90,
              backgroundImage:
                  snapshot.hasData ? NetworkImage(snapshot.data!) : null,
              backgroundColor: Colors.grey[700],
              child:
                  snapshot.hasError || !snapshot.hasData
                      ? const Icon(Icons.person, color: Colors.white, size: 90)
                      : null,
            );
          },
        )
        : CircleAvatar(
          radius: 90,
          backgroundColor: Colors.grey[700],
          child: const Icon(Icons.person, color: Colors.white, size: 90),
        );
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch current user
      final cognitoUser = await Amplify.Auth.getCurrentUser();
      final users = await Amplify.DataStore.query(
        User.classType,
        where: User.ID.eq(cognitoUser.userId),
      );
      if (users.isEmpty) {
        throw Exception('Current user not found');
      }
      final currentUser = users.first;

      // Fetch all users
      final allUsers = await Amplify.DataStore.query(User.classType);

      setState(() {
        _globalUsers = allUsers;
        _schoolUsers =
            allUsers
                .where(
                  (user) =>
                      currentUser.school != null &&
                      user.school != null &&
                      user.school == currentUser.school &&
                      user.id != currentUser.id,
                )
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching users: $e';
        _isLoading = false;
      });
      Log.e('Error in CommunityScreen: $e');
    }
  }

  void _setupRealTimeUpdates() {
    _userSubscription = Amplify.DataStore.observe(User.classType).listen((
      event,
    ) {
      _fetchData(); // Refresh data on any User model change
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Community',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Global'), Tab(text: 'School')],
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              )
              : _errorMessage != null
              ? Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildUserList(_globalUsers, isGlobal: true),
                  _buildUserList(_schoolUsers, isGlobal: false),
                ],
              ),
    );
  }

  Widget _buildUserList(List<User> users, {required bool isGlobal}) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          isGlobal
              ? 'No global users found'
              : 'No users found from your school',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return FadeTransition(
          opacity: CurvedAnimation(
            parent:
                ModalRoute.of(context)?.animation ?? AlwaysStoppedAnimation(1),
            curve: Curves.easeIn,
          ),
          child: GestureDetector(
            onLongPressStart: (details) {
              _showEnlargedPreview(context, user, details.globalPosition);
            },
            onTap: () {
              // Keep the original onTap for navigation
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                          UserDetailScreen(user: user),
                  transitionDuration: const Duration(milliseconds: 300),
                  transitionsBuilder: (
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ) {
                    var begin = const Offset(1.0, 0.0);
                    var end = Offset.zero;
                    var curve = Curves.ease;
                    var tween = Tween(
                      begin: begin,
                      end: end,
                    ).chain(CurveTween(curve: curve));
                    var slideInAnimation = animation.drive(tween);

                    var slideOutTween = Tween(
                      begin: Offset.zero,
                      end: const Offset(-0.3, 0.0),
                    ).chain(CurveTween(curve: curve));
                    var slideOutAnimation = secondaryAnimation.drive(
                      slideOutTween,
                    );

                    return SlideTransition(
                      position: slideOutAnimation,
                      child: SlideTransition(
                        position: slideInAnimation,
                        child: child,
                      ),
                    );
                  },
                ),
              );
            },
            child: Card(
              // color: Colors.grey[850],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: _buildProfilePicture(user),
                title: Text(user.display_username),
                subtitle: Text(
                  isGlobal ? (user.school ?? 'No school') : (user.email),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserDetailScreen(user: user),
                    ),
                  );
                },
                // onTap is now part of the GestureDetector above
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfilePicture(User user) {
    return (user.profilePicture != null && user.profilePicture!.isNotEmpty)
        ? FutureBuilder<String?>(
          future: Util.fetchFromS3(user.profilePicture!),
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
              backgroundColor: Colors.grey[700],
              child:
                  snapshot.hasError || !snapshot.hasData
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : null,
            );
          },
        )
        : CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[700],
          child: const Icon(Icons.person, color: Colors.white, size: 20),
        );
  }
}
