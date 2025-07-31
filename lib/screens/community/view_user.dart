import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';
import 'package:sighttrack/screens/community/user_sightings_gallery.dart';

class UserDetailScreen extends StatefulWidget {
  final User user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  // Add refresh keys to force FutureBuilders to rebuild
  Key _profilePictureKey = UniqueKey();
  Key _sightingsKey = UniqueKey();

  // Lazy loading variables
  List<Sighting> _allSightings = [];
  List<Sighting> _displayedSightings = [];
  bool _isLoadingMore = false;
  static const int _itemsPerPage = 9; // Show 9 items (3x3 grid) per page
  int _currentPage = 0;

  // Scroll controller to maintain position
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _gridKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when user is 200 pixels from the bottom
      _loadMoreSightings();
    }
  }

  Widget _buildProfilePicture(BuildContext context) {
    final String? picUrl = widget.user.profilePicture;

    if (picUrl != null && picUrl.isNotEmpty) {
      // Check if it's a full URL or an S3 key (similar to EnlargedUserPreview)
      if (picUrl.startsWith('http')) {
        return CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(picUrl),
          backgroundColor: Colors.grey[700],
        );
      } else {
        // Assuming it's an S3 key and Util.fetchFromS3 is available
        return FutureBuilder<String?>(
          key: _profilePictureKey, // Add key for refresh
          future: Util.fetchFromS3(
            picUrl,
          ), // Ensure Util is imported and this method exists
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[700],
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF39FF14), // Accent color for loading
                ),
              );
            }
            if (snapshot.hasData && snapshot.data != null) {
              return CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(snapshot.data!),
                backgroundColor: Colors.grey[700],
              );
            } else {
              // Error or no data, show placeholder
              return CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[700],
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.white70,
                ),
              );
            }
          },
        );
      }
    } else {
      // No profile picture URL, show placeholder
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[700],
        child: const Icon(Icons.person, size: 50, color: Colors.white70),
      );
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    BuildContext? context,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context!).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(content, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSightingsSection(BuildContext context) {
    return FutureBuilder<List<Sighting>>(
      key: _sightingsKey, // Add key for refresh
      future: _getUserSightings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.visibility,
                    color: Color(0xFF39FF14),
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sightings',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF39FF14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final sightings = snapshot.data ?? [];
        final sightingsCount = sightings.length;

        if (sightingsCount == 0) {
          return _buildInfoCard(
            icon: Icons.visibility,
            title: 'Sightings',
            content: 'No sightings yet',
            context: context,
          );
        }

        // Initialize sightings data on first load
        if (_allSightings.isEmpty && sightings.isNotEmpty) {
          _initializeSightings(sightings);
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.visibility, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sightings',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$sightingsCount total',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLazySightingsGallery(context),
              ],
            ),
          ),
        );
      },
    );
  }

  void _initializeSightings(List<Sighting> sightings) {
    // Sort sightings by timestamp (most recent first)
    _allSightings = List<Sighting>.from(sightings);
    _allSightings.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Initialize first page without setState (since we're in build phase)
    _currentPage = 0;
    _displayedSightings.clear();
    final endIndex =
        _itemsPerPage > _allSightings.length
            ? _allSightings.length
            : _itemsPerPage;
    _displayedSightings.addAll(_allSightings.sublist(0, endIndex));
    _currentPage = 1; // Set to 1 since we've loaded the first page
  }

  void _loadMoreSightings() {
    if (_isLoadingMore) return;

    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= _allSightings.length) return;

    setState(() {
      _isLoadingMore = true;
    });

    final newItems = _allSightings.sublist(
      startIndex,
      endIndex > _allSightings.length ? _allSightings.length : endIndex,
    );

    setState(() {
      _displayedSightings.addAll(newItems);
      _currentPage++;
      _isLoadingMore = false;
    });
  }

  Widget _buildLazySightingsGallery(BuildContext context) {
    return Column(
      children: [
        GridView.builder(
          key: _gridKey, // Add key to preserve widget state
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: _displayedSightings.length,
          itemBuilder: (context, index) {
            final sighting = _displayedSightings[index];
            return _buildSightingThumbnail(context, sighting);
          },
        ),
        // Loading indicator or "View All" button
        if (_displayedSightings.length < _allSightings.length) ...[
          if (_isLoadingMore) ...[
            const SizedBox(height: 20),
            const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF39FF14),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading more sightings...',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            const SizedBox(height: 16),
            Text(
              'Scroll down to load more (${_allSightings.length - _displayedSightings.length} remaining)',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ] else if (_allSightings.length > _itemsPerPage) ...[
          // Show "View All" button when all items are loaded
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _showAllSightings(context, _allSightings),
            child: Text(
              'View in Full Gallery',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSightingThumbnail(BuildContext context, Sighting sighting) {
    return GestureDetector(
      onTap: () => _viewSighting(context, sighting),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FutureBuilder<String?>(
                future: Util.fetchFromS3(sighting.photo),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.grey[300],
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF39FF14),
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.network(
                      snapshot.data!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 24,
                          ),
                        );
                      },
                    );
                  }

                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
            // Species label overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Text(
                  sighting.species,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewSighting(BuildContext context, Sighting sighting) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewSightingScreen(sighting: sighting),
      ),
    );
  }

  void _showAllSightings(BuildContext context, List<Sighting> sightings) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => UserSightingsGalleryScreen(
              user: widget.user,
              sightings: sightings,
            ),
      ),
    );
  }

  Future<List<Sighting>> _getUserSightings() async {
    try {
      final sightings = await Amplify.DataStore.query(
        Sighting.classType,
        where: Sighting.USER.eq(widget.user.id),
      );
      return sightings;
    } catch (e) {
      Log.e('Error fetching user sightings: $e');
      return [];
    }
  }

  String _formatMemberSince(DateTime? createdAt) {
    if (createdAt == null) return 'Unknown';
    return DateFormat('MMMM yyyy').format(createdAt);
  }

  Future<void> _handleRefresh() async {
    // Generate new keys to force FutureBuilders to rebuild
    setState(() {
      _profilePictureKey = UniqueKey();
      _sightingsKey = UniqueKey();
      // Reset lazy loading state
      _allSightings.clear();
      _displayedSightings.clear();
      _currentPage = 0;
      _isLoadingMore = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0, // Remove shadow for a flatter look
        title: Text('User Details'),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics:
              const AlwaysScrollableScrollPhysics(), // Always allow scrolling for refresh
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight, // Ensure minimum height for scrolling
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // Profile Picture and Basic Info
                  _buildProfilePicture(context),
                  const SizedBox(height: 20),
                  Text(
                    widget.user.display_username,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (widget.user.bio != null && widget.user.bio!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        widget.user.bio!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 20),

                  // User Information Cards
                  Column(
                    children: [
                      if (widget.user.school != null &&
                          widget.user.school!.isNotEmpty)
                        _buildInfoCard(
                          icon: Icons.school,
                          title: 'School',
                          content: widget.user.school!,
                          context: context,
                        ),
                      if (widget.user.age != null)
                        _buildInfoCard(
                          icon: Icons.cake,
                          title: 'Age',
                          content: '${widget.user.age} years old',
                          context: context,
                        ),
                      if (widget.user.country != null &&
                          widget.user.country!.isNotEmpty)
                        _buildInfoCard(
                          icon: Icons.public,
                          title: 'Country',
                          content: widget.user.country!,
                          context: context,
                        ),
                      _buildInfoCard(
                        icon: Icons.calendar_today,
                        title: 'Member Since',
                        content: _formatMemberSince(
                          widget.user.createdAt?.getDateTimeInUtc(),
                        ),
                        context: context,
                      ),
                      _buildSightingsSection(context),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
