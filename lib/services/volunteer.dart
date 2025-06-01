import 'package:sighttrack/barrel.dart';
import 'dart:math';

class Volunteer {
  Volunteer._();

  /// Calculates total service hours for a list of sightings
  /// Takes into account factors like:
  /// - Time between sightings (to account for travel/observation time)
  /// - Description length (more detailed observations take more time)
  /// - Distance between consecutive sightings (travel time)
  static double calculateTotalServiceHours(List<Sighting> sightings) {
    if (sightings.isEmpty) return 0;

    // Sort sightings by timestamp
    final sortedSightings = List<Sighting>.from(sightings)..sort(
      (a, b) => a.timestamp.getDateTimeInUtc().compareTo(
        b.timestamp.getDateTimeInUtc(),
      ),
    );

    double totalHours = 0;

    for (int i = 0; i < sortedSightings.length; i++) {
      final current = sortedSightings[i];

      // Base time for each sighting (15 minutes)
      double sightingHours = 0.25;

      // Add time for detailed descriptions
      if (current.description != null && current.description!.isNotEmpty) {
        // Add 5 minutes for every 50 characters of description
        sightingHours += (current.description!.length / 50) * (5 / 60);
      }

      // If not the first sighting, calculate travel time from previous
      if (i > 0) {
        final previous = sortedSightings[i - 1];

        // Calculate distance between sightings
        final distanceKm = _calculateDistance(
          previous.latitude,
          previous.longitude,
          current.latitude,
          current.longitude,
        );

        // Assume average travel speed of 30 km/h
        final travelHours = distanceKm / 30;

        // Only add travel time if sightings are within 2 hours of each other
        final timeDiff =
            current.timestamp
                .getDateTimeInUtc()
                .difference(previous.timestamp.getDateTimeInUtc())
                .inHours;

        if (timeDiff <= 2) {
          sightingHours += travelHours;
        }
      }

      totalHours += sightingHours;
    }

    return totalHours;
  }

  /// Calculates distance between two points in kilometers using the Haversine formula
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    // Convert latitude and longitude to radians
    final double lat1Rad = lat1 * (pi / 180);
    final double lon1Rad = lon1 * (pi / 180);
    final double lat2Rad = lat2 * (pi / 180);
    final double lon2Rad = lon2 * (pi / 180);

    // Differences in coordinates
    final double dLat = lat2Rad - lat1Rad;
    final double dLon = lon2Rad - lon1Rad;

    // Haversine formula
    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }
}
