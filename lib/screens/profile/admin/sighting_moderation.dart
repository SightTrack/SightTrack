import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';

class SightingModerationScreen extends StatefulWidget {
  const SightingModerationScreen({super.key});

  @override
  State<SightingModerationScreen> createState() =>
      _SightingModerationScreenState();
}

class _SightingModerationScreenState extends State<SightingModerationScreen> {
  bool _isLoading = true;
  List<Sighting> _sightings = [];
  List<Sighting> _filteredSightings = [];
  String _searchQuery = '';
  Set<String> _selectedSightings = {};

  @override
  void initState() {
    super.initState();
    _loadSightings();
  }

  Future<void> _loadSightings() async {
    try {
      setState(() => _isLoading = true);
      final sightings = await Amplify.DataStore.query(Sighting.classType);
      sightings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      setState(() {
        _sightings = sightings;
        _filteredSightings = sightings;
        _isLoading = false;
      });
    } catch (e) {
      Log.e('Error loading sightings: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterSightings(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSightings = _sightings;
      } else {
        _filteredSightings =
            _sightings.where((sighting) {
              return sighting.species.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  (sighting.city?.toLowerCase().contains(query.toLowerCase()) ??
                      false);
            }).toList();
      }
    });
  }

  Future<void> _deleteSighting(Sighting sighting) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Sighting'),
            content: Text(
              'Are you sure you want to delete this ${sighting.species} sighting?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await Amplify.DataStore.delete(sighting);
        _loadSightings();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Sighting deleted')));
        }
      } catch (e) {
        Log.e('Error deleting sighting: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error deleting sighting')),
          );
        }
      }
    }
  }

  Future<void> _deleteSelectedSightings() async {
    if (_selectedSightings.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Selected Sightings'),
            content: Text(
              'Are you sure you want to delete ${_selectedSightings.length} sightings?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete All'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        for (final sightingId in _selectedSightings) {
          final sighting = _sightings.firstWhere((s) => s.id == sightingId);
          await Amplify.DataStore.delete(sighting);
        }
        setState(() => _selectedSightings.clear());
        _loadSightings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected sightings deleted')),
          );
        }
      } catch (e) {
        Log.e('Error deleting sightings: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error deleting sightings')),
          );
        }
      }
    }
  }

  void _viewSighting(Sighting sighting) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewSightingScreen(sighting: sighting),
      ),
    );
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
              Row(
                children: [
                  // const Text(
                  //   'Sighting Moderation',
                  //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  // ),
                  Text('${_filteredSightings.length} sightings'),
                  const Spacer(),

                  if (_selectedSightings.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _deleteSelectedSightings,
                      icon: const Icon(Icons.delete),
                      label: Text('Delete ${_selectedSightings.length}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search sightings...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _filterSightings,
              ),
            ],
          ),
        ),

        // Sightings List
        Expanded(
          child:
              _filteredSightings.isEmpty
                  ? const Center(child: Text('No sightings found'))
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredSightings.length,
                    itemBuilder: (context, index) {
                      final sighting = _filteredSightings[index];
                      final isSelected = _selectedSightings.contains(
                        sighting.id,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Checkbox(
                            value: isSelected,
                            onChanged: (selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedSightings.add(sighting.id);
                                } else {
                                  _selectedSightings.remove(sighting.id);
                                }
                              });
                            },
                          ),
                          title: Text(sighting.species),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sighting.city ?? 'Unknown location'),
                              Text(
                                _formatDateTime(
                                  sighting.timestamp.getDateTimeInUtc(),
                                ),
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'view':
                                  _viewSighting(sighting);
                                  break;
                                case 'delete':
                                  _deleteSighting(sighting);
                                  break;
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Text('View Details'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                          ),
                          onTap: () => _viewSighting(sighting),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
