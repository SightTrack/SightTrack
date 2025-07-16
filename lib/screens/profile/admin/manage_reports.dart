import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';

class ManageReportsScreen extends StatefulWidget {
  const ManageReportsScreen({super.key});

  @override
  State<ManageReportsScreen> createState() => _ManageReportsScreenState();
}

class _ManageReportsScreenState extends State<ManageReportsScreen> {
  bool _isLoading = true;
  List<Report> _reports = [];
  List<Report> _filteredReports = [];

  // Cache for related data to avoid repeated queries
  final Map<String, Sighting> _sightingsCache = {};
  final Map<String, User> _usersCache = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      setState(() => _isLoading = true);

      // Load all reports
      final reports = await Amplify.DataStore.query(Report.classType);

      // Sort by timestamp (newest first)
      reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Pre-load related data
      await _preloadRelatedData(reports);

      setState(() {
        _reports = reports;
        _filteredReports = reports;
        _isLoading = false;
      });
    } catch (e) {
      Log.e('Error loading reports: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error loading reports')));
      }
    }
  }

  Future<void> _preloadRelatedData(List<Report> reports) async {
    try {
      // Get all sightings and users to cache them
      final sightings = await Amplify.DataStore.query(Sighting.classType);
      final users = await Amplify.DataStore.query(User.classType);

      // Build cache maps
      for (final sighting in sightings) {
        _sightingsCache[sighting.id] = sighting;
      }

      for (final user in users) {
        _usersCache[user.id] = user;
      }
    } catch (e) {
      Log.e('Error preloading related data: $e');
    }
  }

  Future<void> _removeSighting(Report report) async {
    try {
      List<Sighting> temp = await Amplify.DataStore.query(
        Sighting.classType,
        where: Sighting.ID.eq(report.reportReportedSightingId),
      );

      await Amplify.DataStore.delete(temp.first);
      Log.i('Sighting deleted');

      await Amplify.DataStore.delete(report);

      await _loadReports();
      setState(() {});
    } catch (e) {
      Log.e('Error removing sighting: $e');
    }
  }

  Future<void> _updateReportStatus(
    Report report,
    ReportStatus newStatus,
  ) async {
    try {
      final updatedReport = report.copyWith(status: newStatus);
      await Amplify.DataStore.save(updatedReport);

      // Update local cache
      final index = _reports.indexWhere((r) => r.id == report.id);
      if (index != -1) {
        _reports[index] = updatedReport;
      }

      _loadReports();
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Report status updated to ${_getStatusDisplayName(newStatus)}',
            ),
          ),
        );
      }
    } catch (e) {
      Log.e('Error updating report status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating report status')),
        );
      }
    }
  }

  Future<void> _updateAdminNotes(Report report, String notes) async {
    try {
      final updatedReport = report.copyWith(adminNotes: notes);
      await Amplify.DataStore.save(updatedReport);

      // Update local cache
      final index = _reports.indexWhere((r) => r.id == report.id);
      if (index != -1) {
        _reports[index] = updatedReport;
      }

      _loadReports();
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Admin notes updated')));
      }
    } catch (e) {
      Log.e('Error updating admin notes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating admin notes')),
        );
      }
    }
  }

  void _showReportDetails(Report report) {
    final sighting = _sightingsCache[report.reportReportedSightingId];
    final reporter = _usersCache[report.reportReporterId];

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Text(
                        'Report Details',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Report Info
                          _buildInfoCard('Report Information', [
                            _buildInfoRow('Report ID', report.id),
                            _buildInfoRow(
                              'Submitted',
                              DateFormat(
                                'MMM dd, yyyy HH:mm',
                              ).format(report.timestamp.getDateTimeInUtc()),
                            ),
                            _buildInfoRow(
                              'Status',
                              _getStatusDisplayName(report.status),
                            ),
                            _buildInfoRow('Reasons', report.reasonsString),
                          ]),
                          const SizedBox(height: 16),

                          // Reporter Info
                          _buildInfoCard('Reporter Information', [
                            _buildInfoRow(
                              'Username',
                              reporter?.display_username ?? 'Unknown',
                            ),
                            _buildInfoRow(
                              'Email',
                              reporter?.email ?? 'Unknown',
                            ),
                            _buildInfoRow(
                              'Country',
                              reporter?.country ?? 'Not provided',
                            ),
                          ]),
                          const SizedBox(height: 16),

                          // Sighting Info
                          _buildInfoCard('Reported Sighting', [
                            _buildInfoRow(
                              'Species',
                              sighting?.species ?? 'Unknown',
                            ),
                            _buildInfoRow(
                              'Location',
                              sighting?.city ?? 'Unknown',
                            ),
                            _buildInfoRow(
                              'Date',
                              sighting != null
                                  ? DateFormat('MMM dd, yyyy HH:mm').format(
                                    sighting.timestamp.getDateTimeInUtc(),
                                  )
                                  : 'Unknown',
                            ),
                            _buildInfoRow(
                              'Description',
                              sighting?.description ?? 'No description',
                            ),
                          ]),
                          const SizedBox(height: 16),

                          // Admin Notes
                          _buildAdminNotesSection(report),
                          const SizedBox(height: 16),

                          // Actions
                          _buildActionsSection(report),

                          DarkButton(
                            text: 'Remove Sighting',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('Remove Sighting'),
                                      content: const Text(
                                        'Are you sure you want to remove this sighting?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            _removeSighting(report);
                                            Navigator.pop(context);
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildAdminNotesSection(Report report) {
    final notesController = TextEditingController(
      text: report.adminNotes ?? '',
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Add your notes here...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                _updateAdminNotes(report, notesController.text);
                Navigator.pop(context);
              },
              child: const Text('Save Notes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection(Report report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children:
                  ReportStatus.values.map((status) {
                    return ElevatedButton(
                      onPressed:
                          report.status == status
                              ? null
                              : () {
                                _updateReportStatus(report, status);
                                Navigator.pop(context);
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            report.status == status
                                ? Colors.grey
                                : _getStatusColor(status),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_getStatusDisplayName(status)),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusDisplayName(ReportStatus status) {
    switch (status) {
      case ReportStatus.PENDING:
        return 'Pending';
      case ReportStatus.UNDER_REVIEW:
        return 'Under Review';
      case ReportStatus.RESOLVED:
        return 'Resolved';
      case ReportStatus.DISMISSED:
        return 'Dismissed';
    }
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.PENDING:
        return Colors.orange;
      case ReportStatus.UNDER_REVIEW:
        return Colors.blue;
      case ReportStatus.RESOLVED:
        return Colors.green;
      case ReportStatus.DISMISSED:
        return Colors.red;
    }
  }

  Widget _buildStatusChip(ReportStatus status) {
    return Chip(
      label: Text(
        _getStatusDisplayName(status),
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      backgroundColor: _getStatusColor(status),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Header and Controls
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Manage Reports',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text('${_filteredReports.length} reports'),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // Reports List
        Expanded(
          child:
              _filteredReports.isEmpty
                  ? const Center(child: Text('No reports found'))
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredReports.length,
                    itemBuilder: (context, index) {
                      final report = _filteredReports[index];
                      final sighting =
                          _sightingsCache[report.reportReportedSightingId];
                      final reporter = _usersCache[report.reportReporterId];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.report,
                            color: _getStatusColor(report.status),
                            size: 32,
                          ),
                          title: Text(
                            sighting?.species ?? 'Unknown Species',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(reporter?.display_username ?? 'Unknown'),
                              const SizedBox(height: 8),
                              // Status chip and menu below the text
                              Row(
                                children: [
                                  _buildStatusChip(report.status),
                                  const Spacer(),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'view':
                                          _showReportDetails(report);
                                          break;
                                        case 'pending':
                                          _updateReportStatus(
                                            report,
                                            ReportStatus.PENDING,
                                          );
                                          break;
                                        case 'review':
                                          _updateReportStatus(
                                            report,
                                            ReportStatus.UNDER_REVIEW,
                                          );
                                          break;
                                        case 'resolved':
                                          _updateReportStatus(
                                            report,
                                            ReportStatus.RESOLVED,
                                          );
                                          break;
                                        case 'dismissed':
                                          _updateReportStatus(
                                            report,
                                            ReportStatus.DISMISSED,
                                          );
                                          break;
                                      }
                                    },
                                    itemBuilder:
                                        (context) => [
                                          const PopupMenuItem(
                                            value: 'view',
                                            child: Row(
                                              children: [
                                                Icon(Icons.visibility),
                                                SizedBox(width: 8),
                                                Text('View Details'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuDivider(),
                                          const PopupMenuItem(
                                            value: 'pending',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.pending,
                                                  color: Colors.orange,
                                                ),
                                                SizedBox(width: 8),
                                                Text('Mark Pending'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'review',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.rate_review,
                                                  color: Colors.blue,
                                                ),
                                                SizedBox(width: 8),
                                                Text('Under Review'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'resolved',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green,
                                                ),
                                                SizedBox(width: 8),
                                                Text('Mark Resolved'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'dismissed',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.cancel,
                                                  color: Colors.red,
                                                ),
                                                SizedBox(width: 8),
                                                Text('Dismiss'),
                                              ],
                                            ),
                                          ),
                                        ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () => _showReportDetails(report),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
