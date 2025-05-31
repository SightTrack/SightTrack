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

  @override
  void initState() {
    super.initState();
    fToast = FToast();
    fToast.init(context);
  }

  // Opens the gallery for image selection.
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path); // Update the selected image
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully!')),
      );
      Navigator.of(context).pop();
    } on StorageException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('StorageException: ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile picture: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Profile Picture'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[900],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display the selected image, user's current image, or a default icon.
              CircleAvatar(
                radius: 150,
                backgroundColor: Colors.grey,
                child:
                    _selectedImage == null && widget.user.profilePicture == null
                        ? const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        )
                        : FutureBuilder<String>(
                          future:
                              _selectedImage != null
                                  ? Future.value(
                                    _selectedImage!.path,
                                  ) // Use the selected file immediately
                                  : Util.fetchFromS3(
                                    widget.user.profilePicture!,
                                  ), // Get the URL if no file selected
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator(); // Show loading indicator
                            } else if (snapshot.hasError || !snapshot.hasData) {
                              return const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              );
                            } else {
                              return CircleAvatar(
                                radius: 150,
                                backgroundColor: Colors.grey,
                                backgroundImage:
                                    _selectedImage != null
                                        ? FileImage(
                                          _selectedImage!,
                                        ) // Show the selected image
                                        : NetworkImage(snapshot.data!)
                                            as ImageProvider<
                                              Object
                                            >?, // Show the fetched image
                              );
                            }
                          },
                        ),
              ),
              const SizedBox(height: 40),
              ModernDarkButton(text: 'Pick Image', onPressed: _pickImage),
              const SizedBox(height: 20),
              ModernDarkButton(text: 'Save Image', onPressed: _saveImage),
            ],
          ),
        ),
      ),
    );
  }
}
