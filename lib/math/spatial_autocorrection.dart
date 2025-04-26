import 'dart:math' as math;
import 'package:sighttrack/barrel.dart';

extension DegreesToRadians on double {
  double toRadians() => this * math.pi / 180.0;
}

class SpatialAutocorrelation {
  SpatialAutocorrelation._();

  static double calculateMoransI({
    required List<Sighting> sightings,
    required String species,
    double maxDistanceKm = 10.0,
    TemporalDateTime? startTime,
    TemporalDateTime? endTime,
  }) {
    // Filter
    final filteredSightings =
        sightings.where((s) {
          if (s.species != species) return false;
          if (startTime != null &&
              s.timestamp.getDateTimeInUtc().isBefore(
                startTime.getDateTimeInUtc(),
              )) {
            return false;
          }
          if (endTime != null &&
              s.timestamp.getDateTimeInUtc().isAfter(
                endTime.getDateTimeInUtc(),
              )) {
            return false;
          }
          return true;
        }).toList();

    if (filteredSightings.length < 2) {
      Log.i(
        'MORANSI: Insufficient sightings for $species: ${filteredSightings.length}',
      );
      return 0.0;
    }

    final n = filteredSightings.length;
    double sumWeights = 0.0, numerator = 0.0, denominator = 0.0;

    final density = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (i == j) continue;
        final distance = _haversineDistance(
          filteredSightings[i].latitude,
          filteredSightings[i].longitude,
          filteredSightings[j].latitude,
          filteredSightings[j].longitude,
        );
        if (distance <= maxDistanceKm) {
          density[i] += 1.0; // Count nearby sightings
        }
      }
    }

    // Calculate mean density
    final meanDensity = density.fold<double>(0.0, (sum, d) => sum + d) / n;

    // Moran's I
    for (int i = 0; i < n; i++) {
      final zi = density[i] - meanDensity; // Deviation from mean density
      denominator += zi * zi; // Sum of squared deviations
      for (int j = 0; j < n; j++) {
        if (i == j) continue;
        final distance = _haversineDistance(
          filteredSightings[i].latitude,
          filteredSightings[i].longitude,
          filteredSightings[j].latitude,
          filteredSightings[j].longitude,
        );
        // Weight: inverse distance. Capped for very close points
        final weight =
            distance > 0.0001 && distance <= maxDistanceKm ? 1 / distance : 0.0;
        sumWeights += weight;
        numerator +=
            weight * zi * (density[j] - meanDensity); // Product of deviations
      }
    }

    // Handle edge cases
    if (sumWeights == 0 || denominator == 0) {
      Log.i(
        'MORANSI: Zero weights or denominator for $species: sumWeights=$sumWeights, denominator=$denominator',
      );
      return 0.0;
    }

    final moransI = (n / sumWeights) * (numerator / denominator);
    Log.i('MORANSI: Success $species: $moransI');
    return moransI;
  }

  /// Calculates Haversine distance between two points in km
  static double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371.0; // Earth radius
    final dLat = (lat2 - lat1).toRadians();
    final dLon = (lon2 - lon1).toRadians();
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1.toRadians()) *
            math.cos(lat2.toRadians()) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.asin(math.sqrt(a));
  }

  /// Aggregates sightings by species to identify biodiversity hotspots.
  /// Returns a map of species to Moran's I values for clustering analysis.
  static Map<String, double> analyzeBiodiversityHotspots({
    required List<Sighting> sightings,
    double? maxDistanceKm,
    TemporalDateTime? startTime,
    TemporalDateTime? endTime,
  }) {
    final speciesSet = sightings.map((s) => s.species).toSet();
    final results = <String, double>{};
    for (final species in speciesSet) {
      results[species] = calculateMoransI(
        sightings: sightings,
        species: species,
        maxDistanceKm: maxDistanceKm ?? 10.0,
        startTime: startTime,
        endTime: endTime,
      );
    }
    return results;
  }
}
