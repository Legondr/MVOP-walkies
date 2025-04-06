import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteGenerationService extends ChangeNotifier {
  static const String _apiKey = "AIzaSyDDgt0QnrDwiztOKcB9PLa-SMlmLrYQmNE";
  static const double _walkingSpeed = 1.4; // Average walking speed in m/s

  /// Generates a walking route based on distance (circular path)
  Future<List<LatLng>> generateRouteByDistance(
      LatLng start, double distance) async {
    debugPrint("Generating route with distance = $distance");

    return await _fetchCircularRoute(start, distance);
  }

  /// Generates a walking route based on time (circular path)
  Future<List<LatLng>> generateRouteByTime(
      LatLng start, int timeInSeconds) async {
    debugPrint("Generating route with time in seconds = $timeInSeconds");

    double estimatedDistance =
        _estimateDistance(timeInSeconds); // Convert time to distance
    return await _fetchCircularRoute(start, estimatedDistance);
  }

  String _formatWaypoints(List<LatLng> waypoints) {
    return waypoints
        .map((point) => "via:${point.latitude},${point.longitude}")
        .join("|");
  }

  Future<List<LatLng>> getWalkingRoute(LatLng start, LatLng end) async {
    final Uri url = Uri.https(
      "maps.googleapis.com",
      "/maps/api/directions/json",
      {
        "origin": "${start.latitude},${start.longitude}",
        "destination": "${end.latitude},${end.longitude}",
        "mode": "walking",
        "key": _apiKey,
      },
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['routes'].isEmpty) {
        //debugPrint("Google Directions API Response: ${response.body}");
        throw Exception("No routes found.");
      }

      //debugPrint("Request URL: $url");
      //debugPrint("Response: ${response.body}");

      final overviewPolyline = data['routes'][0]['overview_polyline']['points'];
      //debugPrint("Polyline: $overviewPolyline");

      final List<LatLng> routePoints = _decodePolyline(overviewPolyline);

      if (routePoints.isEmpty) {
        debugPrint("Decoded route points are empty!");
      }

      return routePoints;
    } else {
      throw Exception("Failed to load route");
    }
  }

  /// Decodes a polyline string into a list of LatLng points
  List<LatLng> _decodePolyline(String polyline) {
    List<LatLng> polylinePoints = [];
    int index = 0, len = polyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int shift = 0, result = 0;
      while (true) {
        int code = polyline.codeUnitAt(index) - 63;
        index++;
        result |= (code & 0x1f) << shift;
        shift += 5;
        if (code < 0x20) break;
      }
      int dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dLat;

      shift = 0;
      result = 0;
      while (true) {
        int code = polyline.codeUnitAt(index) - 63;
        index++;
        result |= (code & 0x1f) << shift;
        shift += 5;
        if (code < 0x20) break;
      }
      int dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dLng;

      polylinePoints.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polylinePoints;
  }

  /// Estimates the total distance from the walking time (using the walking speed)
  double _estimateDistance(int timeInSeconds) {
    return timeInSeconds * _walkingSpeed; // distance = time * speed
  }

  /// Generates waypoints in a circular pattern around the start point based on the total desired distance
  Future<List<LatLng>> _generateCircularWaypoints(
      LatLng center, double totalDistance) async {
    debugPrint('Generating circular waypoints');
    List<LatLng> waypoints = [];

    int numPoints = 8; // More points = smoother circular route
    double estimatedRadius =
        (totalDistance / (2 * pi)); // Approximate circular radius
    Random random = Random();

    for (int i = 0; i < numPoints; i++) {
      double angle = (i * 2 * pi / numPoints) +
          (random.nextDouble() * pi / 8); // Random offset

      // Adjust radius dynamically for variation
      double radius = estimatedRadius *
          (0.9 + random.nextDouble() * 0.2); // 90%-110% random range

      // Convert meters to latitude/longitude degrees
      double latOffset = (radius * cos(angle) / 111000);
      double lngOffset =
          (radius * sin(angle) / (111000 * cos(center.latitude * pi / 180)));

      LatLng waypoint =
          LatLng(center.latitude + latOffset, center.longitude + lngOffset);

      if (await _isValidWaypoint(waypoint)) {
        waypoints.add(waypoint);
      } else {
        i--; // Retry with a new random point
      }
    }

    debugPrint('Generated waypoints: $waypoints');
    return waypoints;
  }

  /// Fetches a circular route and adjusts based on length
  Future<List<LatLng>> _fetchCircularRoute(
      LatLng start, double targetDistance) async {
    debugPrint('Fetching circular route.');

    const int maxRetries = 25;
    const double tolerance = 0.1; // 10% error allowed

    double radiusFactor = 1.0;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      debugPrint("Attempt $attempt with radius factor $radiusFactor");

      // Generate waypoints using adjusted radius
      List<LatLng> waypoints = await _generateCircularWaypoints(
        start,
        targetDistance * radiusFactor,
      );

      final Uri url = Uri.https(
        "maps.googleapis.com",
        "/maps/api/directions/json",
        {
          "origin": "${start.latitude},${start.longitude}",
          "destination":
              "${start.latitude},${start.longitude}", // circular route
          "mode": "walking",
          "key": _apiKey,
          "waypoints": "optimize:true|${_formatWaypoints(waypoints)}",
          "avoid": "highways|tolls",
        },
      );

      final response = await http.get(url);

      if (response.statusCode != 200) continue;

      final data = json.decode(response.body);
      if (data['routes'].isEmpty) continue;

      List<LatLng> routePoints =
          _decodePolyline(data['routes'][0]['overview_polyline']['points']);
      double actualDistance = _calculateTotalDistance(routePoints);

      debugPrint("Generated route length: $actualDistance m");

      double error = actualDistance - targetDistance;
      double errorPercent = error.abs() / targetDistance;

      if (errorPercent <= tolerance) {
        debugPrint("Acceptable route found!");
        return routePoints;
      }

      // Adjust radiusFactor based on over/under
      radiusFactor *= (targetDistance / actualDistance);
    }

    throw Exception("Failed to generate a route within acceptable distance.");
  }

  /// Creates a marker to indicate the start of the route
  Marker createStartMarker(LatLng start) {
    return Marker(
      markerId: const MarkerId("start_marker"),
      position: start,
      infoWindow: const InfoWindow(title: "Start of Route"),
      icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen), // Green color for the start
    );
  }

  /// Calculate total distance of a route given a list of LatLng points
  double _calculateTotalDistance(List<LatLng> points) {
    double totalDistance = 0.0;

    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += _haversineDistance(points[i], points[i + 1]);
    }

    return totalDistance;
  }

  /// Calculate the Haversine distance between two LatLng points
  double _haversineDistance(LatLng p1, LatLng p2) {
    const double R = 6371000; // Earth radius in meters
    double lat1 = p1.latitude * pi / 180;
    double lon1 = p1.longitude * pi / 180;
    double lat2 = p2.latitude * pi / 180;
    double lon2 = p2.longitude * pi / 180;

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a =
        pow(sin(dLat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  Future<bool> _isValidWaypoint(LatLng waypoint) async {
    final Uri url = Uri.https("maps.googleapis.com", "/maps/api/geocode/json", {
      "latlng": "${waypoint.latitude},${waypoint.longitude}",
      "key": _apiKey,
    });

    //debugPrint('Checking waypoint validity: $url');

    final response = await http.get(url);

    //debugPrint('Response status: ${response.statusCode}');
    //debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['results'].isNotEmpty) {
        final firstResult = data['results'][0];
        final types = firstResult['types'] as List<dynamic>? ?? [];

        //debugPrint('Waypoint types: $types');

        return types.any((type) => [
              'street_address',
              'route',
              'park',
              'neighborhood',
              'sublocality',
              'locality',
              'point_of_interest',
              'natural_feature',
              'establishment',
              'premise',
              'tourist_attraction',
              'place_of_worship'
            ].contains(type));
      }
    }

    debugPrint('Waypoint is invalid');
    return false; // Default to invalid if response fails
  }
}
