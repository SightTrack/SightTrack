import 'package:sighttrack/barrel.dart';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void updateDependentFields(UserSettings settings) async {
  try {
    final updatedSettings = settings.copyWith(isAreaCaptureActive: false);

    if (updatedSettings == settings) {
      return;
    }

    await Amplify.DataStore.save(updatedSettings);
    print('Settings updated: ${updatedSettings.toJson()}');
  } catch (e) {
    print('Update dependent fields failed: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Log.init();

  await dotenv.load();
  MapboxOptions.setAccessToken(dotenv.env['MAPBOX_TOKEN']!);

  try {
    // DataStore needs to be added first
    await Amplify.addPlugins([
      AmplifyDataStore(modelProvider: ModelProvider.instance),
      AmplifyAPI(),
      AmplifyAuthCognito(),
      AmplifyStorageS3(),
    ]);

    await Amplify.configure(amplifyconfig);
    // await Amplify.DataStore.clear();
    await Amplify.DataStore.start();

    // Validate and update UserSettings (check if Area Capture mode is activated when not supposed to)
    Amplify.DataStore.observe(UserSettings.classType).listen((event) async {
      final settings = event.item;
      print('UserSettings observer triggered: ${settings.toJson()}');

      if (settings.isAreaCaptureActive == false) {
        return;
      }
      if (settings.isAreaCaptureActive == false ||
          (settings.areaCaptureEnd != null &&
              settings.areaCaptureEnd!.getDateTimeInUtc().isBefore(
                DateTime.now(),
              ))) {
        updateDependentFields(settings);
      }
    });

    // Check for user auth status
    Amplify.Hub.listen(HubChannel.Auth, (hubEvent) async {
      if (hubEvent.eventName == 'SIGNED_IN') {
        Log.i('Event: SIGNED_IN - Waiting for DataStore sync');

        // Wait for the initial sync to complete
        bool isSynced = false;
        final syncSubscription = Amplify.DataStore.observe(
          User.classType,
        ).listen((event) {
          Log.i('Sync received for user: ${event.item.id}');
          isSynced = true;
        });

        // Wait up to 10 seconds for sync to occur
        for (int i = 0; i < 20; i++) {
          if (isSynced) break;
          await Future.delayed(const Duration(milliseconds: 500));
        }
        syncSubscription.cancel();

        final currentUser = await Amplify.Auth.getCurrentUser();
        final userId = currentUser.userId;

        final existingUsers = await Amplify.DataStore.query(
          User.classType,
          where: User.ID.eq(userId),
        );

        if (existingUsers.isEmpty) {
          final attributes = await Amplify.Auth.fetchUserAttributes();
          String email = '';
          for (var attribute in attributes) {
            if (attribute.userAttributeKey.toString().toLowerCase() ==
                'email') {
              email = attribute.value;
              break;
            }
          }

          final newUser = User(
            id: userId,
            display_username: currentUser.username,
            email: email,
            profilePicture: null,
            bio: '',
            country: '',
          );

          await Amplify.DataStore.save(newUser);
          Log.i('New user record created for ${currentUser.username}');
        } else {
          Log.i('User record exists: ${existingUsers.first.toJson()}');
        }
      } else if (hubEvent.eventName == 'SIGNED_OUT') {
        Log.i('Event: SIGNED_OUT - Clearing DataStore');
        await Amplify.DataStore.clear();
      }
    });
  } catch (e) {
    Log.e('Error in main(): $e');
  }
  runApp(const App());
}
