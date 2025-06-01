/* 
  MapBox and Geolocator need to be imported manually in every file that uses it because they share too many similar names
*/

// Dart
export 'dart:async';
export 'dart:convert';
export 'dart:io';

// Amplify
export 'package:amplify_flutter/amplify_flutter.dart'
    hide BadCertificateCallback, X509Certificate;
export 'package:amplify_api/amplify_api.dart';
export 'package:amplify_datastore/amplify_datastore.dart';
export 'package:amplify_storage_s3/amplify_storage_s3.dart';
export 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
export 'package:amplify_authenticator/amplify_authenticator.dart';

// SightTrack util
export 'package:sighttrack/amplifyconfiguration.dart';
export 'package:sighttrack/models/ModelProvider.dart';
export 'package:sighttrack/models/Sighting.dart';
export 'package:sighttrack/models/UserSettings.dart';
export 'package:sighttrack/util.dart';
export 'package:sighttrack/logging.dart';
export 'package:sighttrack/app.dart';
export 'package:sighttrack/services/geography.dart';
export 'package:sighttrack/math/spatial_autocorrection.dart';
export 'package:sighttrack/services/volunteer.dart';
export 'package:core_ui/core_ui.dart';

// SightTrack main
export 'package:sighttrack/navigation.dart';
export 'package:sighttrack/screens/capture/quick_capture/ac_setup.dart';
export 'package:sighttrack/screens/capture/area_capture/ac_home.dart';
export 'package:sighttrack/screens/capture/capture.dart';
export 'package:sighttrack/screens/capture/choose_capture_type.dart';
export 'package:sighttrack/screens/capture/create_sighting.dart';
export 'package:sighttrack/screens/home/all_sightings.dart';
export 'package:sighttrack/screens/home/home.dart';
export 'package:sighttrack/screens/home/view_sighting.dart';
export 'package:sighttrack/screens/profile/profile.dart';
export 'package:sighttrack/screens/profile/settings.dart';
export 'package:sighttrack/screens/profile/profile_picture.dart';
export 'package:sighttrack/screens/data/data.dart';
export 'package:sighttrack/screens/data/global/global_page.dart';
export 'package:sighttrack/screens/data/local/local_page.dart';
export 'package:sighttrack/screens/community/community.dart';
export 'package:sighttrack/screens/other/user_details.dart';
export 'package:sighttrack/screens/data/global/view_statistics.dart';
export 'package:sighttrack/screens/profile/volunteer_hours.dart';
export 'package:sighttrack/screens/auth/signin.dart';
export 'package:sighttrack/screens/auth/signup.dart';
export 'package:sighttrack/screens/data/global/about_biodiversity.dart';

// Other imports
export 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
export 'package:camera/camera.dart';
export 'package:flutter_dotenv/flutter_dotenv.dart';
export 'package:logging/logging.dart';
export 'package:intl/intl.dart';
export 'package:image_picker/image_picker.dart';
export 'package:fluttertoast/fluttertoast.dart';
export 'package:animated_background/animated_background.dart';
export 'package:geolocator/geolocator.dart';
export 'package:geocoding/geocoding.dart';
export 'providers/theme_provider.dart';
export 'package:provider/provider.dart';
