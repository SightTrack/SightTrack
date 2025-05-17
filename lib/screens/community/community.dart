import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';
import 'package:sighttrack/screens/community/view_user.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
    _setupRealTimeUpdates();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
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
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        title: const Text(
          'Community',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF39FF14),
          labelColor: const Color(0xFF39FF14),
          unselectedLabelColor: Colors.grey[400],
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [Tab(text: 'Global'), Tab(text: 'School')],
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF39FF14)),
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
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
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
          child: Card(
            color: Colors.grey[850],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: _buildProfilePicture(user),
              title: Text(
                user.display_username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                isGlobal ? (user.school ?? 'No school') : (user.email),
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewUserScreen(user: user),
                  ),
                );
              },
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF39FF14),
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
