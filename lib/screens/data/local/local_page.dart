import 'package:sighttrack/barrel.dart';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class LocalView extends StatefulWidget {
  const LocalView({super.key});

  @override
  State<LocalView> createState() => _LocalViewState();
}

class _LocalViewState extends State<LocalView> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(child: Column(children: [const Text('Coming soon!')])),
    );
  }
}
