import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_management_system/admin/manage_students.dart';
import 'package:bus_management_system/admin/manage_drivers.dart';
import 'package:bus_management_system/admin/manage_buses.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Marker> _markers = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchDriverLocations();
  }

  Future<void> _fetchDriverLocations() async {
    QuerySnapshot driversSnapshot =
        await FirebaseFirestore.instance.collection('Drivers').get();

    setState(() {
      _markers = driversSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double latitude = data['latitude'] as double;
        double longitude = data['longitude'] as double;
        String driver = data['driverName'] as String;
        String assignedBus = data['assignedBus'] as String;

        return Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(latitude, longitude),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.directions_bus,
                color: Colors.red,
                size: 30.0,
              ),
              Positioned(
                top: -5, // Adjust this value to position the text properly
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.white, // Set white background color
                    borderRadius: BorderRadius.circular(
                        8.0), // Optional: Add border radius
                  ),
                  child: Text(
                    '$assignedBus',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          Tooltip(
            message: 'Sign Out',
            child: IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                _signOut();
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('Admin Menu', style: TextStyle(color: Colors.white)),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Row(
                children: [
                  Icon(Icons.directions_bus, color: Colors.blue),
                  SizedBox(width: 10),
                  Text('Buses', style: TextStyle(color: Colors.blue)),
                ],
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageBusesPage()),
                );
              },
            ),
            ListTile(
              title: Row(
                children: [
                  Icon(Icons.person, color: Colors.blue),
                  SizedBox(width: 10),
                  Text('Drivers', style: TextStyle(color: Colors.blue)),
                ],
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DriversMainPage()),
                );
              },
            ),
            ListTile(
              title: Row(
                children: [
                  Icon(Icons.school, color: Colors.blue),
                  SizedBox(width: 10),
                  Text('Students', style: TextStyle(color: Colors.blue)),
                ],
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageStudentsPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Horizontal row for dashlets
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DashboardCard(
                  title: 'Total Buses',
                  collection: 'Buses',
                ),
                DashboardCard(
                  title: 'Total Students',
                  collection: 'Students',
                ),
                DashboardCard(
                  title: 'Total Drivers',
                  collection: 'Drivers',
                ),
              ],
            ),
            SizedBox(height: 20), // Add spacing between dashlets and map
            // OpenStreetMap widget
            Expanded(
              child: FlutterMap(
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  MarkerLayer(
                    markers: _markers,
                  ),
                ],
                options: MapOptions(
                  initialCenter:
                      LatLng(-0.1566522, 36.1463934), // Initial map center
                  initialZoom: 13.0, // Initial zoom level
                ), //],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to sign out the user
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      // Redirect to sign-in page or any other desired destination
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String collection;

  DashboardCard({required this.title, required this.collection});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5.0,
      color: Color(0xFF132e57),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Container(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection(collection).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  int totalCount = snapshot.data!.docs.length;
                  return Column(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10.0),
                      Text(
                        totalCount.toString(),
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
