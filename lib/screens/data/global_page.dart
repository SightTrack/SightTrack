import 'package:flutter/material.dart';

import 'package:sighttrack/barrel.dart';

class GlobalView extends StatefulWidget {
  const GlobalView({super.key});

  @override
  State<GlobalView> createState() => _GlobalViewState();
}

class _GlobalViewState extends State<GlobalView> {
  int _totalSightings = 0;
  int _uniqueSpecies = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGlobalData();
  }

  Future<void> _fetchGlobalData() async {
    try {
      // Fetch all sightings
      final sightings = await Amplify.DataStore.query(Sighting.classType);

      // Calculate total sightings
      final total = sightings.length;

      // Calculate unique species
      final speciesSet = sightings.map((s) => s.species).toSet();
      final unique = speciesSet.length;

      setState(() {
        _totalSightings = total;
        _uniqueSpecies = unique;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching global data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Column(
                      children: [
                        _buildStatCard(
                          'Total Sightings',
                          _totalSightings.toString(),
                        ),
                        _buildStatCard(
                          'Unique Species',
                          _uniqueSpecies.toString(),
                        ),
                      ],
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
