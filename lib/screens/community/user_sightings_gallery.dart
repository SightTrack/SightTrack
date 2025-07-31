import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';

class UserSightingsGalleryScreen extends StatelessWidget {
  final User user;
  final List<Sighting> sightings;

  const UserSightingsGalleryScreen({
    super.key,
    required this.user,
    required this.sightings,
  });

  @override
  Widget build(BuildContext context) {
    // Sort sightings by timestamp (most recent first)
    final sortedSightings = List<Sighting>.from(sightings);
    sortedSightings.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      appBar: AppBar(
        title: Text('${user.display_username}\'s Sightings'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header with stats
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Sightings',
                    '${sightings.length}',
                    Icons.visibility,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Unique Species',
                    '${sightings.map((s) => s.species).toSet().length}',
                    Icons.pets,
                  ),
                ),
              ],
            ),
          ),

          // Gallery grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: sortedSightings.length,
              itemBuilder: (context, index) {
                final sighting = sortedSightings[index];
                return _buildSightingCard(context, sighting);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSightingCard(BuildContext context, Sighting sighting) {
    return GestureDetector(
      onTap: () => _viewSighting(context, sighting),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Expanded(
              flex: 3,
              child: SizedBox(
                width: double.infinity,
                child: FutureBuilder<String?>(
                  future: Util.fetchFromS3(sighting.photo),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF39FF14),
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
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 32,
                            ),
                          );
                        },
                      );
                    }

                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image,
                        color: Colors.grey,
                        size: 32,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Info section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sighting.species,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (sighting.city != null && sighting.city!.isNotEmpty)
                      Text(
                        sighting.city!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    Text(
                      DateFormat(
                        'MMM dd, yyyy',
                      ).format(sighting.timestamp.getDateTimeInUtc().toLocal()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
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
}
