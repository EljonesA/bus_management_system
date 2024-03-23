import 'package:flutter/material.dart';
import 'package:bus_management_system/login_screens/parent_login.dart';
import 'package:bus_management_system/login_screens/driver_login.dart';
import 'package:bus_management_system/login_screens/admin_login.dart';

class ChooseRolePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set background color to black
      body: Center(
        child: SizedBox(
          height: 500,
          width: 300,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 2),
              color: Colors.black, // Set container color to black
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.directions_bus,
                  size: 40, // Adjust the size of the icon
                  color: Colors.white, // Set icon color to white
                ),
                SizedBox(height: 10), // Add some spacing
                Text(
                  'Choose Role',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Set text color to white
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                RoleButton(
                  role: 'Parent',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ParentLoginPage()),
                    );
                  },
                ),
                RoleButton(
                  role: 'Driver',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DriverLoginPage()),
                    );
                  },
                ),
                RoleButton(
                  role: 'Admin',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminLoginPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RoleButton extends StatelessWidget {
  final String role;
  final VoidCallback onPressed;

  RoleButton({required this.role, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          primary: Colors.white, // Set button background color to white
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          role,
          style: TextStyle(
            fontSize: 18,
            color: Colors.black, // Set button text color to black
          ),
        ),
      ),
    );
  }
}
