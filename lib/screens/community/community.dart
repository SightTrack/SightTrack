import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  List<User> _globalUsers = [];
  List<User> _schoolUsers = [];
  List<User> _filteredGlobalUsers = [];
  List<User> _filteredSchoolUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;
  StreamSubscription? _userSubscription;
  OverlayEntry? _overlayEntry; // For the enlarged user preview

  // Search controllers
  final TextEditingController _globalSearchController = TextEditingController();
  final TextEditingController _schoolSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
    _setupRealTimeUpdates();

    // Listen to tab changes to rebuild search bar
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _removeEnlargedPreview(); // Ensure overlay is removed when screen is disposed
    _userSubscription?.cancel();
    _tabController.dispose();
    _globalSearchController.dispose();
    _schoolSearchController.dispose();
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
      builder: (context) {
        return Center(
          child: Material(
            child: Container(
              width: 260,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  // Close button
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 24),
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

  void _filterGlobalUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredGlobalUsers = List.from(_globalUsers);
      } else {
        _filteredGlobalUsers =
            _globalUsers.where((user) {
              return user.display_username.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  user.email.toLowerCase().contains(query.toLowerCase());
            }).toList();
      }
    });
  }

  void _filterSchoolUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSchoolUsers = List.from(_schoolUsers);
      } else {
        _filteredSchoolUsers =
            _schoolUsers.where((user) {
              return user.display_username.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  user.email.toLowerCase().contains(query.toLowerCase());
            }).toList();
      }
    });
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

        // Initialize filtered lists
        _filteredGlobalUsers = List.from(_globalUsers);
        _filteredSchoolUsers = List.from(_schoolUsers);

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
                  _buildUserListWithSliver(
                    _filteredGlobalUsers,
                    isGlobal: true,
                  ),
                  _buildUserListWithSliver(
                    _filteredSchoolUsers,
                    isGlobal: false,
                  ),
                ],
              ),
    );
  }

  Widget _buildUserListWithSliver(List<User> users, {required bool isGlobal}) {
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchData();
        _globalSearchController.clear();
        _schoolSearchController.clear();
      },
      child: CustomScrollView(
        slivers: [
          // Search bar as floating sliver
          SliverAppBar(
            automaticallyImplyLeading: false,
            floating: true,
            snap: true,
            elevation: 0,
            toolbarHeight: 80,
            flexibleSpace: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(),
              child: Center(
                child:
                    isGlobal
                        ? STSearchBar(
                          hintText: 'Search by name or email',
                          onSearchChanged: _filterGlobalUsers,
                          controller: _globalSearchController,
                          padding: EdgeInsets.zero,
                        )
                        : STSearchBar(
                          hintText: 'Search by name or email',
                          onSearchChanged: _filterSchoolUsers,
                          controller: _schoolSearchController,
                          padding: EdgeInsets.zero,
                        ),
              ),
            ),
          ),
          // User list content
          _buildUserListSliver(users, isGlobal: isGlobal),
        ],
      ),
    );
  }

  Widget _buildUserListSliver(List<User> users, {required bool isGlobal}) {
    if (users.isEmpty) {
      // Check if it's due to search or no users
      final hasSearch =
          isGlobal
              ? _globalSearchController.text.isNotEmpty
              : _schoolSearchController.text.isNotEmpty;

      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasSearch ? Icons.search_off : Icons.people_outline,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                hasSearch
                    ? 'No users found matching your search'
                    : isGlobal
                    ? 'No global users found'
                    : 'No users found from your school',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              if (hasSearch) ...[
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search terms',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final user = users[index];
          return FadeTransition(
            opacity: CurvedAnimation(
              parent:
                  ModalRoute.of(context)?.animation ??
                  AlwaysStoppedAnimation(1),
              curve: Curves.easeIn,
            ),
            child: GestureDetector(
              onLongPressStart: (details) {
                _showEnlargedPreview(context, user, details.globalPosition);
              },
              onTap: () {
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
                ),
              ),
            ),
          );
        }, childCount: users.length),
      ),
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
