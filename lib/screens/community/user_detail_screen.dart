import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart'; // Assuming User model is here

class UserDetailScreen extends StatelessWidget {
  final User user;

  const UserDetailScreen({Key? key, required this.user}) : super(key: key);

  Widget _buildProfilePicture(BuildContext context) {
    final String? picUrl = user.profilePicture;

    if (picUrl != null && picUrl.isNotEmpty) {
      // Check if it's a full URL or an S3 key (similar to EnlargedUserPreview)
      if (picUrl.startsWith('http')) {
        return CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(picUrl),
          backgroundColor: Colors.grey[700],
        );
      } else {
        // Assuming it's an S3 key and Util.fetchFromS3 is available
        return FutureBuilder<String?>(
          future: Util.fetchFromS3(picUrl), // Ensure Util is imported and this method exists
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[700],
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF39FF14), // Accent color for loading
                ),
              );
            }
            if (snapshot.hasData && snapshot.data != null) {
              return CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(snapshot.data!),
                backgroundColor: Colors.grey[700],
              );
            } else {
              // Error or no data, show placeholder
              return CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[700],
                child: const Icon(Icons.person, size: 50, color: Colors.white70),
              );
            }
          },
        );
      }
    } else {
      // No profile picture URL, show placeholder
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[700],
        child: const Icon(Icons.person, size: 50, color: Colors.white70),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // Dark theme background
      appBar: AppBar(
        backgroundColor: Colors.grey[900], // Dark theme AppBar
        elevation: 0, // Remove shadow for a flatter look
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'User Details',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _buildProfilePicture(context),
              SizedBox(height: 20),
              Text(
                user.display_username,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                user.school ?? 'No school information',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              // Add more user details widgets here
            ],
          ),
        ),
      ),
    );
  }
}
