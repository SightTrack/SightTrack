import 'package:sighttrack/barrel.dart';
import 'package:flutter/material.dart';

class ChangeProfilePictureScreen extends StatefulWidget {
  final User user;
  const ChangeProfilePictureScreen({super.key, required this.user});

  @override
  State<ChangeProfilePictureScreen> createState() =>
      _ChangeProfilePictureScreenState();
}

class _ChangeProfilePictureScreenState
    extends State<ChangeProfilePictureScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  late FToast fToast;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    fToast = FToast();
    fToast.init(context);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveImage() async {
    if (_selectedImage == null) {
      fToast.showToast(
        child: Util.redToast('No changes'),
        gravity: ToastGravity.BOTTOM,
        toastDuration: Duration(seconds: 3),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final String storagePath =
          'profile_pictures/${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final awsFile = AWSFile.fromPath(_selectedImage!.path);

      final uploadResult =
          await Amplify.Storage.uploadFile(
            localFile: awsFile,
            path: StoragePath.fromString(storagePath),
          ).result;
      Log.i('Uploaded file: ${uploadResult.uploadedItem.path}');

      final updatedUser = widget.user.copyWith(profilePicture: storagePath);
      await Amplify.DataStore.save(updatedUser);

      if (!mounted) return;
      Navigator.of(context).pop();
      fToast.showToast(
        child: Util.greenToast('Updated successfully!'),
        gravity: ToastGravity.BOTTOM,
        toastDuration: Duration(seconds: 2),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile picture: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Photo'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  // Profile image section with overlay
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.surfaceContainerHighest,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child:
                              _selectedImage == null &&
                                      widget.user.profilePicture == null
                                  ? Icon(
                                    Icons.person,
                                    size: 80,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  )
                                  : FutureBuilder<String>(
                                    future:
                                        _selectedImage != null
                                            ? Future.value(_selectedImage!.path)
                                            : Util.fetchFromS3(
                                              widget.user.profilePicture!,
                                            ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      if (snapshot.hasError ||
                                          !snapshot.hasData) {
                                        return Icon(
                                          Icons.person,
                                          size: 80,
                                          color:
                                              theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        );
                                      }
                                      return Image(
                                        image:
                                            _selectedImage != null
                                                ? FileImage(_selectedImage!)
                                                : NetworkImage(snapshot.data!)
                                                    as ImageProvider,
                                        fit: BoxFit.cover,
                                        width: 200,
                                        height: 200,
                                      );
                                    },
                                  ),
                        ),
                      ),
                      // Camera overlay button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: theme.colorScheme.onPrimary,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Instructions text
                  Text(
                    'Choose a photo that represents you',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A clear photo will help others recognize you',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Choose Photo'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isUploading ? null : _saveImage,
                          icon:
                              _isUploading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.check),
                          label: Text(_isUploading ? 'Saving...' : 'Save'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Loading overlay
          if (_isUploading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
