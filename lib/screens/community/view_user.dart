import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';

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

        final sightingsCount = snapshot.data?.length ?? 0;
        return _buildInfoCard(
          icon: Icons.visibility,
          title: 'Sightings',
          content: '$sightingsCount total',
          context: context,
        );
      },
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
    });
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
