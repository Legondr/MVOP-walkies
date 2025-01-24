import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:walkies/app/router.dart';
import 'package:walkies/screens/home screen/home_screen.dart';
import 'package:walkies/screens/login screen/login_screen.dart';
import 'package:walkies/screens/register screen/register_screen.dart';

@RoutePage()
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void signUserIn() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FloatingActionButton(onPressed: () {
          context.router.push(const HomeRoute());
        }),
      ),
    );
  }
}
