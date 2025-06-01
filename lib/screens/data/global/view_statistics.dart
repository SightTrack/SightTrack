import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';

class ViewStatisticsPage extends StatefulWidget {
  const ViewStatisticsPage({super.key});

  @override
  State<ViewStatisticsPage> createState() => _ViewStatisticsPageState();
}

class _ViewStatisticsPageState extends State<ViewStatisticsPage> {
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Statistics')),
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sighting'),
            Text('Total Sightings: '),
            Text('Total Sightings Today: '),
          ],
        ),
      ),
    );
  }
}
