import 'package:sighttrack/barrel.dart';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class Util {
  Util._();

  static Widget greenToast(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Colors.greenAccent,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(Icons.check), SizedBox(width: 12.0), Text(text)],
      ),
    );
  }

  static Widget redToast(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Colors.redAccent,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(Icons.error), SizedBox(width: 12.0), Text(text)],
      ),
    );
  }

  static Future<UserSettings?> getUserSettings() async {
    try {
      final currentUser = await Amplify.Auth.getCurrentUser();
      final userId = currentUser.userId;

      final users = await Amplify.DataStore.query(
        User.classType,
        where: User.ID.eq(userId),
      );

      if (users.isEmpty) {
        return null; // No user found
      }

      final user = users.first;
      final settings = await Amplify.DataStore.query(
        UserSettings.classType,
        where: UserSettings.USERID.eq(user.id),
      );

      return settings.isNotEmpty ? settings.first : null;
    } catch (e) {
      Log.e('Util.getUserSettings(): $e');
      return null;
    }
  }

  static Future<bool> isAdmin() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session is CognitoAuthSession) {
        final idToken = session.userPoolTokensResult.value.idToken.raw;
        final tokenParts = idToken.toString().split('.');
        if (tokenParts.length != 3) {
          Log.e('isAdmin(): Invalid JWT format');
          return false;
        }
        final payload = base64Url.decode(base64Url.normalize(tokenParts[1]));
        final claims = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
        final groups = claims['cognito:groups'] as List<dynamic>?;
        return groups?.contains('Admin') ?? false;
      } else {
        Log.e('Session is not a CognitoAuthSession');
      }
      return false;
    } catch (e) {
      Log.e('Error checking admin status: $e');
      return false;
    }
  }

  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.best),
      );
    } catch (e) {
      Log.e('Error getting location: $e');
      return null;
    }
  }

  static Future<List<String>> doAWSRekognitionCall(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final requestBody = jsonEncode({'image': base64Image});

      final response =
          await Amplify.API
              .post(
                '/analyze',
                body: HttpPayload.json(requestBody),
                headers: {'Content-Type': 'application/json'},
              )
              .response;

      final responseBody = jsonDecode(response.decodeBody());
      final labels =
          (responseBody['labels'] as List)
              .map((label) => label['Name'] as String)
              .toList();

      Log.i('Lambda response: $labels');
      return labels;
    } on ApiException catch (e) {
      Log.e('API call to /analyze failed (method: POST): $e');
      return [];
    } catch (e) {
      Log.e('Unexpected error in Lambda invocation: $e');
      return [];
    }
  }
}
