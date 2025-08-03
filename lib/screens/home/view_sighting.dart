import 'package:sighttrack/barrel.dart';
import 'package:core_ui/core_ui.dart';

import 'package:flutter/material.dart';

class ViewSightingScreen extends StatefulWidget {
  final Sighting sighting;

  const ViewSightingScreen({super.key, required this.sighting});

  @override
  State<ViewSightingScreen> createState() => _ViewSightingScreenState();
}

class _ViewSightingScreenState extends State<ViewSightingScreen> {
  bool _isLocationExpanded = false;
  bool _isTechnicalExpanded = false;
  late Future<String> _photoUrlFuture; // Cache the future
  bool? isAdminUser;
  FToast? toast;

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await Util.isAdmin();
      setState(() {
        isAdminUser = isAdmin;
      });
    } catch (e) {
      Log.e('Error checking admin status: $e');
      setState(() {
        isAdminUser = false;
      });
    }
  }

  Future<void> _deleteSighting() async {
    try {
      await Amplify.DataStore.delete(widget.sighting);
      Log.i('DELETE: Sighting ${widget.sighting.id}');
      if (mounted) {
        Navigator.pop(context); // Go back after deletion
      }
    } catch (e) {
      Log.e('Error deleting sighting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete sighting: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _photoUrlFuture = Util.fetchFromS3(widget.sighting.photo);
    _checkAdminStatus();
    toast = FToast();
    toast!.init(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sighting Details'),
        actions: [
          IconButton(
            tooltip: 'Report',
            icon: const Icon(Icons.flag, size: 26, color: Colors.deepOrange),
            onPressed: () {
              _showReportDialog(context);
            },
          ),
          if (isAdminUser == true) // Show delete button only for admins
            IconButton(
              icon: const Icon(Icons.delete, size: 26, color: Colors.red),
              tooltip: 'Delete Sighting',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: const Text(
                        'Delete Sighting',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: const Text(
                        'Are you sure you want to delete this sighting? This action cannot be undone.',
                        style: TextStyle(fontSize: 16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 15, color: Colors.grey),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop(); // Close dialog
                            await _deleteSighting();
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _photoUrlFuture = Util.fetchFromS3(widget.sighting.photo);
          });
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.sighting.description != null &&
                  widget.sighting.description!.isNotEmpty)
                _buildSection('Description', widget.sighting.description!),

              if (widget.sighting.user != null)
                _buildClickableUserSection(widget.sighting.user!),

              ExpandableNetworkImage(
                imageUrlFuture: _photoUrlFuture,
                width: double.infinity,
                height: 250,
              ),

              const SizedBox(height: 20),
              _buildSection('Species', widget.sighting.species),
              _buildSection(
                'Timestamp',
                DateFormat('MMMM dd, yyyy HH:mm').format(
                  widget.sighting.timestamp.getDateTimeInUtc().toLocal(),
                ),
              ),

              ExpansionTile(
                title: Text(
                  'Location Details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                initiallyExpanded: _isLocationExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _isLocationExpanded = expanded;
                  });
                },
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                shape: const Border(),
                collapsedShape: const Border(),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, size: 16),
                            const SizedBox(width: 15),
                            Expanded(
                              child: AutoSizeText(
                                'Location may have been offset due to user\'s privacy settings',
                                style: Theme.of(context).textTheme.labelMedium,
                                maxLines: 5,
                                wrapWords: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildDetailRow(
                          'Latitude',
                          '${widget.sighting.latitude}',
                        ),
                        _buildDetailRow(
                          'Longitude',
                          '${widget.sighting.longitude}',
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),

              ExpansionTile(
                title: Text(
                  'Technical Details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                initiallyExpanded: _isTechnicalExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _isTechnicalExpanded = expanded;
                  });
                },
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                shape: const Border(),
                collapsedShape: const Border(),
                children: [
                  Align(
                    // Wrap the Column in an Align widget
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTechnicalDetailRow(
                            'Sighting ID',
                            widget.sighting.id,
                          ),
                          if (widget.sighting.user != null)
                            _buildTechnicalDetailRow(
                              'User ID',
                              widget.sighting.user!.id,
                            ),
                          _buildTechnicalDetailRow(
                            'Photo URL',
                            widget.sighting.photo,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(content, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildClickableUserSection(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('User', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => UserDetailScreen(user: user),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              user.display_username,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.labelLarge,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          Text(value, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    // Define state variables outside the builder to persist across rebuilds
    bool inappropriateContent = false;
    bool incorrectSpecies = false;
    bool spam = false;
    bool other = false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                'Report Sighting',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Please select a reason for reporting this sighting.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Inappropriate content'),
                    value: inappropriateContent,
                    onChanged:
                        isSubmitting
                            ? null
                            : (bool? value) {
                              setState(() {
                                inappropriateContent = value ?? false;
                              });
                            },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('Incorrect species identification'),
                    value: incorrectSpecies,
                    onChanged:
                        isSubmitting
                            ? null
                            : (bool? value) {
                              setState(() {
                                incorrectSpecies = value ?? false;
                              });
                            },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('Spam'),
                    value: spam,
                    onChanged:
                        isSubmitting
                            ? null
                            : (bool? value) {
                              setState(() {
                                spam = value ?? false;
                              });
                            },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('Other'),
                    value: other,
                    onChanged:
                        isSubmitting
                            ? null
                            : (bool? value) {
                              setState(() {
                                other = value ?? false;
                              });
                            },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed:
                      isSubmitting
                          ? null
                          : () async {
                            // Check if at least one reason is selected
                            if (!inappropriateContent &&
                                !incorrectSpecies &&
                                !spam &&
                                !other) {
                              toast!.showToast(
                                child: Util.redToast(
                                  'Please select at least one reason for \nreporting.',
                                ),
                              );
                              return;
                            }

                            setState(() {
                              isSubmitting = true;
                            });

                            try {
                              await _submitReport(
                                inappropriateContent: inappropriateContent,
                                incorrectSpecies: incorrectSpecies,
                                spam: spam,
                                other: other,
                              );

                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }

                              if (context.mounted) {
                                toast?.showToast(
                                  child: Util.greenToast(
                                    'Report submitted successfully. Thank you \nfor helping keep our community safe',
                                  ),
                                  toastDuration: const Duration(seconds: 3),
                                );
                              }
                            } catch (e) {
                              setState(() {
                                isSubmitting = false;
                              });

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to submit report: ${e.toString()}',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                  child:
                      isSubmitting
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text(
                            'Submit Report',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitReport({
    required bool inappropriateContent,
    required bool incorrectSpecies,
    required bool spam,
    required bool other,
  }) async {
    try {
      // Collect selected reasons
      List<String> reasons = [];
      if (inappropriateContent) reasons.add('Inappropriate content');
      if (incorrectSpecies) reasons.add('Incorrect species identification');
      if (spam) reasons.add('Spam');
      if (other) reasons.add('Other');

      // Get current user
      User reporter = await Util.getUserModel();

      Log.i('Reporter: ');

      // Create report object with proper foreign key IDs for @hasOne relationships
      final report = Report(
        timestamp: TemporalDateTime.now(),
        reasons: reasons,
        reasonsString: reasons.join(', '),
        status: ReportStatus.PENDING,
        reportReportedSightingId: widget.sighting.id,
        reportReporterId: reporter.id,
      );

      Log.i('Report: $report');

      // Save the report to DataStore
      await Amplify.DataStore.save(report);
    } catch (e) {
      Log.e('Error submitting report: $e');
      rethrow;
    }
  }
}
