import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:walkies/services/locationService/location_service.dart';
import 'dart:async';

@RoutePage()
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  late GoogleMapController mapController;
  LatLng _currentPosition = const LatLng(51.509865, -0.118092);
  bool _isLoading = true;

  Future<void> _updateMapLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      LatLng currentLocation = LatLng(position.latitude, position.longitude);

      debugPrint(
          "Fetched Location: ${position.latitude}, ${position.longitude}");

      setState(() {
        _currentPosition = currentLocation;
        _isLoading = false;
      });

      // Ensure controller is initialized before using it
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 15.0),
      );
    } catch (e) {
      debugPrint("Error fetching location: ${e.toString()}");
    }
  }

  @override
  void initState() {
    super.initState();
    _updateMapLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Walkies - Route'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
                _updateMapLocation(); // Fetch location after map loads
              },
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 15.0,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('currentLocation'),
                  position: _currentPosition,
                  infoWindow: const InfoWindow(title: "You are here"),
                ),
              },
            ),
    );
  }
}
