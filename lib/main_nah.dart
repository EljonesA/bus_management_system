import 'package:bus_management_system/model/routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// import 'Screens/welcome_screen.dart';
import 'package:bus_management_system/screens/welcome_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyCW-6bjFDyNtPRsEEU43xv0Wteonf2cKdw',
      appId: '1:703723306361:android:81fe552b4f080e9ec583a8',
      messagingSenderId: 'messagingSenderId',
      projectId: 'bus-management-system-2f1fa',
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus Tracking App',
      theme: ThemeData(
        //backgroundColor: Colors.black
        primarySwatch: Colors.deepPurple,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: splashRoute,
      routes: routes,
      home: welcomeScreen(),
    );
  }
}
