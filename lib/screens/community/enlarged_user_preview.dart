import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart'; 

class EnlargedUserPreview extends StatelessWidget {
  final User user;

  const EnlargedUserPreview({Key? key, required this.user}) : super(key: key);

  Widget _buildEnlargedProfilePicture(BuildContext context) {
    final String? picUrl = user.profilePicture;
    // Simplified version of _buildProfilePicture from CommunityScreen
    // Assuming Util.fetchFromS3 is available if picUrl is a S3 key
    // For simplicity, direct NetworkImage if it's a full URL, or placeholder
    if (picUrl != null && picUrl.isNotEmpty) {
      if (picUrl.startsWith('http')) { // Check if it's a full URL
        return CircleAvatar(
          radius: 60,
          backgroundImage: NetworkImage(picUrl),
          backgroundColor: Colors.grey[700],
        );
      } else {
        // Assuming it's an S3 key and Util.fetchFromS3 is available
        // This part might need adjustment based on actual Util.fetchFromS3 implementation
        return FutureBuilder<String?>(
          future: Util.fetchFromS3(picUrl), // Ensure Util is imported and this method exists
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[700],
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF39FF14),
                ),
              );
            }
            if (snapshot.hasData && snapshot.data != null) {
              return CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(snapshot.data!),
                backgroundColor: Colors.grey[700],
              );
            } else {
              return CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[700],
                child: const Icon(Icons.person, size: 60, color: Colors.white70),
              );
            }
          },
        );
      }
    } else {
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey[700],
        child: const Icon(Icons.person, size: 60, color: Colors.white70),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 220, // Adjusted height slightly for better spacing
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _buildEnlargedProfilePicture(context),
          const SizedBox(height: 12),
          Text(
            user.display_username,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            user.school ?? 'No school information',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[300],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
