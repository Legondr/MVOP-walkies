import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:walkies/screens/loginScreen/login_screen.dart';
import 'package:walkies/screens/registerScreen/register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FloatingActionButton(onPressed: FirebaseAuth.instance.signOut),
      ),
    );
  }
}
