import 'package:flutter/material.dart';
import 'package:walkies/app/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:walkies/services/trackPositionService/track_position_service.dart';
import 'package:walkies/services/routeGenerationService/route_generation_service.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  checkAndRequestLocation();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TrackPositionService>(
          create: (context) => TrackPositionService(),
        ),
        ChangeNotifierProvider<RouteGenerationService>(
          create: (context) => RouteGenerationService(),
        ),
      ],
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

  final _router = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => TrackPositionService()), // Registering the service
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: _router.config(),
      ),
    );
  }
}

Future<void> checkAndRequestLocation() async {
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) {
    // Open settings because permission was permanently denied
    await Geolocator.openAppSettings();
  }

  if (permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always) {
    // Permission granted, get location
    Position position = await Geolocator.getCurrentPosition();
    debugPrint("Location: ${position.latitude}, ${position.longitude}");
  }
}
