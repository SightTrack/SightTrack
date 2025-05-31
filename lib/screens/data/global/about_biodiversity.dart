import 'package:flutter/material.dart';

class AboutBiodiversityScreen extends StatefulWidget {
  const AboutBiodiversityScreen({super.key});

  @override
  State<AboutBiodiversityScreen> createState() =>
      _AboutBiodiversityScreenState();
}

class _AboutBiodiversityScreenState extends State<AboutBiodiversityScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('About Biodiversity Scores'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text(
                  'Understanding Biodiversity Scores',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Our biodiversity scoring system uses advanced spatial statistics to measure species distribution patterns and identify biodiversity hotspots.',
                  style: TextStyle(color: Colors.grey[300], fontSize: 16),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),

          // Moran's I Section
          _buildSectionHeader("Moran's I Spatial Correlation"),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionContent(
                  content:
                      "We use Moran's I statistic to measure how species are distributed across space. This helps identify whether sightings of a species tend to be:",
                  bulletPoints: [
                    'Clustered (Score > 0.3): Species found in concentrated areas',
                    'Random (-0.3 to 0.3): No clear pattern in distribution',
                    'Dispersed (Score < -0.3): Species spread out evenly',
                  ],
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),

          // Factors Section
          _buildSectionHeader('Factors in Calculation'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionContent(
                  content: 'The biodiversity score takes into account:',
                  bulletPoints: [
                    'Geographic distance between sightings',
                    'Temporal patterns (time between sightings)',
                    'Species density in local areas',
                    'Maximum distance threshold (10km)',
                  ],
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),

          // Visual Patterns Section
          _buildSectionHeader('Visual Distribution Patterns'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDistributionPattern(
                        'Clustered',
                        Icons.circle,
                        Colors.green,
                        'Score > 0.3',
                      ),
                      _buildDistributionPattern(
                        'Random',
                        Icons.circle,
                        Colors.yellow,
                        '-0.3 to 0.3',
                      ),
                      _buildDistributionPattern(
                        'Dispersed',
                        Icons.circle,
                        Colors.red,
                        'Score < -0.3',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Practical Examples Section
          _buildSectionHeader('Practical Examples'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionContent(
                  content: 'Consider these scenarios:',
                  bulletPoints: [
                    'High Score (0.8): Many Blue Jays spotted in a local park',
                    'Medium Score (0.2): Rabbits seen occasionally throughout the city',
                    'Low Score (-0.5): Butterflies spotted evenly across wide areas',
                  ],
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),

          // How to Contribute Section
          _buildSectionHeader('How to Contribute Better Data'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionContent(
                  content: 'To help improve biodiversity analysis:',
                  bulletPoints: [
                    'Record multiple sightings in an area when possible',
                    'Include accurate location data',
                    'Note the time of sightings',
                    'Add detailed descriptions of the environment',
                  ],
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),

          // Research Value Section
          _buildSectionHeader('Research Value'),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 32.0),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.science, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Scientific Impact',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your sightings contribute to scientific understanding of:',
                      style: TextStyle(
                        color: Colors.blue.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Species distribution patterns\n'
                      '• Habitat preferences\n'
                      '• Migration patterns\n'
                      '• Urban wildlife adaptation',
                      style: TextStyle(
                        color: Colors.blue.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent({
    required String content,
    required List<String> bulletPoints,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(content, style: TextStyle(color: Colors.grey[300], fontSize: 16)),
        const SizedBox(height: 8),
        ...bulletPoints.map(
          (point) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(color: Colors.grey[300], fontSize: 16),
                ),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(color: Colors.grey[300], fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionPattern(
    String title,
    IconData icon,
    Color color,
    String score,
  ) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: RepaintBoundary(
            child: CustomPaint(
              painter: DistributionPainter(
                title: title,
                color: color,
                seed: title.hashCode,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        Text(score, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SectionHeaderDelegate(
        title: title,
        backgroundColor: Colors.grey[900]!,
      ),
    );
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final Color backgroundColor;

  _SectionHeaderDelegate({required this.title, required this.backgroundColor});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = shrinkOffset / maxExtent;
    final titleSize = 20.0 - (progress * 4.0);

    return Container(
      color: backgroundColor.withValues(alpha: 0.98),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            bottom: 16 - (progress * 8),
            left: 16,
            right: 16,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (overlapsContent)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(height: 1, color: Colors.grey[800]),
            ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 80.0;

  @override
  double get minExtent => 60.0;

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) {
    return title != oldDelegate.title ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}

class DistributionPainter extends CustomPainter {
  final String title;
  final Color color;
  final int seed;

  DistributionPainter({
    required this.title,
    required this.color,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color.withValues(alpha: 0.6)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;

    switch (title) {
      case 'Clustered':
        // Draw clustered points
        for (var i = 0; i < 12; i++) {
          final x = size.width * 0.3 + ((seed + i * 7) % 30) + (i % 3) * 10;
          final y = size.height * 0.3 + ((seed + i * 11) % 30) + (i ~/ 3) * 10;
          canvas.drawCircle(Offset(x, y), 3, paint);
        }
        break;
      case 'Random':
        // Draw random points
        for (var i = 0; i < 12; i++) {
          final x = (seed + i * 17) % size.width.toInt();
          final y = (seed + i * 23) % size.height.toInt();
          canvas.drawCircle(Offset(x.toDouble(), y.toDouble()), 3, paint);
        }
        break;
      case 'Dispersed':
        // Draw evenly dispersed points
        for (var i = 0; i < 12; i++) {
          final x = size.width * ((i % 4) / 4);
          final y = size.height * ((i ~/ 4) / 3);
          canvas.drawCircle(Offset(x + 15, y + 15), 3, paint);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant DistributionPainter oldDelegate) =>
      oldDelegate.title != title ||
      oldDelegate.color != color ||
      oldDelegate.seed != seed;
}
