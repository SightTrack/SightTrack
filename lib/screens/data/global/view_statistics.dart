import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';

class ViewStatisticsPage extends StatefulWidget {
  const ViewStatisticsPage({super.key});

  @override
  State<ViewStatisticsPage> createState() => _ViewStatisticsPageState();
}

class _ViewStatisticsPageState extends State<ViewStatisticsPage> {
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await Statistics.getAllStatistics();
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading statistics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Statistics')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    _buildSection(
                      'User Statistics',
                      _statistics['userStatistics'],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      'Sighting Statistics',
                      _statistics['sightingStatistics'],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      'Combined Statistics',
                      _statistics['combinedStatistics'],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSection(String title, Map<String, dynamic>? data) {
    if (data == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...data.entries.map(
          (entry) => _buildStatItem(entry.key, entry.value, 0),
        ),
      ],
    );
  }

  Widget _buildStatItem(String key, dynamic value, int indentLevel) {
    final indent = '  ' * indentLevel;

    if (value is Map<String, dynamic>) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: indentLevel * 16.0, bottom: 4.0),
            child: Text('$indent$key:'),
          ),
          ...value.entries.map(
            (entry) => _buildStatItem(entry.key, entry.value, indentLevel + 1),
          ),
        ],
      );
    } else if (value is List) {
      if (value.isEmpty) {
        return Padding(
          padding: EdgeInsets.only(left: indentLevel * 16.0, bottom: 4.0),
          child: Text('$indent$key: (empty)'),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: indentLevel * 16.0, bottom: 4.0),
            child: Text('$indent$key:'),
          ),
          ...value.asMap().entries.map((entry) {
            if (entry.value is Map) {
              return _buildStatItem(
                '${entry.key + 1}',
                entry.value,
                indentLevel + 1,
              );
            } else {
              return Padding(
                padding: EdgeInsets.only(
                  left: (indentLevel + 1) * 16.0,
                  bottom: 2.0,
                ),
                child: Text('${'  ' * (indentLevel + 1)}- ${entry.value}'),
              );
            }
          }),
        ],
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(left: indentLevel * 16.0, bottom: 4.0),
        child: Text('$indent$key: ${_formatSimpleValue(value)}'),
      );
    }
  }

  String _formatSimpleValue(dynamic value) {
    if (value is double) {
      return value.toStringAsFixed(2);
    } else if (value is String && value.isEmpty) {
      return '(empty)';
    }
    return value.toString();
  }
}
