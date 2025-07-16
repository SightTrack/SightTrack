import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';
import 'package:intl/intl.dart';

class EditSightingScreen extends StatefulWidget {
  final Sighting sighting;

  const EditSightingScreen({super.key, required this.sighting});

  @override
  State<EditSightingScreen> createState() => _EditSightingScreenState();
}

class _EditSightingScreenState extends State<EditSightingScreen> {
  late TextEditingController _descriptionController;
  late DateTime _selectedDateTime;
  bool _isLoading = false;
  bool _isLocationExpanded = false;
  bool _isTechnicalExpanded = false;
  late Future<String> _photoUrlFuture;
  FToast? toast;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.sighting.description ?? '',
    );
    _selectedDateTime = widget.sighting.timestamp.getDateTimeInUtc().toLocal();
    _photoUrlFuture = Util.fetchFromS3(widget.sighting.photo);
    toast = FToast();
    toast!.init(context);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedSighting = widget.sighting.copyWith(
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        timestamp: TemporalDateTime.fromString(
          _selectedDateTime.toUtc().toIso8601String(),
        ),
      );

      await Amplify.DataStore.save(updatedSighting);

      if (mounted) {
        toast?.showToast(
          child: Util.greenToast('Sighting updated successfully'),
          toastDuration: const Duration(seconds: 2),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      Log.e('Error updating sighting: $e');
      if (mounted) {
        toast?.showToast(
          child: Util.redToast('Failed to update sighting'),
          toastDuration: const Duration(seconds: 2),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSighting() async {
    try {
      await Amplify.DataStore.delete(widget.sighting);
      Log.i('DELETE: Sighting ${widget.sighting.id}');
      if (mounted) {
        toast?.showToast(
          child: Util.greenToast('Sighting deleted successfully'),
          toastDuration: const Duration(seconds: 2),
        );
        Navigator.pop(context, true); // Return true to indicate deletion
      }
    } catch (e) {
      Log.e('Error deleting sighting: $e');
      if (mounted) {
        toast?.showToast(
          child: Util.redToast('Failed to delete sighting'),
          toastDuration: const Duration(seconds: 2),
        );
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Delete Sighting',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Sighting'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, size: 26, color: Colors.red),
            tooltip: 'Delete Sighting',
            onPressed: _showDeleteDialog,
          ),
          IconButton(
            icon:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.check, size: 26, color: Colors.green),
            tooltip: 'Save Changes',
            onPressed: _isLoading ? null : _saveChanges,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description (Editable)
            _buildEditableSection(
              'Description',
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add a description...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            if (widget.sighting.user != null)
              _buildSection('User', widget.sighting.user!.display_username),

            // Photo (Non-editable)
            FutureBuilder<String>(
              future: _photoUrlFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Center(
                      child: Icon(Icons.image, size: 80, color: Colors.grey),
                    ),
                  );
                } else if (snapshot.hasError || snapshot.data == null) {
                  return Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Center(
                      child: Icon(Icons.image, size: 80, color: Colors.grey),
                    ),
                  );
                } else {
                  return GestureDetector(
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        barrierDismissible: true,
                        builder: (BuildContext context) {
                          return Dialog(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            insetPadding: const EdgeInsets.all(16),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.9,
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.9,
                              ),
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Image.network(
                                    snapshot.data!,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black54,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        image: DecorationImage(
                          image: NetworkImage(snapshot.data!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 20),

            // Species (Non-editable)
            _buildSection('Species', widget.sighting.species),

            // Timestamp (Editable)
            _buildEditableSection(
              'Timestamp',
              GestureDetector(
                onTap: _selectDateTime,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          DateFormat(
                            'MMMM dd, yyyy HH:mm',
                          ).format(_selectedDateTime),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
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
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info, size: 16),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              'Location may have been offset due to user\'s privacy settings',
                              style: Theme.of(context).textTheme.labelMedium,
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
                      if (widget.sighting.city != null)
                        _buildDetailRow('City', widget.sighting.city!),
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
              children: [
                Align(
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

            const SizedBox(height: 100),
          ],
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

  Widget _buildEditableSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        child,
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
}
