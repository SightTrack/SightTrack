import 'package:sighttrack/barrel.dart';
import 'dart:math' as math;

/// Utility class for calculating comprehensive statistics on User and Sighting models
class Statistics {
  Statistics._();

  /// Returns a comprehensive statistics data blob for both users and sightings
  static Future<Map<String, dynamic>> getAllStatistics() async {
    final users = await _getAllUsers();
    final sightings = await _getAllSightings();

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'userStatistics': _calculateUserStatistics(users),
      'sightingStatistics': _calculateSightingStatistics(sightings),
      'combinedStatistics': _calculateCombinedStatistics(users, sightings),
    };
  }

  /// Get all users from the database
  static Future<List<User>> _getAllUsers() async {
    try {
      return await Amplify.DataStore.query(User.classType);
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  /// Get all sightings from the database
  static Future<List<Sighting>> _getAllSightings() async {
    try {
      return await Amplify.DataStore.query(Sighting.classType);
    } catch (e) {
      print('Error fetching sightings: $e');
      return [];
    }
  }

  /// Calculate comprehensive user statistics
  static Map<String, dynamic> _calculateUserStatistics(List<User> users) {
    if (users.isEmpty) {
      return {
        'totalUsers': 0,
        'demographics': {},
        'engagement': {},
        'temporal': {},
      };
    }

    // Basic counts
    final totalUsers = users.length;
    final usersWithBios =
        users.where((u) => u.bio != null && u.bio!.isNotEmpty).length;
    final usersWithProfilePictures =
        users
            .where(
              (u) => u.profilePicture != null && u.profilePicture!.isNotEmpty,
            )
            .length;
    final usersWithSchools =
        users.where((u) => u.school != null && u.school!.isNotEmpty).length;

    // Demographics
    final countryDistribution = <String, int>{};
    final ageDistribution = <String, int>{};
    final schoolDistribution = <String, int>{};

    for (final user in users) {
      // Country distribution
      final country = user.country ?? 'Unknown';
      countryDistribution[country] = (countryDistribution[country] ?? 0) + 1;

      // Age distribution
      if (user.age != null) {
        final ageGroup = _getAgeGroup(user.age!);
        ageDistribution[ageGroup] = (ageDistribution[ageGroup] ?? 0) + 1;
      }

      // School distribution
      if (user.school != null && user.school!.isNotEmpty) {
        schoolDistribution[user.school!] =
            (schoolDistribution[user.school!] ?? 0) + 1;
      }
    }

    // Temporal analysis
    final usersByMonth = <String, int>{};
    final now = DateTime.now();
    final activeUsers30Days =
        users
            .where(
              (u) =>
                  u.updatedAt != null &&
                  now.difference(u.updatedAt!.getDateTimeInUtc()).inDays <= 30,
            )
            .length;

    for (final user in users) {
      if (user.createdAt != null) {
        final monthKey = DateFormat(
          'yyyy-MM',
        ).format(user.createdAt!.getDateTimeInUtc());
        usersByMonth[monthKey] = (usersByMonth[monthKey] ?? 0) + 1;
      }
    }

    return {
      'totalUsers': totalUsers,
      'demographics': {
        'countryDistribution': countryDistribution,
        'ageDistribution': ageDistribution,
        'schoolDistribution': schoolDistribution,
        'averageAge': _calculateAverageAge(users),
        'topCountries': _getTopEntries(countryDistribution, 5),
        'topSchools': _getTopEntries(schoolDistribution, 5),
      },
      'engagement': {
        'usersWithBios': usersWithBios,
        'usersWithProfilePictures': usersWithProfilePictures,
        'usersWithSchools': usersWithSchools,
        'profileCompletionRate':
            (usersWithBios + usersWithProfilePictures) / (totalUsers * 2),
        'activeUsers30Days': activeUsers30Days,
        'averageBioLength': _calculateAverageBioLength(users),
      },
      'temporal': {
        'usersByMonth': usersByMonth,
        'growthRate': _calculateGrowthRate(usersByMonth),
        'signupTrend': _calculateSignupTrend(users),
      },
    };
  }

  /// Calculate comprehensive sighting statistics
  static Map<String, dynamic> _calculateSightingStatistics(
    List<Sighting> sightings,
  ) {
    if (sightings.isEmpty) {
      return {
        'totalSightings': 0,
        'species': {},
        'geographical': {},
        'temporal': {},
        'quality': {},
      };
    }

    final totalSightings = sightings.length;

    // Species analysis
    final speciesDistribution = <String, int>{};
    for (final sighting in sightings) {
      speciesDistribution[sighting.species] =
          (speciesDistribution[sighting.species] ?? 0) + 1;
    }

    // Geographical analysis
    final cityDistribution = <String, int>{};
    final coordinates = <Map<String, double>>[];

    for (final sighting in sightings) {
      if (sighting.city != null && sighting.city!.isNotEmpty) {
        cityDistribution[sighting.city!] =
            (cityDistribution[sighting.city!] ?? 0) + 1;
      }
      coordinates.add({
        'latitude': sighting.latitude,
        'longitude': sighting.longitude,
      });
    }

    // Temporal analysis
    final sightingsByMonth = <String, int>{};
    final sightingsByHour = <int, int>{};
    final sightingsByDayOfWeek = <String, int>{};

    for (final sighting in sightings) {
      final dateTime = sighting.timestamp.getDateTimeInUtc();

      // By month
      final monthKey = DateFormat('yyyy-MM').format(dateTime);
      sightingsByMonth[monthKey] = (sightingsByMonth[monthKey] ?? 0) + 1;

      // By hour
      final hour = dateTime.hour;
      sightingsByHour[hour] = (sightingsByHour[hour] ?? 0) + 1;

      // By day of week
      final dayOfWeek = DateFormat('EEEE').format(dateTime);
      sightingsByDayOfWeek[dayOfWeek] =
          (sightingsByDayOfWeek[dayOfWeek] ?? 0) + 1;
    }

    // Quality metrics
    final sightingsWithDescriptions =
        sightings
            .where((s) => s.description != null && s.description!.isNotEmpty)
            .length;

    final timeClaimedSightings = sightings.where((s) => s.isTimeClaimed).length;

    return {
      'totalSightings': totalSightings,
      'species': {
        'uniqueSpecies': speciesDistribution.length,
        'speciesDistribution': speciesDistribution,
        'topSpecies': _getTopEntries(speciesDistribution, 10),
        'speciesDiversity': _calculateSpeciesDiversity(speciesDistribution),
      },
      'geographical': {
        'uniqueCities': cityDistribution.length,
        'cityDistribution': cityDistribution,
        'topCities': _getTopEntries(cityDistribution, 10),
        'geographicalSpread': _calculateGeographicalSpread(coordinates),
        'centerPoint': _calculateCenterPoint(coordinates),
      },
      'temporal': {
        'sightingsByMonth': sightingsByMonth,
        'sightingsByHour': sightingsByHour,
        'sightingsByDayOfWeek': sightingsByDayOfWeek,
        'peakHour': _findPeakHour(sightingsByHour),
        'peakDay': _findPeakDay(sightingsByDayOfWeek),
        'seasonalTrends': _calculateSeasonalTrends(sightingsByMonth),
      },
      'quality': {
        'sightingsWithDescriptions': sightingsWithDescriptions,
        'descriptionRate': sightingsWithDescriptions / totalSightings,
        'timeClaimedSightings': timeClaimedSightings,
        'timeClaimedRate': timeClaimedSightings / totalSightings,
        'averageDescriptionLength': _calculateAverageDescriptionLength(
          sightings,
        ),
      },
    };
  }

  /// Calculate combined statistics that involve both users and sightings
  static Map<String, dynamic> _calculateCombinedStatistics(
    List<User> users,
    List<Sighting> sightings,
  ) {
    if (users.isEmpty || sightings.isEmpty) {
      return {'userEngagement': {}, 'productivity': {}, 'community': {}};
    }

    // User engagement metrics
    final userSightingCounts = <String, int>{};
    for (final sighting in sightings) {
      if (sighting.user != null) {
        final userId = sighting.user!.id;
        userSightingCounts[userId] = (userSightingCounts[userId] ?? 0) + 1;
      }
    }

    final activeUsers = userSightingCounts.length;
    final totalSightings = sightings.length;
    final averageSightingsPerUser = totalSightings / activeUsers;

    // Top contributors
    final topContributors =
        userSightingCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Volunteer hours calculation
    final totalVolunteerHours = Volunteer.calculateTotalServiceHours(sightings);

    return {
      'userEngagement': {
        'activeUsers': activeUsers,
        'totalUsers': users.length,
        'engagementRate': activeUsers / users.length,
        'averageSightingsPerUser': averageSightingsPerUser,
        'topContributors':
            topContributors
                .take(10)
                .map((e) => {'userId': e.key, 'sightingCount': e.value})
                .toList(),
      },
      'productivity': {
        'totalVolunteerHours': totalVolunteerHours,
        'averageHoursPerUser': totalVolunteerHours / activeUsers,
        'averageHoursPerSighting': totalVolunteerHours / totalSightings,
      },
      'community': {
        'participationRate': activeUsers / users.length,
        'communitySize': users.length,
        'totalContributions': totalSightings,
        'averageUserAge': _calculateAverageAge(users),
      },
    };
  }

  // Helper methods
  static String _getAgeGroup(int age) {
    if (age < 13) return 'Under 13';
    if (age < 18) return '13-17';
    if (age < 25) return '18-24';
    if (age < 35) return '25-34';
    if (age < 50) return '35-49';
    if (age < 65) return '50-64';
    return '65+';
  }

  static List<Map<String, dynamic>> _getTopEntries(
    Map<String, int> distribution,
    int limit,
  ) {
    final entries = distribution.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(limit)
        .map((e) => {'name': e.key, 'count': e.value})
        .toList();
  }

  static double _calculateAverageAge(List<User> users) {
    final usersWithAge = users.where((u) => u.age != null).toList();
    if (usersWithAge.isEmpty) return 0;

    return usersWithAge.map((u) => u.age!).reduce((a, b) => a + b) /
        usersWithAge.length;
  }

  static double _calculateAverageBioLength(List<User> users) {
    final usersWithBio =
        users.where((u) => u.bio != null && u.bio!.isNotEmpty).toList();
    if (usersWithBio.isEmpty) return 0;

    return usersWithBio.map((u) => u.bio!.length).reduce((a, b) => a + b) /
        usersWithBio.length;
  }

  static double _calculateAverageDescriptionLength(List<Sighting> sightings) {
    final sightingsWithDescription =
        sightings
            .where((s) => s.description != null && s.description!.isNotEmpty)
            .toList();
    if (sightingsWithDescription.isEmpty) return 0;

    return sightingsWithDescription
            .map((s) => s.description!.length)
            .reduce((a, b) => a + b) /
        sightingsWithDescription.length;
  }

  static double _calculateGrowthRate(Map<String, int> usersByMonth) {
    if (usersByMonth.length < 2) return 0;

    final sortedEntries =
        usersByMonth.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    final recent = sortedEntries.last.value;
    final previous = sortedEntries[sortedEntries.length - 2].value;

    return previous == 0 ? 0 : (recent - previous) / previous;
  }

  static Map<String, dynamic> _calculateSignupTrend(List<User> users) {
    final now = DateTime.now();
    final last30Days =
        users
            .where(
              (u) =>
                  u.createdAt != null &&
                  now.difference(u.createdAt!.getDateTimeInUtc()).inDays <= 30,
            )
            .length;

    final last7Days =
        users
            .where(
              (u) =>
                  u.createdAt != null &&
                  now.difference(u.createdAt!.getDateTimeInUtc()).inDays <= 7,
            )
            .length;

    return {
      'last7Days': last7Days,
      'last30Days': last30Days,
      'dailyAverage': last30Days / 30,
    };
  }

  static double _calculateSpeciesDiversity(
    Map<String, int> speciesDistribution,
  ) {
    // Shannon diversity index
    final total = speciesDistribution.values.reduce((a, b) => a + b);
    double diversity = 0;

    for (final count in speciesDistribution.values) {
      final proportion = count / total;
      diversity -= proportion * math.log(proportion);
    }

    return diversity;
  }

  static Map<String, double> _calculateGeographicalSpread(
    List<Map<String, double>> coordinates,
  ) {
    if (coordinates.isEmpty) return {'latitudeRange': 0, 'longitudeRange': 0};

    final latitudes = coordinates.map((c) => c['latitude']!).toList();
    final longitudes = coordinates.map((c) => c['longitude']!).toList();

    return {
      'latitudeRange': latitudes.reduce(math.max) - latitudes.reduce(math.min),
      'longitudeRange':
          longitudes.reduce(math.max) - longitudes.reduce(math.min),
    };
  }

  static Map<String, double> _calculateCenterPoint(
    List<Map<String, double>> coordinates,
  ) {
    if (coordinates.isEmpty) return {'latitude': 0, 'longitude': 0};

    final avgLat =
        coordinates.map((c) => c['latitude']!).reduce((a, b) => a + b) /
        coordinates.length;
    final avgLng =
        coordinates.map((c) => c['longitude']!).reduce((a, b) => a + b) /
        coordinates.length;

    return {'latitude': avgLat, 'longitude': avgLng};
  }

  static int _findPeakHour(Map<int, int> hourDistribution) {
    if (hourDistribution.isEmpty) return 0;
    return hourDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  static String _findPeakDay(Map<String, int> dayDistribution) {
    if (dayDistribution.isEmpty) return 'Monday';
    return dayDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  static Map<String, int> _calculateSeasonalTrends(
    Map<String, int> monthlyData,
  ) {
    final seasons = <String, int>{
      'Spring': 0, // Mar, Apr, May
      'Summer': 0, // Jun, Jul, Aug
      'Fall': 0, // Sep, Oct, Nov
      'Winter': 0, // Dec, Jan, Feb
    };

    for (final entry in monthlyData.entries) {
      final month = int.parse(entry.key.split('-')[1]);
      final count = entry.value;

      if ([3, 4, 5].contains(month)) {
        seasons['Spring'] = (seasons['Spring'] ?? 0) + count;
      } else if ([6, 7, 8].contains(month)) {
        seasons['Summer'] = (seasons['Summer'] ?? 0) + count;
      } else if ([9, 10, 11].contains(month)) {
        seasons['Fall'] = (seasons['Fall'] ?? 0) + count;
      } else {
        seasons['Winter'] = (seasons['Winter'] ?? 0) + count;
      }
    }

    return seasons;
  }
}
