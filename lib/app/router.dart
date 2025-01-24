import 'package:auto_route/auto_route.dart';
import 'package:walkies/screens/home screen/home_screen.dart';
import 'package:walkies/screens/login screen/login_screen.dart';
import 'package:walkies/screens/register screen/register_screen.dart';
part 'router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: LoginRoute.page,
          initial: true,
        ),
        AutoRoute(
          page: RegisterRoute.page,
        ),
        AutoRoute(
          page: HomeRoute.page,
        )
      ];
}
