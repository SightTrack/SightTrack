import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';
import 'dart:math' as math;

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() => _isLoading = true);

      final users = await Amplify.DataStore.query(User.classType);
      final sightings = await Amplify.DataStore.query(Sighting.classType);

      // Species Analysis
      final speciesCount = <String, int>{};
      for (final sighting in sightings) {
        speciesCount[sighting.species] =
            (speciesCount[sighting.species] ?? 0) + 1;
      }
      final sortedSpecies =
          speciesCount.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      // Geographic Analysis
      final cityCount = <String, int>{};
      for (final sighting in sightings) {
        if (sighting.city != null && sighting.city!.isNotEmpty) {
          cityCount[sighting.city!] = (cityCount[sighting.city!] ?? 0) + 1;
        }
      }
      final sortedCities =
          cityCount.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      // Temporal Analysis
      final hourlyCount = <int, int>{};
      for (final sighting in sightings) {
        final hour = sighting.timestamp.getDateTimeInUtc().hour;
        hourlyCount[hour] = (hourlyCount[hour] ?? 0) + 1;
      }

      // Volunteer Hours
      final totalVolunteerHours = Volunteer.calculateTotalServiceHours(
        sightings,
      );

      setState(() {
        _analyticsData = {
          'totalUsers': users.length,
          'totalSightings': sightings.length,
          'totalSpecies': speciesCount.length,
          'totalVolunteerHours': totalVolunteerHours,
          'topSpecies': sortedSpecies.take(10).toList(),
          'topCities': sortedCities.take(10).toList(),
          'hourlyData': hourlyCount,
          'peakHour':
              hourlyCount.entries.isEmpty
                  ? 0
                  : hourlyCount.entries
                      .reduce((a, b) => a.value > b.value ? a : b)
                      .key,
          'shannonDiversity': _calculateShannonDiversity(speciesCount),
        };
        _isLoading = false;
      });
    } catch (e) {
      Log.e('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  double _calculateShannonDiversity(Map<String, int> speciesCount) {
    if (speciesCount.isEmpty) return 0.0;

    final total = speciesCount.values.reduce((a, b) => a + b);
    double shannonIndex = 0.0;

    for (final count in speciesCount.values) {
      if (count > 0) {
        final proportion = count / total;
        shannonIndex -= proportion * (math.log(proportion) / math.log(2));
      }
    }

    return shannonIndex;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Analytics Dashboard',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Tab Selection
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabButton('Overview', 0),
                    _buildTabButton('Species', 1),
                    _buildTabButton('Geography', 2),
                    _buildTabButton('Timeline', 3),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(child: _buildTabContent()),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () => setState(() => _selectedTabIndex = index),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? Theme.of(context).colorScheme.primary : null,
          foregroundColor:
              isSelected ? Theme.of(context).colorScheme.onPrimary : null,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildSpeciesTab();
      case 2:
        return _buildGeographyTab();
      case 3:
        return _buildTimelineTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Key Metrics
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 1,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
            children: [
              _buildMetricCard(
                'Total Users',
                '${_analyticsData['totalUsers'] ?? 0}',
                Icons.people,
                Colors.blue,
              ),
              _buildMetricCard(
                'Total Sightings',
                '${_analyticsData['totalSightings'] ?? 0}',
                Icons.camera_alt,
                Colors.green,
              ),
              _buildMetricCard(
                'Species Recorded',
                '${_analyticsData['totalSpecies'] ?? 0}',
                Icons.pets,
                Colors.orange,
              ),
              _buildMetricCard(
                'Volunteer Hours',
                '${(_analyticsData['totalVolunteerHours'] ?? 0.0).toStringAsFixed(1)}h',
                Icons.volunteer_activism,
                Colors.purple,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Insights
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Insights',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInsightRow(
                    'Peak Activity Hour',
                    '${_analyticsData['peakHour'] ?? 0}:00',
                  ),
                  _buildInsightRow(
                    'Diversity Index',
                    '${(_analyticsData['shannonDiversity'] ?? 0.0).toStringAsFixed(2)}',
                  ),
                  _buildInsightRow('Top Species', _getTopSpeciesName()),
                  _buildInsightRow('Top Location', _getTopCityName()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeciesTab() {
    final topSpecies = (_analyticsData['topSpecies'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Species: ${_analyticsData['totalSpecies'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Diversity Index: ${(_analyticsData['shannonDiversity'] ?? 0.0).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Most Sighted Species',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (topSpecies.isEmpty)
                    const Text('No species data available')
                  else
                    ...topSpecies.asMap().entries.map((entry) {
                      final index = entry.key;
                      final species = entry.value;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withValues(alpha: 0.2),
                          child: Text('${index + 1}'),
                        ),
                        title: Text(species.key),
                        trailing: Text('${species.value} sightings'),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeographyTab() {
    final topCities = (_analyticsData['topCities'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Locations Covered: ${topCities.length} cities',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Locations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (topCities.isEmpty)
                    const Text('No location data available')
                  else
                    ...topCities.asMap().entries.map((entry) {
                      final index = entry.key;
                      final city = entry.value;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.withValues(alpha: 0.2),
                          child: Text('${index + 1}'),
                        ),
                        title: Text(city.key),
                        trailing: Text('${city.value} sightings'),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    final hourlyData = (_analyticsData['hourlyData'] as Map?) ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peak Activity Hour: ${_analyticsData['peakHour'] ?? 0}:00',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activity by Hour',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (hourlyData.isEmpty)
                    const Text('No temporal data available')
                  else
                    ...List.generate(24, (hour) {
                      final count = hourlyData[hour] ?? 0;
                      if (count == 0) return const SizedBox.shrink();

                      return ListTile(
                        leading: Text('${hour.toString().padLeft(2, '0')}:00'),
                        title: LinearProgressIndicator(
                          value: count / 20, // Normalize to max of 20
                          backgroundColor:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.purple,
                          ),
                        ),
                        trailing: Text('$count'),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getTopSpeciesName() {
    final topSpecies = (_analyticsData['topSpecies'] as List?) ?? [];
    return topSpecies.isNotEmpty ? topSpecies[0].key : 'No data';
  }

  String _getTopCityName() {
    final topCities = (_analyticsData['topCities'] as List?) ?? [];
    return topCities.isNotEmpty ? topCities[0].key : 'No data';
  }
}
