import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DriverPage extends StatefulWidget {
  @override
  _DriverPageState createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String _driverEmail;
  late Map<String, dynamic> _driverData = {};
  late List<Map<String, dynamic>> _students = [];
  List<LatLng> _guardianLocations = [];
  List<Polyline> _polylines = [];

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _driverEmail = user.email!;
      });
      await _fetchDriverData(_driverEmail);
      await _fetchStudentsData(_driverData['assignedBus']);
    }
  }

  Future<void> _fetchDriverData(String email) async {
    try {
      DocumentSnapshot snapshot = await _firestore
          .collection('Drivers')
          .where('driverEmail', isEqualTo: email)
          .limit(1)
          .get()
          .then((querySnapshot) => querySnapshot.docs.first);

      setState(() {
        _driverData = snapshot.data() as Map<String, dynamic>;
      });
    } catch (e) {
      print('Error fetching driver data: $e');
    }
  }

  Future<void> _fetchStudentsData(String assignedBus) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Students')
          .where('assignedBus', isEqualTo: assignedBus)
          .get();

      setState(() {
        _students = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        // Extract guardian locations
        _guardianLocations = _students
            .map((student) => LatLng(
                  student['latitude'] ?? 0.0,
                  student['longitude'] ?? 0.0,
                ))
            .toList();
        if (_guardianLocations.isNotEmpty) {
          List<LatLng> waypoints = [
            LatLng(
              _driverData['latitude'] ?? 0.0,
              _driverData['longitude'] ?? 0.0,
            ),
            ..._guardianLocations,
          ];
          _fetchRoute(waypoints);
        }
      });
    } catch (e) {
      print('Error fetching students data: $e');
    }
  }

  String _distance = '';
  List<String> _instructions = [];

  Future<void> _fetchRoute(List<LatLng> waypoints) async {
    final String apiKey = '7c30bb61-cba7-4f00-b1f3-4ae494ecb0a4';
    final String baseUrl = 'https://graphhopper.com/api/1/route';
    final String profile = 'car';

    // Convert waypoints to coordinates string
    String coordinates = waypoints
        .map((point) => '${point.latitude},${point.longitude}')
        .join('&point=');

    final String url =
        '$baseUrl?point=$coordinates&vehicle=$profile&key=$apiKey&points_encoded=false&type=json&instructions=true';
    print(url);

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['paths'] != null && decoded['paths'].isNotEmpty) {
          List<dynamic> paths = decoded['paths'];
          // Access the 'points' field
          List<dynamic> points = paths[0]['points']['coordinates'];

          // Get distance
          _distance = (paths[0]['distance'] / 1000).toStringAsFixed(2) + ' km';
          print("Distance: $_distance");

          // Get instructions
          _instructions = paths[0]['instructions'].map<String>((ins) {
            return ins['text'] as String;
          }).toList();
          print("Instructions: $_instructions");

          List<LatLng> polylineCoordinates = [];
          for (var point in points) {
            double lat = point[1];
            double lng = point[0];
            polylineCoordinates.add(LatLng(lat, lng));
          }
          setState(() {
            _polylines.add(
              Polyline(
                points: polylineCoordinates,
                color: Colors.blue,
                strokeWidth: 5,
              ),
            );
          });
        } else {
          print('No routes found.');
        }
      } else {
        print('Failed to fetch route: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
  }

  void _drawRoute(List<LatLng> routePoints) {
    List<LatLng> polylineCoordinates = [];
    for (var point in routePoints) {
      polylineCoordinates.add(LatLng(point.latitude, point.longitude));
    }

    // Create a new Polyline and add it to the list
    Polyline polyline = Polyline(
      points: polylineCoordinates,
      color: Colors.blue,
      strokeWidth: 5,
    );

    // Update the UI to draw the route
    setState(() {
      _polylines.add(polyline);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Details'),
        actions: [
          Tooltip(
            message: 'Sign Out',
            child: IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () {
                _signOut();
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            _buildDriverDataTable(),
            SizedBox(height: 40),
            Text(
              'Students Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            _students.isNotEmpty
                ? _buildStudentsDataTable()
                : Center(
                    child: CircularProgressIndicator(),
                  ),
            SizedBox(height: 40),
            Text(
              'Driver Location',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            _buildMap(),
          ],
        ),
      ),
    );
  }

  // Method to sign out the user
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pop();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Widget _buildDriverDataTable() {
    return DataTable(
      columnSpacing: 20.0,
      headingRowHeight: 40.0,
      dataRowHeight: 40.0,
      columns: [
        DataColumn(
          label: Text(
            'Field',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Value',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
      rows: _driverData.entries.map((entry) {
        return DataRow(cells: [
          DataCell(Text(
            entry.key,
            style: TextStyle(fontWeight: FontWeight.bold),
          )),
          DataCell(Text(entry.value.toString())),
        ]);
      }).toList(),
    );
  }

  Widget _buildStudentsDataTable() {
    return DataTable(
      columnSpacing: 20.0,
      headingRowHeight: 40.0,
      dataRowHeight: 40.0,
      columns: [
        DataColumn(
          label: Text(
            'Student ID',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Name',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Grade',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Assigned Bus',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Guardian Name',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Guardian Contacts',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
      rows: _students.map((student) {
        return DataRow(cells: [
          DataCell(Text(student['studentId'] ?? '')),
          DataCell(Text(student['studentName'] ?? '')),
          DataCell(Text(student['studentGrade'] ?? '')),
          DataCell(Text(student['assignedBus'] ?? '')),
          DataCell(Text(student['guardianName'] ?? '')),
          DataCell(Text(student['guardianEmail'] ?? '')),
        ]);
      }).toList(),
    );
  }

  Widget _buildMap() {
    // Get driver's latitude and longitude
    double latitude = _driverData['latitude'] ?? 0.0;
    double longitude = _driverData['longitude'] ?? 0.0;

    // Create a LatLng object for the driver's location
    LatLng driverLocation = LatLng(latitude, longitude);

    return Stack(
      children: [
        Container(
          height: 500,
          child: FlutterMap(
            options: MapOptions(
              center: LatLng(-1.286389, 36.817223),
              zoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              MarkerLayer(
                markers: [
                  // Marker for the driver's location
                  Marker(
                    width: 80.0,
                    height: 80.0,
                    point: driverLocation,
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 30.0,
                    ),
                  ),
                  // Markers for the guardians' locations
                  ..._guardianLocations.map((guardianLocation) => Marker(
                        width: 80.0,
                        height: 80.0,
                        point: guardianLocation,
                        child: Icon(
                          Icons.location_pin,
                          color: Colors.green,
                          size: 30.0,
                        ),
                      )),
                ],
              ),
              PolylineLayer(
                polylines: _polylines,
              ),
            ],
          ),
        ),
        Positioned(
          width: 300,
          // height: 300,
          top: 16,
          left: 16,
          child: Container(
            padding: EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distance: $_distance',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Route Instructions:',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _instructions.map((instruction) {
                    return Text('- $instruction');
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
