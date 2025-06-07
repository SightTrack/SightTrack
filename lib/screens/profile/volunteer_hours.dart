import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';

class VolunteerHoursScreen extends StatefulWidget {
  const VolunteerHoursScreen({super.key});

  @override
  State<VolunteerHoursScreen> createState() => _VolunteerHoursScreenState();
}

class _VolunteerHoursScreenState extends State<VolunteerHoursScreen>
    with SingleTickerProviderStateMixin {
  List<Sighting> _unclaimedSightings = [];
  List<Sighting> _claimedSightings = [];
  List<Sighting> _allUnclaimedSightings =
      []; // Store all unclaimed sightings for calculation
  bool _isLoading = true;
  bool _isSubmitting = false;
  late FToast fToast;
  late TabController _tabController;

  // Pagination
  static const int _pageSize = 15;
  int _unclaimedPage = 0;
  int _claimedPage = 0;
  bool _hasMoreUnclaimed = true;
  bool _hasMoreClaimed = true;
  bool _loadingMoreUnclaimed = false;
  bool _loadingMoreClaimed = false;

  // Total counts for tab badges
  int _totalUnclaimedCount = 0;
  int _totalClaimedCount = 0;

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
    _tabController = TabController(length: 2, vsync: this);
    _loadSightings();
    _loadSupervisors();

    fToast = FToast();
    fToast.init(context);

    initialize();
  }

  Future<void> initialize() async {
    Mail testMail = Mail(
      'volunteer@mail.sighttrack.org',
      '0651jamestan@gmail.com',
    );
    // await testMail.sendEmail('Test', 'Hello, this is a test email');
  }

  @override
  void dispose() {
    _activitySupervisorController.dispose();
    _activitySupervisorFocusNode.dispose();
    _schoolSupervisorController.dispose();
    _schoolSupervisorFocusNode.dispose();
    _tabController.dispose();
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

      // Sort sightings by timestamp (newest first)
      sightings.sort(
        (a, b) => b.timestamp.getDateTimeInUtc().compareTo(
          a.timestamp.getDateTimeInUtc(),
        ),
      );

      // Separate claimed and unclaimed sightings
      final unclaimed =
          sightings.where((s) => s.isTimeClaimed != true).toList();
      final claimed = sightings.where((s) => s.isTimeClaimed == true).toList();

      setState(() {
        _unclaimedSightings = unclaimed.take(_pageSize).toList();
        _claimedSightings = claimed.take(_pageSize).toList();
        _hasMoreUnclaimed = unclaimed.length > _pageSize;
        _hasMoreClaimed = claimed.length > _pageSize;
        _unclaimedPage = 0;
        _claimedPage = 0;
        _isLoading = false;
        _totalUnclaimedCount = unclaimed.length;
        _totalClaimedCount = claimed.length;
        _allUnclaimedSightings = unclaimed;
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

  Future<void> _loadMoreSightings(bool isUnclaimed) async {
    if (isUnclaimed && (_loadingMoreUnclaimed || !_hasMoreUnclaimed)) return;
    if (!isUnclaimed && (_loadingMoreClaimed || !_hasMoreClaimed)) return;

    setState(() {
      if (isUnclaimed) {
        _loadingMoreUnclaimed = true;
      } else {
        _loadingMoreClaimed = true;
      }
    });

    try {
      final user = await Util.getUserModel();
      final allSightings = await Amplify.DataStore.query(
        Sighting.classType,
        where: Sighting.USER.eq(user.id),
      );

      allSightings.sort(
        (a, b) => b.timestamp.getDateTimeInUtc().compareTo(
          a.timestamp.getDateTimeInUtc(),
        ),
      );

      if (isUnclaimed) {
        final unclaimed =
            allSightings.where((s) => s.isTimeClaimed != true).toList();
        final nextPage = _unclaimedPage + 1;
        final startIndex = nextPage * _pageSize;
        final endIndex = (nextPage + 1) * _pageSize;

        if (startIndex < unclaimed.length) {
          final newSightings = unclaimed.sublist(
            startIndex,
            endIndex > unclaimed.length ? unclaimed.length : endIndex,
          );

          setState(() {
            _unclaimedSightings.addAll(newSightings);
            _unclaimedPage = nextPage;
            _hasMoreUnclaimed = endIndex < unclaimed.length;
            _loadingMoreUnclaimed = false;
            _totalUnclaimedCount = unclaimed.length;
            _allUnclaimedSightings = unclaimed;
          });
        } else {
          setState(() {
            _hasMoreUnclaimed = false;
            _loadingMoreUnclaimed = false;
          });
        }
      } else {
        final claimed =
            allSightings.where((s) => s.isTimeClaimed == true).toList();
        final nextPage = _claimedPage + 1;
        final startIndex = nextPage * _pageSize;
        final endIndex = (nextPage + 1) * _pageSize;

        if (startIndex < claimed.length) {
          final newSightings = claimed.sublist(
            startIndex,
            endIndex > claimed.length ? claimed.length : endIndex,
          );

          setState(() {
            _claimedSightings.addAll(newSightings);
            _claimedPage = nextPage;
            _hasMoreClaimed = endIndex < claimed.length;
            _loadingMoreClaimed = false;
            _totalClaimedCount = claimed.length;
          });
        } else {
          setState(() {
            _hasMoreClaimed = false;
            _loadingMoreClaimed = false;
          });
        }
      }
    } catch (e) {
      Log.e('Error loading more sightings: $e');
      setState(() {
        if (isUnclaimed) {
          _loadingMoreUnclaimed = false;
        } else {
          _loadingMoreClaimed = false;
        }
      });
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

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 400, // Fixed height for the tabbed content
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Unclaimed'),
                      SizedBox(width: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_totalUnclaimedCount',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Claimed'),
                      SizedBox(width: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_totalClaimedCount',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSightingTab(true), // Unclaimed
                  _buildSightingTab(false), // Claimed
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSightingTab(bool isUnclaimed) {
    final sightings = isUnclaimed ? _unclaimedSightings : _claimedSightings;
    final hasMore = isUnclaimed ? _hasMoreUnclaimed : _hasMoreClaimed;
    final loadingMore =
        isUnclaimed ? _loadingMoreUnclaimed : _loadingMoreClaimed;

    if (sightings.isEmpty) {
      return Center(
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
              isUnclaimed ? 'No unclaimed sightings' : 'No claimed sightings',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: sightings.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= sightings.length) {
          // Load more indicator
          if (loadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (hasMore) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 80.0,
                vertical: 10,
              ),
              child: SizedBox(
                child: ModernDarkButton(
                  onPressed: () => _loadMoreSightings(isUnclaimed),
                  text: 'Load More',
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final sighting = sightings[index];
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              sighting.species,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sighting.city ?? 'Unknown location',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (sighting.isTimeClaimed == true)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'CLAIMED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
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
      },
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
                      'Total Volunteer Hours: ${Volunteer.calculateTotalServiceHours(_allUnclaimedSightings).round()} (${Volunteer.calculateTotalServiceHours(_allUnclaimedSightings).toStringAsFixed(2)})',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        // How Hours Are Calculated Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calculate_outlined,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'How Hours Are Calculated',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildCalculationItem(
                                Icons.access_time,
                                'Base Time',
                                '15 minutes per sighting',
                              ),
                              _buildCalculationItem(
                                Icons.lock_outline,
                                'One-Time Claim',
                                'Sightings can only be claimed once. Claim multiple sightings together.',
                              ),
                              _buildCalculationItem(
                                Icons.description_outlined,
                                'Description Bonus',
                                '+5 minutes per 50 characters of detailed observations',
                              ),
                              _buildCalculationItem(
                                Icons.directions_car_outlined,
                                'Travel Time',
                                'Based on distance between consecutive sightings',
                                isLast: true,
                              ),
                              Container(
                                margin: const EdgeInsets.only(left: 32, top: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '• Uses actual GPS coordinates',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      '• Assumes average travel speed of 30 km/h',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      '• Only counts if sightings are within 2 hours',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Tips to Maximize Hours Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tips to Maximize Your Hours',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildTipItem(
                                Icons.edit_outlined,
                                'Write detailed descriptions of your observations',
                              ),
                              _buildTipItem(
                                Icons.timeline_outlined,
                                'Record consecutive sightings when possible',
                              ),
                              _buildTipItem(
                                Icons.nature_outlined,
                                'Include habitat information and behavior notes',
                              ),
                              _buildTipItem(
                                Icons.camera_alt_outlined,
                                'Take clear, well-focused photos',
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                      ],
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
                                    await _submitHours();
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

  Future<void> _submitHours() async {
    try {
      // Check if there are any unclaimed sightings
      if (_allUnclaimedSightings.isEmpty) {
        fToast.showToast(
          child: Util.redToast('You can\'t claim any more hours'),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

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

        // Update isTimeClaimed to true for all unclaimed sightings
        for (Sighting sighting in _allUnclaimedSightings) {
          final updatedSighting = sighting.copyWith(isTimeClaimed: true);
          await Amplify.DataStore.save(updatedSighting);
        }

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

  Widget _buildCalculationItem(
    IconData icon,
    String title,
    String description, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String title, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
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
