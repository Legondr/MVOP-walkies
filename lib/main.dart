import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:walkies/app/router.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

  final _router = AppRouter();
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router.config(),
    );
  }
}
