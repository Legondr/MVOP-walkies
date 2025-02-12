import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:walkies/services/routeGenerationService/route_generation_service.dart';
import 'package:walkies/services/trackPositionService/track_position_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  late GoogleMapController mapController;
  Set<Polyline> _polylines = {};
  bool _isMapReady = false; // Track if map is initialized

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

    return Scaffold(
      appBar: AppBar(title: const Text('Walkies - Live Tracking')),
      body: Consumer<TrackPositionService>(
        builder: (context, trackingService, child) {
          return Stack(
            children: [
              GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                  mapController = controller;
                  setState(() => _isMapReady = true); // Ensure map is ready
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
                myLocationButtonEnabled: false,
              ),
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: trackingService.isTracking
                            ? trackingService.stopTracking
                            : trackingService.startTracking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: trackingService.isTracking
                              ? Colors.red
                              : Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50.0,
                            vertical: 15.0,
                          ),
                        ),
                        child: Text(
                          trackingService.isTracking ? "Stop" : "Start",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () => _showRouteOptionsDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30.0,
                            vertical: 15.0,
                          ),
                        ),
                        child: const Text(
                          "Generate Route",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRouteOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Generate Route"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("By Distance"),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDistanceInputDialog(context);
                },
              ),
              ListTile(
                title: const Text("By Time"),
                onTap: () {
                  Navigator.of(context).pop();
                  _showTimeInputDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDistanceInputDialog(BuildContext context) {
    TextEditingController distanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter Distance (meters)"),
          content: TextField(
            controller: distanceController,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(hintText: "Enter distance in meters"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                double? distance = double.tryParse(distanceController.text);
                if (distance != null && distance > 0) {
                  Navigator.of(context).pop();
                  LatLng startLocation =
                      await Provider.of<TrackPositionService>(context,
                              listen: false)
                          .getCurrentLocation();

                  List<LatLng> route =
                      await Provider.of<RouteGenerationService>(context,
                              listen: false)
                          .generateRouteByDistance(startLocation, distance);

                  _updateRouteOnMap(route);
                }
              },
              child: const Text("Generate"),
            ),
          ],
        );
      },
    );
  }

  void _showTimeInputDialog(BuildContext context) {
    TextEditingController timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter Time (minutes)"),
          content: TextField(
            controller: timeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Enter time in minutes",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                int? timeInMinutes = int.tryParse(timeController.text);
                if (timeInMinutes != null && timeInMinutes > 0) {
                  Navigator.of(context).pop();
                  int durationInSeconds = timeInMinutes * 60;

                  LatLng startLocation =
                      await Provider.of<TrackPositionService>(context,
                              listen: false)
                          .getCurrentLocation();

                  List<LatLng> route = await Provider.of<
                          RouteGenerationService>(context, listen: false)
                      .generateRouteByTime(startLocation, durationInSeconds);

                  _updateRouteOnMap(route);
                }
              },
              child: const Text("Generate"),
            ),
          ],
        );
      },
    );
  }

  void _updateRouteOnMap(List<LatLng> route) {
    if (!_isMapReady) {
      debugPrint("Map not ready yet, skipping update.");
      return;
    }

    if (route.isEmpty) {
      debugPrint("No route to display!");
      return;
    }

    debugPrint('Updating map with polyline: ${route.length} points');

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId("generatedRoute"),
          points: route,
          color: Colors.cyanAccent, // Ensure visible color
          width: 5,
          visible: true,
        ),
      };
    });

    _moveCameraToRoute(route);
  }

  void _moveCameraToRoute(List<LatLng> route) async {
    if (route.isEmpty) return;

    final controller = await _controller.future;

    debugPrint("Moving camera to first route point: ${route.first}");

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(_getBounds(route), 50),
    );

    // Add a manual delay, then print camera position
    Future.delayed(const Duration(seconds: 2), () async {
      LatLngBounds visibleRegion = await controller.getVisibleRegion();
      // Calculate the center of the visible region
      LatLng center = LatLng(
        (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) /
            2,
        (visibleRegion.northeast.longitude +
                visibleRegion.southwest.longitude) /
            2,
      );

      debugPrint(
          "Current camera position: ${center.latitude}, ${center.longitude}");
    });
  }
}

LatLngBounds _getBounds(List<LatLng> points) {
  double minLat = points.first.latitude;
  double maxLat = points.first.latitude;
  double minLng = points.first.longitude;
  double maxLng = points.first.longitude;

  for (LatLng point in points) {
    if (point.latitude < minLat) minLat = point.latitude;
    if (point.latitude > maxLat) maxLat = point.latitude;
    if (point.longitude < minLng) minLng = point.longitude;
    if (point.longitude > maxLng) maxLng = point.longitude;
  }

  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}
