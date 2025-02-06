import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:walkies/services/trackPositionService/track_position_service.dart';
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
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      LatLng startLocation =
          await Provider.of<TrackPositionService>(context, listen: false)
              .getCurrentLocation();

      if (_controller.isCompleted) {
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLngZoom(startLocation, 15));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var trackingService = Provider.of<TrackPositionService>(context);

    // Update route when new locations arrive
    _polylines = {
      Polyline(
        polylineId: const PolylineId("userRoute"),
        points: trackingService.routeCoordinates,
        color: Colors.blue,
        width: 5,
      ),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Walkies - Live Tracking')),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              mapController = controller;
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(0.0, 0.0),
              zoom: 15.0,
            ),
            markers: {
              if (trackingService.routeCoordinates.isNotEmpty)
                Marker(
                  markerId: const MarkerId('currentLocation'),
                  position: trackingService.routeCoordinates.last,
                  infoWindow: const InfoWindow(title: "You are here"),
                ),
            },
            polylines: _polylines,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 200,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      if (trackingService.isTracking) {
                        trackingService.stopTracking(); // Stop tracking
                      } else {
                        trackingService.startTracking(); // Start tracking
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: trackingService.isTracking
                          ? Colors.red
                          : Colors.green,
                    ),
                    child: Text(
                      trackingService.isTracking ? "Stop" : "Start",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
