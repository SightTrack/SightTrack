import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';

class VolunteerHoursScreen extends StatefulWidget {
  const VolunteerHoursScreen({super.key});

  @override
  State<VolunteerHoursScreen> createState() => _VolunteerHoursScreenState();
}

class _VolunteerHoursScreenState extends State<VolunteerHoursScreen> {
  List<Sighting> _sightings = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  late FToast fToast;

  // Activity supervisor state
  String? _selectedActivitySupervisor;
  List<String> _activitySupervisors = [];
  bool _loadingActivitySupervisors = true;
  final _activitySupervisorController = TextEditingController();
  final _activitySupervisorFocusNode = FocusNode();
  bool _isAddingNewActivitySupervisor = false;

  // School supervisor state
  String? _selectedSchoolSupervisor;
  List<String> _schoolSupervisors = [];
  bool _loadingSchoolSupervisors = true;
  final _schoolSupervisorController = TextEditingController();
  final _schoolSupervisorFocusNode = FocusNode();
  bool _isAddingNewSchoolSupervisor = false;

  @override
  void initState() {
    super.initState();
    _loadSightings();
    _loadSupervisors();

    fToast = FToast();
    fToast.init(context);
  }

  @override
  void dispose() {
    _activitySupervisorController.dispose();
    _activitySupervisorFocusNode.dispose();
    _schoolSupervisorController.dispose();
    _schoolSupervisorFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSightings() async {
    try {
      Log.i('Loading sightings...');
      final user = await Util.getUserModel();
      Log.i('User: $user');

      // Query sightings directly from DataStore
      final sightings = await Amplify.DataStore.query(
        Sighting.classType,
        where: Sighting.USER.eq(user.id),
      );

      Log.i('Found ${sightings.length} sightings');

      setState(() {
        _sightings =
            sightings..sort(
              (a, b) => b.timestamp.getDateTimeInUtc().compareTo(
                a.timestamp.getDateTimeInUtc(),
              ),
            );
        _isLoading = false;
      });
    } catch (e) {
      Log.e('Error loading sightings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSupervisors() async {
    try {
      final activitySupervisors = await Volunteer.getActivitySupervisors();
      final schoolSupervisors = await Volunteer.getSchoolSupervisors();
      if (mounted) {
        setState(() {
          _activitySupervisors = activitySupervisors;
          _schoolSupervisors = schoolSupervisors;
          _loadingActivitySupervisors = false;
          _loadingSchoolSupervisors = false;
        });
      }
    } catch (e) {
      Log.e('Error loading supervisors: $e');
      if (mounted) {
        setState(() {
          _loadingActivitySupervisors = false;
          _loadingSchoolSupervisors = false;
        });
      }
    }
  }

  void _handleActivitySupervisorSelection(String supervisor) {
    setState(() {
      _selectedActivitySupervisor = supervisor;
      _activitySupervisorController.text = supervisor;
      _isAddingNewActivitySupervisor = false;
    });
  }

  void _handleSchoolSupervisorSelection(String supervisor) {
    setState(() {
      _selectedSchoolSupervisor = supervisor;
      _schoolSupervisorController.text = supervisor;
      _isAddingNewSchoolSupervisor = false;
    });
  }

  void _handleAddNewActivitySupervisor(String newSupervisor) {
    setState(() {
      _selectedActivitySupervisor = newSupervisor;
      _activitySupervisorController.text = newSupervisor;
      _isAddingNewActivitySupervisor = false;
    });
  }

  void _handleAddNewSchoolSupervisor(String newSupervisor) {
    setState(() {
      _selectedSchoolSupervisor = newSupervisor;
      _schoolSupervisorController.text = newSupervisor;
      _isAddingNewSchoolSupervisor = false;
    });
  }

  Widget _buildSightingsList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_sightings.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.nature_outlined,
                size: 64,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No sightings yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final sighting = _sightings[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewSightingScreen(sighting: sighting),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sighting.species,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sighting.city ?? 'Unknown location',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  DateFormat(
                    'MM/dd/yy • HH:mm',
                  ).format(sighting.timestamp.getDateTimeInUtc().toLocal()),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        );
      }, childCount: _sightings.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Volunteer Hours'),
              floating: true,
              snap: true,
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverHeaderDelegate(
                title: 'My Sightings',
                height: 50,
              ),
            ),
            _buildSightingsList(),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverHeaderDelegate(
                title: 'Volunteer Hours',
                height: 50,
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Volunteer Hours: ${Volunteer.calculateTotalServiceHours(_sightings).round()}',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'How are volunteer hours calculated?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Base time: 15 minutes per sighting\n'
                      '• Description bonus: +5 minutes per 50 characters of detailed observations\n'
                      '• Travel time: Calculated based on distance between consecutive sightings\n'
                      '  - Uses actual GPS coordinates\n'
                      '  - Assumes average travel speed of 30 km/h\n'
                      '  - Only counts if sightings are within 2 hours of each other\n\n'
                      'Tips to maximize your volunteer hours:\n'
                      '• Write detailed descriptions of your observations\n'
                      '• Record consecutive sightings when possible\n'
                      '• Include habitat information and behavior notes\n'
                      '• Take clear, well-focused photos',
                      style: TextStyle(fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your volunteer hours contribute to citizen science and wildlife conservation efforts. Thank you for your dedication!',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverHeaderDelegate(title: 'Claim Hours', height: 50),
            ),
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Activity Supervisor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_loadingActivitySupervisors)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Loading supervisors...'),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          // Unfocus when tapping outside of the input field
                          _activitySupervisorFocusNode.unfocus();
                        },
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _activitySupervisorController,
                                  focusNode: _activitySupervisorFocusNode,
                                  decoration: InputDecoration(
                                    hintText: 'Search or enter supervisor name',
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                    ),
                                    suffixIcon:
                                        _activitySupervisorController
                                                .text
                                                .isNotEmpty
                                            ? IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                setState(() {
                                                  _activitySupervisorController
                                                      .clear();
                                                  _selectedActivitySupervisor =
                                                      null;
                                                  _isAddingNewActivitySupervisor =
                                                      false;
                                                });
                                              },
                                            )
                                            : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    // Ensure the suggestions show up when tapping the field
                                    setState(() {});
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      _isAddingNewActivitySupervisor =
                                          value.isNotEmpty &&
                                          !_activitySupervisors.any(
                                            (s) =>
                                                s.toLowerCase() ==
                                                value.toLowerCase(),
                                          );
                                    });
                                  },
                                ),
                                if (_activitySupervisorFocusNode.hasFocus &&
                                    _activitySupervisorController
                                        .text
                                        .isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ...(_activitySupervisors
                                            .where(
                                              (s) => s.toLowerCase().contains(
                                                _activitySupervisorController
                                                    .text
                                                    .toLowerCase(),
                                              ),
                                            )
                                            .map(
                                              (s) => ListTile(
                                                leading: const Icon(
                                                  Icons.person,
                                                ),
                                                title: Text(s),
                                                onTap: () {
                                                  _handleActivitySupervisorSelection(
                                                    s,
                                                  );
                                                  _activitySupervisorFocusNode
                                                      .unfocus();
                                                },
                                              ),
                                            )),
                                        if (_isAddingNewActivitySupervisor)
                                          ListTile(
                                            leading: const Icon(
                                              Icons.add_circle_outline,
                                            ),
                                            title: Text(
                                              'Add "${_activitySupervisorController.text}" as new supervisor',
                                              style: const TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            onTap: () {
                                              _handleAddNewActivitySupervisor(
                                                _activitySupervisorController
                                                    .text,
                                              );
                                              _activitySupervisorFocusNode
                                                  .unfocus();
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select School Supervisor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_loadingSchoolSupervisors)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Loading supervisors...'),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          // Unfocus when tapping outside of the input field
                          _schoolSupervisorFocusNode.unfocus();
                        },
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _schoolSupervisorController,
                                  focusNode: _schoolSupervisorFocusNode,
                                  decoration: InputDecoration(
                                    hintText: 'Search or enter supervisor name',
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                    ),
                                    suffixIcon:
                                        _schoolSupervisorController
                                                .text
                                                .isNotEmpty
                                            ? IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                setState(() {
                                                  _schoolSupervisorController
                                                      .clear();
                                                  _selectedSchoolSupervisor =
                                                      null;
                                                  _isAddingNewSchoolSupervisor =
                                                      false;
                                                });
                                              },
                                            )
                                            : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    // Ensure the suggestions show up when tapping the field
                                    setState(() {});
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      _isAddingNewSchoolSupervisor =
                                          value.isNotEmpty &&
                                          !_schoolSupervisors.any(
                                            (s) =>
                                                s.toLowerCase() ==
                                                value.toLowerCase(),
                                          );
                                    });
                                  },
                                ),
                                if (_schoolSupervisorFocusNode.hasFocus &&
                                    _schoolSupervisorController.text.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ...(_schoolSupervisors
                                            .where(
                                              (s) => s.toLowerCase().contains(
                                                _schoolSupervisorController.text
                                                    .toLowerCase(),
                                              ),
                                            )
                                            .map(
                                              (s) => ListTile(
                                                leading: const Icon(
                                                  Icons.person,
                                                ),
                                                title: Text(s),
                                                onTap: () {
                                                  _handleSchoolSupervisorSelection(
                                                    s,
                                                  );
                                                  _schoolSupervisorFocusNode
                                                      .unfocus();
                                                },
                                              ),
                                            )),
                                        if (_isAddingNewSchoolSupervisor)
                                          ListTile(
                                            leading: const Icon(
                                              Icons.add_circle_outline,
                                            ),
                                            title: Text(
                                              'Add "${_schoolSupervisorController.text}" as new supervisor',
                                              style: const TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            onTap: () {
                                              _handleAddNewSchoolSupervisor(
                                                _schoolSupervisorController
                                                    .text,
                                              );
                                              _schoolSupervisorFocusNode
                                                  .unfocus();
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (_activitySupervisorController.text.isNotEmpty &&
                        _schoolSupervisorController.text.isNotEmpty)
                      Center(
                        child:
                            _isSubmitting
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                                : ModernDarkButton(
                                  onPressed: () async {
                                    if (_activitySupervisorController
                                            .text
                                            .isEmpty ||
                                        _schoolSupervisorController
                                            .text
                                            .isEmpty) {
                                      fToast.showToast(
                                        child: Util.redToast(
                                          'Please fill out both fields',
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() {
                                      _isSubmitting = true;
                                    });
                                    await _updateSupervisors();
                                  },
                                  text: 'Submit Hours',
                                ),
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateSupervisors() async {
    try {
      // Get current user
      final user = await Util.getUserModel();

      // Get current settings
      final existingSettings = await Amplify.DataStore.query(
        UserSettings.classType,
        where: UserSettings.USERID.eq(user.id),
      );

      if (existingSettings.isEmpty) {
        throw Exception('User settings not found');
      }

      final settings = existingSettings.first;

      // Get current supervisor lists and make them modifiable
      var currentActivitySupervisors = List<String>.from(
        settings.activitySupervisor ?? [],
      );
      var currentSchoolSupervisors = List<String>.from(
        settings.schoolSupervisor ?? [],
      );

      // Add new supervisors if they don't exist
      if (!currentActivitySupervisors.contains(_selectedActivitySupervisor)) {
        currentActivitySupervisors.add(_selectedActivitySupervisor!);
      }
      if (!currentSchoolSupervisors.contains(_selectedSchoolSupervisor)) {
        currentSchoolSupervisors.add(_selectedSchoolSupervisor!);
      }

      // Create updated settings
      final updatedSettings = settings.copyWith(
        activitySupervisor: currentActivitySupervisors,
        schoolSupervisor: currentSchoolSupervisors,
      );

      // Save to DataStore
      await Amplify.DataStore.save(updatedSettings);

      if (mounted) {
        await Volunteer.initiateVolunteerHoursRequest(
          _selectedActivitySupervisor!,
          _selectedSchoolSupervisor!,
        );

        setState(() {
          _isSubmitting = false;
        });

        // Show success message
        fToast.showToast(
          child: Util.greenToast('Sent volunteer hours request'),
          toastDuration: Duration(seconds: 4),
        );

        // Clear the form
        _activitySupervisorController.clear();
        _schoolSupervisorController.clear();
        _selectedActivitySupervisor = null;
        _selectedSchoolSupervisor = null;

        //Go back to profile screen
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      Log.e('Error updating supervisors: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        fToast.showToast(child: Util.redToast('Error updating supervisors'));
      }
    }
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final double height;

  _SliverHeaderDelegate({required this.title, required this.height});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: height,
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _SliverHeaderDelegate oldDelegate) {
    return title != oldDelegate.title || height != oldDelegate.height;
  }
}
