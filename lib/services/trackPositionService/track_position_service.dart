import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';

class TrackPositionService extends ChangeNotifier {
  bool _isTracking = false;
  final List<LatLng> _routeCoordinates = [];
  StreamSubscription<Position>? _positionStream;

  bool get isTracking => _isTracking;
  List<LatLng> get routeCoordinates => _routeCoordinates;

  Future<LatLng> getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      throw Exception("Location permission denied.");
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return LatLng(position.latitude, position.longitude);
  }

  void startTracking() {
    if (_isTracking) return; // Prevent multiple subscriptions
    _isTracking = true;
    _routeCoordinates.clear();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((Position position) {
      LatLng newPosition = LatLng(position.latitude, position.longitude);
      _routeCoordinates.add(newPosition);
      notifyListeners();
    });

    debugPrint("Tracking started...");
  }

  void stopTracking() {
    _isTracking = false;
    _positionStream?.cancel();
    notifyListeners();
    debugPrint("Tracking stopped...");
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
