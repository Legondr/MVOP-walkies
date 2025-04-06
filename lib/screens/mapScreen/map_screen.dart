import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:walkies/services/routeGenerationService/route_generation_service.dart';
import 'package:walkies/services/trackPositionService/track_position_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

@RoutePage()
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  late GoogleMapController mapController;
  final Set<Polyline> _polylines = {};
  late LatLng startLocation;

  late Future<LatLng> _initialLocationFuture;

  @override
  void initState() {
    super.initState();
    _initialLocationFuture =
        Provider.of<TrackPositionService>(context, listen: false)
            .getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user from Firebase Auth
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Walkies'),
        leading: Builder(
          builder: (context) {
            return IconButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: const Icon(Icons.menu),
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // Optional: Add a header with user profile information
            UserAccountsDrawerHeader(
              accountName: const Text(''),
              accountEmail: Text(currentUser?.email ?? 'youremail@example.com'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 50),
              ),
            ),
            // Add Drawer items

            ListTile(
              title: const Text('Log Out'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                _signOut(); // Sign out
              },
            ),
          ],
        ),
      ),
      body: Consumer<TrackPositionService>(
        builder: (context, trackingService, child) {
          // We are using FutureBuilder to wait for the start location
          return FutureBuilder<LatLng>(
            future: _initialLocationFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.hasData) {
                startLocation = snapshot.data!;

                // Now that we have the startLocation, we can display the map
                return Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        if (!_controller.isCompleted) {
                          // Check if already completed
                          _controller.complete(controller);
                        }
                        mapController = controller;

                        // Only animate the camera after the controller is created
                        if (snapshot.hasData) {
                          mapController.animateCamera(
                            CameraUpdate.newLatLngZoom(startLocation, 15),
                          );
                        }
                      },
                      initialCameraPosition: CameraPosition(
                        target: startLocation,
                        zoom: 15.0,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('currentLocation'),
                          position: startLocation,
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
              }

              // Fallback if no data
              return const Center(child: Text('No location available'));
            },
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
    debugPrint(
        "Generate route by distance called with distance: ${distanceController.text}");

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter Distance (meters)"),
          content: TextField(
            controller: distanceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Enter distance in meters",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                debugPrint('Generating route');

                double? distance = double.tryParse(distanceController.text);
                if (distance != null && distance > 0) {
                  Navigator.of(context).pop();

                  LatLng startLocation =
                      await Provider.of<TrackPositionService>(context,
                              listen: false)
                          .getCurrentLocation();

                  // Generate an endpoint by moving "distance" meters away (mock logic)
                  List<LatLng> waypoints = await RouteGenerationService()
                      .generateRouteByDistance(startLocation, distance);
                  // Ensure loop closure by adding start location at the end
                  waypoints.add(startLocation);

                  _updateRouteOnMap(waypoints);
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
    debugPrint(
        "Generate route by time called with time: ${timeController.text}");

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
                debugPrint('Generating route');

                if (!mounted) return;

                final currentContext = context; // Capture context

                int? timeInMinutes = int.tryParse(timeController.text);
                if (timeInMinutes != null && timeInMinutes > 0) {
                  Navigator.of(currentContext).pop(); // Pop before async call

                  int durationInSeconds = timeInMinutes * 60;

                  // Fetch services *before* async calls to avoid context issues
                  final trackPositionService =
                      Provider.of<TrackPositionService>(
                    currentContext,
                    listen: false,
                  );

                  final routeGenerationService =
                      Provider.of<RouteGenerationService>(
                    currentContext,
                    listen: false,
                  );

                  // Get start location
                  LatLng startLocation =
                      await trackPositionService.getCurrentLocation();
                  if (!mounted) return;

                  // Generate route
                  List<LatLng> waypoints =
                      await routeGenerationService.generateRouteByTime(
                    startLocation,
                    durationInSeconds,
                  );

                  // Close the loop
                  waypoints.add(startLocation);
                  if (!mounted) return;
                  _updateRouteOnMap(waypoints);
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
    if (route.isEmpty) {
      debugPrint("No route to display!");
      return;
    }

    double actualDistance =
        _calculateTotalDistance(route); // Calculate route length
    debugPrint(
        "Generated route length: ${actualDistance.toStringAsFixed(2)} meters");

    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId("generatedRoute"),
          points: route,
          color: Colors.cyan,
          width: 5,
          visible: true,
        ),
      );
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {}); // Force UI update
    });

    _moveCameraToRoute(route);
  }

  /// Calculates the total distance of a polyline route in meters
  double _calculateTotalDistance(List<LatLng> route) {
    double totalDistance = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      totalDistance += _calculateDistance(route[i], route[i + 1]);
    }
    return totalDistance;
  }

  /// Haversine formula to calculate distance between two LatLng points
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double R = 6371000; // Earth radius in meters
    double lat1 = point1.latitude * pi / 180;
    double lat2 = point2.latitude * pi / 180;
    double dLat = lat2 - lat1;
    double dLon = (point2.longitude - point1.longitude) * pi / 180;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  void _moveCameraToRoute(List<LatLng> route) async {
    if (route.isEmpty) return;

    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(_getBounds(route), 50),
    );
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate back to the login screen after signing out
      if (mounted) {
        Navigator.pushReplacementNamed(
            context, '/login'); // Adjust route name as needed
      }
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
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
