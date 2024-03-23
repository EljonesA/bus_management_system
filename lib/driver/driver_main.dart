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
  late List<String> _absentStudents = [];
  String _status = 'Off-Route'; // Define _status variable

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
      ;
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
          _fetchAbsentStudents();
        }
      });
    } catch (e) {
      print('Error fetching students data: $e');
    }
  }

  Future<void> _fetchAbsentStudents() async {
    try {
      DateTime currentDate = DateTime.now();
      currentDate =
          DateTime.utc(currentDate.year, currentDate.month, currentDate.day);

      // Query documents where the current date is within the date range
      QuerySnapshot snapshot =
          await _firestore.collection('AbsenseReport').get();

      // Extract student IDs from the documents
      List<String> absentStudentIds = [];
      snapshot.docs.forEach((doc) {
        String uptoDateString = doc['Upto'];
        // add leading 0 to month
        List<String> parts = uptoDateString.split('-');
        String month = parts[1].length == 1 ? '0${parts[1]}' : parts[1];
        uptoDateString = '${parts[0]}-$month-${parts[2]}';

        DateTime uptoDate = DateTime.parse(uptoDateString);
        //DateTime uptoDate = DateTime.parse("2024-03-13");
        if (uptoDate.isAfter(currentDate)) {
          absentStudentIds.add(doc['studentID'] as String);
        }
      });

      setState(() {
        _absentStudents = absentStudentIds;
      });
    } catch (e) {
      print('Error fetching absent students: $e');
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
              _signOut();
            },
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
            Tooltip(
              message: 'Provide Feedback',
              child: IconButton(
                icon: Icon(Icons.feedback, color: Colors.yellow),
                onPressed: () {
                  _showFeedbackDialog(); // Function to show feedback dialog
                },
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.black,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.green, width: 2),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.school,
                                  color: Colors.green,
                                  size: 48,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Students Assigned',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '${_students.length}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Card(
                          color: Colors.black,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.green, width: 2),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Absent Students',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '${_absentStudents.length}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 50),
                _buildMapWithEnRouteButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog() {
    String feedback = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Submit Feedback', style: TextStyle(color: Colors.white)),
          content: TextField(
            onChanged: (value) {
              feedback = value;
            },
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your feedback',
              hintStyle: TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                if (feedback.isNotEmpty) {
                  _submitFeedback(feedback);
                  Navigator.pop(context);
                }
              },
              child: Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: BorderSide(color: Colors.green, width: 2.0),
          ),
          contentTextStyle: TextStyle(color: Colors.white),
        );
      },
    );
  }

  Future<void> _submitFeedback(String feedback) async {
    try {
      // You can customize this logic to submit feedback to Firestore
      await _firestore.collection('Feedback').add({
        'driverEmail': _driverData['driverEmail'],
        'feedback': feedback,
        'Driver': _driverData['driverName'],
        'timestamp': FieldValue.serverTimestamp(),
        'Bus': _driverData['assignedBus'],
        'Tag': 'Driver',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Feedback submitted successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error submitting feedback: $e');
    }
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
    return Center(
      child: Card(
        elevation: 3,
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Container(
          width: double.infinity,
          child: DataTable(
            columnSpacing: 20.0,
            headingRowHeight: 40.0,
            dataRowHeight: 40.0,
            headingRowColor: MaterialStateColor.resolveWith(
              (states) => Colors.green,
            ),
            columns: [
              DataColumn(
                label: Text(
                  'Driver Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(''),
              ),
            ],
            rows: [
              DataRow(cells: [
                DataCell(Text(
                  'Name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                )),
                DataCell(Text(
                  _driverData['driverName'] ?? '',
                  style: TextStyle(color: Colors.black),
                )),
              ]),
              DataRow(cells: [
                DataCell(Text(
                  'ID',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                )),
                DataCell(Text(
                  _driverData['empID'] ?? '',
                  style: TextStyle(color: Colors.black),
                )),
              ]),
              DataRow(cells: [
                DataCell(Text(
                  'Assigned Bus',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                )),
                DataCell(Text(
                  _driverData['assignedBus'] ?? '',
                  style: TextStyle(color: Colors.black),
                )),
              ]),
              DataRow(cells: [
                DataCell(Text(
                  'Phone Number',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                )),
                DataCell(Text(
                  _driverData['phoneNumber'] ?? '',
                  style: TextStyle(color: Colors.black),
                )),
              ]),
              DataRow(cells: [
                DataCell(Text(
                  'License Number',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                )),
                DataCell(Text(
                  _driverData['driverLicenceNumber'] ?? '',
                  style: TextStyle(color: Colors.black),
                )),
              ]),
              DataRow(cells: [
                DataCell(Text(
                  'National ID',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                )),
                DataCell(Text(
                  _driverData['driverNationalID'] ?? '',
                  style: TextStyle(color: Colors.black),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsDataTable() {
    return Center(
      child: Card(
        elevation: 3,
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Container(
          width: double.infinity,
          child: DataTable(
            columnSpacing: 20.0,
            headingRowHeight: 40.0,
            dataRowHeight: 40.0,
            headingRowColor: MaterialStateColor.resolveWith(
              (states) => Colors.green,
            ),
            columns: [
              DataColumn(
                label: Text(
                  'Student ID',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Grade',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Medical Concerns',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Guardian Name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Guardian Contacts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            rows: _students.map((student) {
              // Determine status color
              Color statusColor = _absentStudents.contains(student['studentId'])
                  ? Colors.red
                  : Colors.green;

              // Determine status tooltip
              String statusTooltip =
                  _absentStudents.contains(student['studentId'])
                      ? 'Absent'
                      : 'Present';

              return DataRow(cells: [
                DataCell(
                  Text(
                    student['studentId'] ?? '',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                DataCell(
                  Text(
                    student['studentName'] ?? '',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                DataCell(
                  Text(
                    student['studentGrade'] ?? '',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                DataCell(
                  Text(
                    student['medicalConcerns'] ?? '',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                DataCell(
                  Text(
                    student['guardianName'] ?? '',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                DataCell(
                  Text(
                    student['guardianMobile'] ?? '',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                DataCell(
                  Tooltip(
                    message: statusTooltip,
                    child: Icon(Icons.circle, color: statusColor),
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMapWithEnRouteButton() {
    return Stack(
      children: [
        _buildMap(),
        Positioned(
          top: 20.0,
          right: 10.0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.green,
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(5.0),
              color: Colors.black,
            ),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return DropdownButton<String>(
                  value: _status,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                  iconSize: 24,
                  elevation: 16,
                  style: TextStyle(color: Colors.white),
                  underline: Container(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _status = newValue!;
                      _updateDriverStatus(
                          newValue); // Update status in Firestore
                    });
                  },
                  dropdownColor: Colors.black,
                  items: <String>['En-Route', 'Off-Route']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          value,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // route status update pop-up
  void _showStatusUpdateDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: BorderSide(color: Colors.green, width: 2.0),
          ),
          backgroundColor: Colors.black,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateDriverStatus(String status) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('Drivers')
          .where('driverEmail', isEqualTo: _driverEmail)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String driverId = querySnapshot.docs.first.id;
        await _firestore
            .collection('Drivers')
            .doc(driverId)
            .update({'status': status});

        _showStatusUpdateDialog('Route status updated successfully.');
      } else {
        _showStatusUpdateDialog('Driver document not found.');
      }
    } catch (e) {
      _showStatusUpdateDialog('Error updating route status: $e');
    }
  }

  Widget _buildMap() {
    // Get driver's latitude and longitude
    double latitude = _driverData['latitude'] ?? 0.0;
    double longitude = _driverData['longitude'] ?? 0.0;

    // Create a LatLng object for the driver's location
    LatLng driverLocation = LatLng(latitude, longitude);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.green, // Green border color
          width: 3.0, // Width of the border
        ),
      ),
      child: Stack(
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
                      child: Tooltip(
                        message: '    Driver Info:\n'
                            'Name: ${_driverData['driverName']}\n'
                            'Email: ${_driverData['driverEmail']}\n'
                            'Phone: ${_driverData['phoneNumber']}',
                        child: Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 30.0,
                        ),
                      ),
                    ),
                    // Markers for the guardians' locations
                    ..._guardianLocations.asMap().entries.map((entry) {
                      int index = entry.key;
                      LatLng guardianLocation = entry.value;
                      Color markerColor = _absentStudents
                              .contains(_students[index]['studentId'])
                          ? Colors.orange
                          : Colors.green;
                      return Marker(
                        width: 80.0,
                        height: 80.0,
                        point: guardianLocation,
                        child: Tooltip(
                          message: '     Student Info:\n'
                              'ID: ${_students[index]['studentId']}\n'
                              'Name: ${_students[index]['studentName']}\n'
                              'Grade: ${_students[index]['studentGrade']}\n'
                              'Guardian: ${_students[index]['guardianName']}',
                          child: Icon(
                            Icons.bus_alert,
                            color: markerColor,
                            size: 30.0,
                          ),
                        ),
                      );
                    }),
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
      ),
    );
  }
}
