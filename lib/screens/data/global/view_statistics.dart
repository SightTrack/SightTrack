import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';

class ViewStatisticsPage extends StatefulWidget {
  const ViewStatisticsPage({super.key});

  @override
  State<ViewStatisticsPage> createState() => _ViewStatisticsPageState();
}

class _ViewStatisticsPageState extends State<ViewStatisticsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('View Statistics'),
      ),
      body: const Center(child: Text('View Statistics Page')),
    );
  }
}
