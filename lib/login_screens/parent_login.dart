import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:bus_management_system/choose_role_page.dart';
import 'package:bus_management_system/parents/parent_main.dart';
import 'package:bus_management_system/parents/parent_register_child.dart';
import 'dart:async'; // import for timer

class ParentLoginPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 2),
              color: Colors.black,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Parent Login',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                Image.asset('images/parent_icon.jpeg',
                    width: 150), // Add parent icon
                SizedBox(height: 20),
                Container(
                  width: 250,
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person, color: Colors.white),
                      border: OutlineInputBorder(),
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: 250,
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock, color: Colors.white),
                      border: OutlineInputBorder(),
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    String email = _emailController.text.trim();
                    String password = _passwordController.text.trim();
                    _signInWithEmailAndPassword(context, email, password);
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.white,
                  ),
                  child: Text('Sign In', style: TextStyle(color: Colors.black)),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    // Reset password logic
                    _resetPassword(context, _emailController.text.trim());
                  },
                  child: Text('Forgot Password?',
                      style: TextStyle(color: Colors.white)),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    // Navigate to signup page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ParentSignUpPage()),
                    );
                  },
                  child: Text('Not a member? Sign Up',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithEmailAndPassword(
      BuildContext context, String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Navigate to the home page or any other page after successful sign-in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ParentViewPage()),
      );
    } catch (e) {
      // Handle sign-in errors, display error message to the user
      Fluttertoast.showToast(
        msg: "Wrong credentials, double check & try again",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      print('Sign in error: $e');
    }
  }

  Future<void> _resetPassword(BuildContext context, String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Fluttertoast.showToast(
        msg: "Password reset email sent to $email",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to send password reset email",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      print('Reset password error: $e');
    }
  }
}

class ParentSignUpPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(
            255, 86, 150, 88), // Set the background color of the app bar
        elevation: 0, // Remove the elevation (shadow) of the app bar
        foregroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SchollyBus Mate',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.exit_to_app,
            ),
            onPressed: () {
              // navigate back to login screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ChooseRolePage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 2),
              color: Colors.black,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Parent / Guardian Sign Up',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                Image.asset('images/parent_icon.jpeg',
                    width: 150), // Add parent icon
                SizedBox(height: 20),
                Container(
                  width: 250,
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person, color: Colors.white),
                      border: OutlineInputBorder(),
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: 250,
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock, color: Colors.white),
                      border: OutlineInputBorder(),
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    String email = _emailController.text.trim();
                    String password = _passwordController.text.trim();
                    _verifyEmail(context, email, password);
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.white,
                  ),
                  child: Text('Sign Up', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verifyEmail(
      BuildContext context, String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _auth.currentUser!.sendEmailVerification();

      Timer.periodic(Duration(seconds: 2), (timer) {
        _auth.currentUser!.reload();
        if (_auth.currentUser!.emailVerified) {
          timer.cancel();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => StudentRegistrationPage()),
          );
        }
      });
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.green, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            title: Text(
              "Email Verification",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              "A verification email has been sent to $email",
              style: TextStyle(color: Colors.white),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  "OK",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.green, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            title: Text(
              "Error",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              "Error! Double check & try again.",
              style: TextStyle(color: Colors.white),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  "OK",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      print('Sign up error: $e');
    }
  }

  Future<void> _registerWithEmailAndPassword(
      BuildContext context, String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      // Navigate to the login page or any other page after successful registration
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => StudentRegistrationPage()),
      );
    } catch (e) {
      // Handle registration errors, display error message to the user
      Fluttertoast.showToast(
        msg: "Error! Double check & try again.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      print('Sign up error: $e');
    }
  }
}
