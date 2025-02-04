import 'package:auto_route/auto_route.dart';
import 'package:walkies/screens/homeScreen/home_screen.dart';
import 'package:walkies/screens/loginScreen/login_screen.dart';
import 'package:walkies/screens/registerScreen/register_screen.dart';
import 'package:walkies/screens/authScreen/auth_screen.dart';
import 'package:walkies/screens/mapScreen/map_screen.dart';
import 'package:walkies/screens/forgotPasswordScreen/forgot_password_screen.dart';
import 'package:flutter/material.dart';
part 'router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: LoginRoute.page,
        ),
        AutoRoute(
          page: RegisterRoute.page,
        ),
        AutoRoute(
          page: HomeRoute.page,
        ),
        AutoRoute(
          page: ForgotPasswordRoute.page,
        ),
        AutoRoute(
          page: AuthRoute.page,
          initial: true,
        ),
        AutoRoute(
          page: MapRoute.page,
        )
      ];
}
