import 'package:sighttrack/barrel.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import 'package:flutter/material.dart';

class Util {
  Util._(); // Prevent instantiation

  // static String mapStyle = 'mapbox://styles/jamestt/cm8c8inqm004b01rxat34g28r';
  static String mapStyle =
      'mapbox://styles/jamestt/cm8c8inqm004b01rxat34g28r/draft';

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

  static Future<User> getUserModel() async {
    final currentCognitoUser = await Amplify.Auth.getCurrentUser();
    final userId = currentCognitoUser.userId;

    final users = await Amplify.DataStore.query(
      User.classType,
      where: User.ID.eq(userId),
    );

    return users.first;
  }

  static Future<String> getCognitoUsername() async {
    final currentCognitoUser = await Amplify.Auth.getCurrentUser();
    return currentCognitoUser.username;
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

  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
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

  static Future<String> fetchFromS3(String path) async {
    final result =
        await Amplify.Storage.getUrl(
          path: StoragePath.fromString(path),
          options: const StorageGetUrlOptions(
            pluginOptions: S3GetUrlPluginOptions(
              validateObjectExistence: true,
              expiresIn: Duration(hours: 10),
            ),
          ),
        ).result;
    return result.url.toString();
  }

  static Future<String> getCityName(double latitude, double longitude) async {
    try {
      // Get placemarks from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      // Extract city name (locality) from the first placemark
      Placemark placemark = placemarks.first;
      String? city = placemark.locality;

      return city?.isNotEmpty == true ? city! : 'Unknown city';
    } catch (e) {
      Log.e('getCityName() failed: $e');
      return 'Unknown City';
    }
  }

  static void setupMapbox(mapbox.MapboxMap mapboxMap) async {
    await mapboxMap.logo.updateSettings(mapbox.LogoSettings(enabled: false));
    await mapboxMap.attribution.updateSettings(
      mapbox.AttributionSettings(enabled: false),
    );
    await mapboxMap.scaleBar.updateSettings(
      mapbox.ScaleBarSettings(enabled: false),
    );

    await mapboxMap.location.updateSettings(
      mapbox.LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        puckBearingEnabled: true,
      ),
    );
  }
}
