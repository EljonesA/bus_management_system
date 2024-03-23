import 'package:flutter/material.dart';
import 'package:bus_management_system/choose_role_page.dart';
import 'package:firebase_core/firebase_core.dart';

// Initialize firebase
void main() async {
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

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF2A3040), // Uber primary color
        scaffoldBackgroundColor: Colors.black, // Uber scaffold background color
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: TextTheme(
          bodyText1: TextStyle(color: Colors.white),
          bodyText2: TextStyle(color: Colors.white),
          button: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: Color(0xFF2A3040), // Uber primary color
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            primary: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white),
          prefixStyle: TextStyle(color: Colors.white),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 2.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 2.0),
          ),
        ),
      ),
      home: ChooseRolePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChooseRolePage(),
    );
  }
}

class FirebaseInitialization {
  static FirebaseApp? _firebaseApp;

  // Initialize Firebase
  static Future<void> initializeFirebase() async {
    try {
      _firebaseApp ??= await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: "6bjFDyNtPRsEEU43xv0Wteonf2cKdw",
          appId: "1:703723306361:android:81fe552b4f080e9ec583a8",
          messagingSenderId: "messagingSenderId",
          projectId: "bus-management-system-2f1fa",
        ),
      );
    } catch (e) {
      print('Error initializing Firebase: $e');
    }
  }

  // Access initialized Firebase app
  static FirebaseApp? get firebaseApp => _firebaseApp;
}
