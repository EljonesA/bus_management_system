import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:bus_management_system/admin/admin_main.dart';

class AdminLoginPage extends StatelessWidget {
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
                  'Admin Login',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                Image.asset('images/admin_icon.png',
                    width: 150), // Add admin icon
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
                          builder: (context) => AdminSignUpPage()),
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
        MaterialPageRoute(builder: (context) => AdminPage()),
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

class AdminSignUpPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Sign Up'),
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
                  'Admin Sign Up',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                Image.asset('images/admin_icon.png',
                    width: 150), // Add admin icon
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
                    _registerWithEmailAndPassword(context, email, password);
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

  Future<void> _registerWithEmailAndPassword(
      BuildContext context, String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      // Navigate to the login page or any other page after successful registration
    } catch (e) {
      // Handle registration errors, display error message to the user
      Fluttertoast.showToast(
        msg: "Sign up error: $e",
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
