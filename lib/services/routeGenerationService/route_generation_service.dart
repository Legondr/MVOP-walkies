import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

class RouteGenerationService extends ChangeNotifier {
  final Random _random = Random();

  /// **Generate a random route based on a given distance (in meters)**
  Future<List<LatLng>> generateRouteByDistance(
      LatLng startLocation, double desiredDistance) async {
    List<LatLng> route = [];
    double totalDistance = 0.0;
    LatLng currentLocation = startLocation;
    route.add(currentLocation);

    while (totalDistance < desiredDistance) {
      // Generate a random point nearby
      LatLng newPoint = _generateRandomPointNearby(
          currentLocation, 50, 150); // Random step size between 50m - 150m

      // Calculate distance to the new point
      double distanceToNewPoint = _calculateDistance(currentLocation, newPoint);

      if (totalDistance + distanceToNewPoint <= desiredDistance) {
        totalDistance += distanceToNewPoint;
        route.add(newPoint);
        currentLocation = newPoint;
      } else {
        break;
      }
    }
    debugPrint("Generated Route: $route");
    return route;
  }

  /// **Generate a random route based on a given duration (in seconds)**
  Future<List<LatLng>> generateRouteByTime(
      LatLng startLocation, int durationInSeconds) async {
    List<LatLng> route = [];
    LatLng currentLocation = startLocation;
    route.add(currentLocation);

    int timeElapsed = 0;
    int averageWalkingSpeed = 1; // In meters per second (~3.6 km/h)

    while (timeElapsed < durationInSeconds) {
      // Calculate step size based on walking speed (assuming avg 1m per second)
      double stepSize = averageWalkingSpeed *
          30.0; // Each step moves ~30 seconds worth of distance

      // Generate a new point nearby with the step size
      LatLng newPoint = _generateRandomPointNearby(
          currentLocation, stepSize * 0.8, stepSize * 1.2);

      // Simulate time by adding 30 seconds per step
      timeElapsed += 30;
      route.add(newPoint);
      currentLocation = newPoint;
    }
    debugPrint("Generated Route: $route");
    return route;
  }

  /// **Generate a random nearby point based on a given step size**
  LatLng _generateRandomPointNearby(
      LatLng origin, double minDistance, double maxDistance) {
    double distance =
        minDistance + _random.nextDouble() * (maxDistance - minDistance);
    double bearing = _random.nextDouble() * 360; // Random direction

    return _calculateNewPosition(origin, distance, bearing);
  }

  /// **Calculate the new LatLng position based on distance and bearing**
  LatLng _calculateNewPosition(LatLng start, double distance, double bearing) {
    const double earthRadius = 6371000; // Earth's radius in meters
    double lat1 = _degreesToRadians(start.latitude);
    double lon1 = _degreesToRadians(start.longitude);
    double bearingRad = _degreesToRadians(bearing);

    double lat2 = asin(sin(lat1) * cos(distance / earthRadius) +
        cos(lat1) * sin(distance / earthRadius) * cos(bearingRad));

    double lon2 = lon1 +
        atan2(sin(bearingRad) * sin(distance / earthRadius) * cos(lat1),
            cos(distance / earthRadius) - sin(lat1) * sin(lat2));

    return LatLng(_radiansToDegrees(lat2), _radiansToDegrees(lon2));
  }

  /// **Calculate distance between two LatLng points in meters**
  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// **Convert degrees to radians**
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  /// **Convert radians to degrees**
  double _radiansToDegrees(double radians) {
    return radians * 180.0 / pi;
  }
}
