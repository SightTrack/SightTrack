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
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('View Statistics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sighting',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
            Text(
              'Total Sightings: ',
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
            Text(
              'Total Sightings Today: ',
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
