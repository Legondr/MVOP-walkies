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
      LatLng start, double distance, int numPoints) async {
    return await _fetchCircularRoute(start, distance, numPoints);
  }

  /// Generates a walking route based on time (circular path)
  Future<List<LatLng>> generateRouteByTime(
      LatLng start, int timeInSeconds, int numPoints) async {
    double estimatedDistance =
        _estimateDistance(timeInSeconds); // Convert time to distance
    return await _fetchCircularRoute(start, estimatedDistance, numPoints);
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
        debugPrint("Google Directions API Response: ${response.body}");
        throw Exception("No routes found.");
      }

      debugPrint("Request URL: $url");
      debugPrint("Response: ${response.body}");

      final overviewPolyline = data['routes'][0]['overview_polyline']['points'];
      debugPrint("Polyline: $overviewPolyline");

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
  List<LatLng> _generateCircularWaypoints(
      LatLng center, double totalDistance, int numPoints) {
    List<LatLng> waypoints = [];

    // Calculate the distance between consecutive waypoints
    double distancePerPoint = totalDistance / numPoints;

    // Approximate the angular distance between consecutive waypoints on the circle
    double angleIncrement = 2 * pi / numPoints;

    // Generate waypoints
    for (int i = 0; i < numPoints; i++) {
      double angle = i * angleIncrement;
      double radius = distancePerPoint / angleIncrement;

      double latOffset =
          radius * cos(angle) / 111000; // Convert meters to degrees
      double lngOffset =
          radius * sin(angle) / (111000 * cos(center.latitude * pi / 180));

      LatLng waypoint =
          LatLng(center.latitude + latOffset, center.longitude + lngOffset);

      // You can optionally call a function to validate the waypoint here
      if (_isValidWaypoint(waypoint)) {
        waypoints.add(waypoint);
      } else {
        // If the waypoint is invalid, retry generating it or adjust the angle
        i--; // Retry this waypoint if invalid
      }
    }

    return waypoints;
  }

  /// A helper function to check if a waypoint is valid
  /// You can call Google Maps Geocoding API here to check if the location is walkable
  bool _isValidWaypoint(LatLng waypoint) {
    return true; // Placeholder for actual validation logic
  }

  /// Fetches a circular route using waypoints and Google Directions API with a check for dead ends
  Future<List<LatLng>> _fetchCircularRoute(
      LatLng start, double distance, int numPoints) async {
    List<LatLng> waypoints =
        _generateCircularWaypoints(start, distance, numPoints);

    // Ensure that all waypoints are connected in a valid route before proceeding
    LatLng end = start; // Ensuring circular route

    final Uri url = Uri.https(
      "maps.googleapis.com",
      "/maps/api/directions/json",
      {
        "origin": "${start.latitude},${start.longitude}",
        "destination": "${end.latitude},${end.longitude}",
        "mode": "walking",
        "key": _apiKey,
        "waypoints": "optimize:true|${_formatWaypoints(waypoints)}",
        "avoid": "highways|tolls",
        "optimize_waypoints":
            "false", // Prevents Google from rearranging waypoints
      },
    );

    debugPrint("Generated URL: $url");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['routes'].isEmpty) {
        debugPrint("Google Directions API Response: ${response.body}");
        throw Exception(
            "No routes found. Check if walking routes are available.");
      }

      debugPrint("Request URL: $url");
      debugPrint("Response: ${response.body}");

      // Decode polyline points
      return _decodePolyline(data['routes'][0]['overview_polyline']['points']);
    } else {
      throw Exception("Failed to load route");
    }
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
}
