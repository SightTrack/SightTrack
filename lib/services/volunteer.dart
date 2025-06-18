import 'package:sighttrack/barrel.dart';
import 'dart:math';
import 'dart:convert';

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

  static Future<List<String>> getActivitySupervisors() async {
    User user = await Util.getUserModel();
    String userId = user.id;

    final existingSettings = await Amplify.DataStore.query(
      UserSettings.classType,
      where: UserSettings.USERID.eq(userId),
    );

    if (existingSettings.isEmpty) {
      return [];
    }

    return existingSettings.first.activitySupervisor ?? [];
  }

  static Future<List<String>> getSchoolSupervisors() async {
    User user = await Util.getUserModel();
    String userId = user.id;

    final existingSettings = await Amplify.DataStore.query(
      UserSettings.classType,
      where: UserSettings.USERID.eq(userId),
    );

    if (existingSettings.isEmpty) {
      return [];
    }

    return existingSettings.first.schoolSupervisor ?? [];
  }

  static Future<void> initiateVolunteerHoursRequest(
    String activitySupervisor,
    String schoolSupervisor,
    List<Sighting> sightings,
    User user,
  ) async {
    try {
      // Calculate total hours
      final totalHours = calculateTotalServiceHours(sightings);

      // Sort sightings by timestamp for date range calculation
      final sortedSightings = List<Sighting>.from(sightings)..sort(
        (a, b) => a.timestamp.getDateTimeInUtc().compareTo(
          b.timestamp.getDateTimeInUtc(),
        ),
      );

      // Calculate date range
      String dateRange = '';
      if (sortedSightings.isNotEmpty) {
        final startDate = sortedSightings.first.timestamp.getDateTimeInUtc();
        final endDate = sortedSightings.last.timestamp.getDateTimeInUtc();
        final formatter = DateFormat('MMM d, yyyy');

        if (startDate.day == endDate.day &&
            startDate.month == endDate.month &&
            startDate.year == endDate.year) {
          dateRange = formatter.format(startDate);
        } else {
          dateRange =
              '${formatter.format(startDate)} - ${formatter.format(endDate)}';
        }
      }

      // Get unique locations
      final locations =
          sightings
              .where((s) => s.city != null && s.city!.isNotEmpty)
              .map((s) => s.city!)
              .toSet()
              .toList();
      final locationsSummary = locations.join(', ');

      // Get unique species count
      final uniqueSpecies = sightings.map((s) => s.species).toSet();
      final speciesCount = uniqueSpecies.length;

      // Format sightings for template
      final formattedSightings =
          sightings.map((sighting) {
            final dateTime = sighting.timestamp.getDateTimeInUtc().toLocal();
            return {
              'species': sighting.species,
              'city': sighting.city ?? 'Unknown location',
              'date': DateFormat('MMM d, yyyy').format(dateTime),
              'time': DateFormat('HH:mm').format(dateTime),
              'description': sighting.description ?? 'No description provided',
            };
          }).toList();

      // Create the data blob for the email template
      final Map<String, dynamic> dataBlob = {
        // Volunteer information
        'volunteer_name': user.realName,
        'volunteer_email': user.email,
        'student_id': user.studentId,
        'school_name': user.school,
        'submission_date': DateFormat('MMM d, yyyy').format(DateTime.now()),

        // Sightings summary
        'total_sightings': sightings.length,
        'total_hours': totalHours.toStringAsFixed(2),
        'date_range': dateRange,
        'locations_summary':
            locationsSummary.isNotEmpty
                ? locationsSummary
                : 'Various locations',
        'species_count': speciesCount,
        'sightings': formattedSightings,

        // Calculation constants (matching the values used in calculateTotalServiceHours)
        'base_time_per_sighting': 15, // 15 minutes
        'description_bonus_per_chars': 5, // 5 minutes bonus
        'description_char_threshold': 50, // per 50 characters
        'average_travel_speed': 30, // 30 km/h
        'time_window_hours': 2, // 2 hours
        // Supervisor information
        'activity_supervisor': activitySupervisor,
        'school_supervisor': schoolSupervisor,
      };

      // Call the Lambda function via API Gateway
      final response =
          await Amplify.API
              .post(
                '/sendVolunteerHours',
                body: HttpPayload.json(dataBlob),
                headers: {'Content-Type': 'application/json'},
              )
              .response;

      // Check if the response was successful
      if (response.statusCode == 200) {
        Log.i('Volunteer hours request sent successfully');
      } else {
        Log.e(
          'Failed to send volunteer hours request. Status: ${response.statusCode}',
        );
        throw Exception('Failed to send volunteer hours request');
      }
    } catch (e) {
      Log.e('Error in initiateVolunteerHoursRequest: $e');
      rethrow;
    }
  }
}
