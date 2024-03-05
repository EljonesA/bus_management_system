import 'package:bus_management_system/others/WaitingMode.dart';
import 'package:bus_management_system/others/google_map.dart';
import 'package:bus_management_system/screens/home_screen.dart';
import 'package:bus_management_system/screens/login_screen.dart';
import 'package:bus_management_system/screens/splash_screen.dart';
import 'package:bus_management_system/screens/welcome_home_screen.dart';
// import 'package:bus_management_system/others/blacktint.dart';
// import 'package:bus_management_system/others/google_map copy.dart';
// import 'package:bus_management_system/others/map_style.dart';

const String welcomeRoute = "/welcome";
const String homeRoute = "/blacktint";
const String loginRoute = "/login";
const String splashRoute = "/splash";

final routes = {
  welcomeRoute: (context) => welcomeScreen(),
  homeRoute: (context) => HomeScreen(),
  loginRoute: (context) => LoginScreen(),
  splashRoute: (context) => splashScreen()
};
