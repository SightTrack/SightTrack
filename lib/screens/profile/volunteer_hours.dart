import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';

class VolunteerHoursScreen extends StatefulWidget {
  const VolunteerHoursScreen({super.key});

  @override
  State<VolunteerHoursScreen> createState() => _VolunteerHoursScreenState();
}

class _VolunteerHoursScreenState extends State<VolunteerHoursScreen> {
  List<Sighting> _sightings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSightings();
  }

  Future<void> _loadSightings() async {
    try {
      Log.i('Loading sightings...');
      final user = await Util.getUserModel();
      Log.i('User: $user');

      // Query sightings directly from DataStore
      final sightings = await Amplify.DataStore.query(
        Sighting.classType,
        where: Sighting.USER.eq(user.id),
      );

      Log.i('Found ${sightings.length} sightings');

      setState(() {
        _sightings =
            sightings..sort(
              (a, b) => b.timestamp.getDateTimeInUtc().compareTo(
                a.timestamp.getDateTimeInUtc(),
              ),
            );
        _isLoading = false;
      });
    } catch (e) {
      Log.e('Error loading sightings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSightingsList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_sightings.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.nature_outlined,
                size: 64,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No sightings yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final sighting = _sightings[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewSightingScreen(sighting: sighting),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sighting.species,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sighting.city ?? 'Unknown location',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  DateFormat(
                    'MM/dd/yy • HH:mm',
                  ).format(sighting.timestamp.getDateTimeInUtc().toLocal()),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        );
      }, childCount: _sightings.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text(
                'Volunteer Hours',
                style: TextStyle(color: Colors.white),
              ),
              foregroundColor: Colors.white,
              backgroundColor: Colors.transparent,
              floating: true,
              snap: true,
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverHeaderDelegate(
                title: 'My Sightings',
                height: 50,
              ),
            ),
            _buildSightingsList(),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverHeaderDelegate(
                title: 'Volunteer Hours',
                height: 50,
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Volunteer Hours: ${Volunteer.calculateTotalServiceHours(_sightings).round()}',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'How are volunteer hours calculated?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Base time: 15 minutes per sighting\n'
                      '• Description bonus: +5 minutes per 50 characters of detailed observations\n'
                      '• Travel time: Calculated based on distance between consecutive sightings\n'
                      '  - Uses actual GPS coordinates\n'
                      '  - Assumes average travel speed of 30 km/h\n'
                      '  - Only counts if sightings are within 2 hours of each other\n\n'
                      'Tips to maximize your volunteer hours:\n'
                      '• Write detailed descriptions of your observations\n'
                      '• Record consecutive sightings when possible\n'
                      '• Include habitat information and behavior notes\n'
                      '• Take clear, well-focused photos',
                      style: TextStyle(fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your volunteer hours contribute to citizen science and wildlife conservation efforts. Thank you for your dedication!',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
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
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final double height;

  _SliverHeaderDelegate({required this.title, required this.height});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: height,
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _SliverHeaderDelegate oldDelegate) {
    return title != oldDelegate.title || height != oldDelegate.height;
  }
}
