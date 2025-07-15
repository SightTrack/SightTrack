import 'package:sighttrack/barrel.dart';
import 'package:flutter/material.dart';

class LocalView extends StatefulWidget {
  const LocalView({super.key});

  @override
  State<LocalView> createState() => _LocalViewState();
}

class _LocalViewState extends State<LocalView> {
  bool _isLoading = true;
  late List<Sighting>? _uniqueSightings;
  late List<Sighting>? _allSightings;

  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoading = false;
    });
  }

  Future<List<String>>? _fetchUniqueSpecies() async {
    List<Sighting> sightings = await Amplify.DataStore.query(
      Sighting.classType,
    );

    List<String> uniqueSpecies =
        sightings
            .map((sighting) => sighting.species)
            .where((species) => species.isNotEmpty)
            .toSet()
            .toList();

    print(uniqueSpecies);

    return [];
  }

  @override
  Widget build(BuildContext context) {
    // _fetchUniqueSpecies();
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Coming Soon!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline),
                                const SizedBox(width: 12),
                                const Text(
                                  'Feature in Development',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'We\'re working hard to bring you local data management capabilities. Stay tuned for updates!',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
