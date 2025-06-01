import 'package:sighttrack/barrel.dart';

class Geography {
  Geography._();

  // Builds the Sighting model database by filling nullable field `city` from each coordinates
  static Future<void> setCityNameForAllSightings() async {
    try {
      final sightings = await Amplify.DataStore.query(Sighting.classType);

      for (final sighting in sightings) {
        if (sighting.city != null && sighting.city!.isNotEmpty) {
          continue;
        }

        try {
          final city = await Util.getCityName(
            sighting.latitude,
            sighting.longitude,
          );

          if (city != 'Unknown City') {
            final updatedSighting = sighting.copyWith(city: city);
            await Amplify.DataStore.save(updatedSighting);
            print('Updated sighting ${sighting.id} with city: $city');
          } else {
            print('No valid city found for sighting ${sighting.id}');
          }
        } catch (e) {
          print('Error processing sighting ${sighting.id}: $e');
        }
      }
    } catch (e) {
      print('Error querying sightings: $e');
    }
  }
}
