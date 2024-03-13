import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class ParentViewPage extends StatefulWidget {
  @override
  _ParentViewPageState createState() => _ParentViewPageState();
}

class _ParentViewPageState extends State<ParentViewPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 1; // Default index for Home

  late String _guardianEmail;
  late List<Map<String, dynamic>> _students = [];
  late Map<String, dynamic> _driverData = {};
  late LatLng _driverLocation = LatLng(0.0, 0.0);
  late LatLng _guardianLocation = LatLng(0.0, 0.0);
  late MapController _mapController;
  List<LatLng> _routeCoordinates = [];
  late double _distance = 0.0;
  late String _eta = '';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _guardianEmail = user.email!;
      });
      await _fetchStudentsData(_guardianEmail);
    }
  }

  Future<void> _fetchStudentsData(String guardianEmail) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Students')
          .where('guardianEmail', isEqualTo: guardianEmail)
          .get();

      setState(() {
        _students = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });

      if (_students.isNotEmpty) {
        await _fetchDriverData(_students[0]['assignedBus']);
        // Fetch guardian location if available
        await _fetchGuardianLocation();
      }
    } catch (e) {
      print('Error fetching students data: $e');
    }
  }

  Future<void> _fetchDriverData(String assignedBus) async {
    try {
      DocumentSnapshot snapshot = await _firestore
          .collection('Drivers')
          .where('assignedBus', isEqualTo: assignedBus)
          .limit(1)
          .get()
          .then((querySnapshot) => querySnapshot.docs.first);

      setState(() {
        _driverData = snapshot.data() as Map<String, dynamic>;
        // Extract driver location
        _driverLocation = LatLng(
          _driverData['latitude'] ?? 0.0,
          _driverData['longitude'] ?? 0.0,
        );
      });
    } catch (e) {
      print('Error fetching driver data: $e');
    }
  }

  Future<void> _fetchGuardianLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        // > alert guardian to allow to use service
        print("Location access denied");
        return;
      }

      // Get the current position (latitude and longitude)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _guardianLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Error fetching guardian location: $e');
    }
  }

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
          print(points);

          // Process route points and draw on the map
          List<LatLng> routeCoordinates = points.map((point) {
            return LatLng(
                point[1], point[0]); // GeoJSON format [longitude, latitude]
          }).toList();

          // Draw route on the map
          _drawRoute(routeCoordinates);

          // Calculate distance
          double distanceInMeters = paths[0]['distance'].toDouble();
          double distanceInKms = distanceInMeters / 1000;

          // Calculate estimated arrival time (in milliseconds)
          int estimatedTimeInSeconds = paths[0]['time'];
          int estimatedTimeInMilliseconds = estimatedTimeInSeconds * 1000;
          // Convert milliseconds to DateTime for display
          DateTime estimatedArrivalTime = DateTime.now().add(
            Duration(milliseconds: estimatedTimeInMilliseconds),
          );

          setState(() {
            _distance = distanceInKms;
            _eta = estimatedArrivalTime.toString();
          });
        }
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
  }

  void _drawRoute(List<LatLng> routeCoordinates) {
    setState(() {
      // Update the list of route coordinates in the widget state
      _routeCoordinates = routeCoordinates;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Add navigation logic based on the selected index
    switch (index) {
      case 0:
        // Navigate to Driver page
        // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => DriverPage()));
        break;
      case 1:
        // Navigate to Home page (current page)
        break;
      case 2:
        // Navigate to Map page
        // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => MapPage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parent View'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
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
              'Student Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            _buildStudentsDataTable(),
            SizedBox(height: 40),
            Text(
              'Driver Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            _buildDriverInfo(),
            SizedBox(height: 40),
            Text(
              'Bus Location',
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
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        backgroundColor: Colors.transparent, // Adjust as needed
        color: Colors.green, // Adjust color to match Bolt's green
        items: [
          Icon(Icons.drive_eta, color: Colors.white), // Icon for Driver
          Icon(Icons.home, color: Colors.white), // Icon for Home
          Icon(Icons.map, color: Colors.white), // Icon for Map
        ],
        onTap: _onItemTapped, // Handle navigation
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAbsenceReportDialog();
        },
        tooltip: 'Report Absence',
        child: Icon(Icons.calendar_month_outlined),
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

  Widget _buildStudentsDataTable() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchStudentDataWithAbsenceStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // or any other loading indicator
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (snapshot.hasData) {
          List<Map<String, dynamic>> students = snapshot.data!;
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8),
            child: DataTable(
              columnSpacing: 20.0,
              headingRowHeight: 40.0,
              dataRowHeight: 40.0,
              headingRowColor: MaterialStateColor.resolveWith(
                  (states) => Colors.green), // Green background for header
              columns: [
                DataColumn(
                  label: Text(
                    'Student ID',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white), // White text color for header
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Name',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white), // White text color for header
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Grade',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white), // White text color for header
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Assigned Bus',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white), // White text color for header
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Status',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white), // White text color for header
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Revoke',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white), // White text color for header
                  ),
                )
              ],
              rows: students.map((student) {
                // Determine the color of the status indicator
                Color statusColor =
                    student['isAbsent'] ? Colors.red : Colors.green;

                return DataRow(cells: [
                  DataCell(Text(
                    student['studentId'] ?? '',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  )),
                  DataCell(Text(
                    student['studentName'] ?? '',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  )),
                  DataCell(Text(
                    student['studentGrade'] ?? '',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  )),
                  DataCell(Text(
                    student['assignedBus'] ?? '',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  )),
                  DataCell(
                    // Display the status indicator
                    Icon(
                      Icons.circle,
                      color: statusColor,
                    ),
                  ),
                  DataCell(
                    ElevatedButton(
                      onPressed: () {
                        _revokeAbsenteism(student['studentId']);
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.black, // Background color
                        onPrimary: Colors.white, // Text color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              8.0), // Adjust the radius as needed
                        ),
                      ),
                      child: Text('Mark Present'),
                    ),
                  ),
                ]);
              }).toList(),
            ),
          );
        }
        return Container(); // Return an empty container if no data available
      },
    );
  }

  Future<void> _revokeAbsenteism(String studentId) async {
    try {
      await _firestore
          .collection('AbsenseReport')
          .where('studentID', isEqualTo: studentId)
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          doc.reference.delete();
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Absenteism revoked successfully'),
          duration: Duration(seconds: 2),
        ),
      );
      // Trigger UI refresh
      setState(() {});
    } catch (e) {
      print('Error revoking absenteism: $e');
    }
  }

  Future<List<Map<String, dynamic>>>
      _fetchStudentDataWithAbsenceStatus() async {
    List<Map<String, dynamic>> studentsWithStatus = [];

    try {
      for (var student in _students) {
        // Fetch absence status for each student
        bool isAbsent = await _isStudentAbsent(student['studentId']);
        student['isAbsent'] = isAbsent;
        studentsWithStatus.add(student);
      }
    } catch (e) {
      print('Error fetching student data with absence status: $e');
    }

    return studentsWithStatus;
  }

// Example function to determine absence status (you can replace it with your own logic)
  Future<bool> _isStudentAbsent(String studentId) async {
    try {
      // Get the current date
      DateTime currentDate = DateTime.now();

      // Retrieve AbsenceReport records for the student
      QuerySnapshot snapshot = await _firestore
          .collection('AbsenseReport')
          .where('studentID', isEqualTo: studentId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Loop through each AbsenceReport record
        for (QueryDocumentSnapshot doc in snapshot.docs) {
          // Get the 'Upto' date from the AbsenceReport record
          String uptoDateString = doc['Upto'];

          // Parse the 'Upto' date string to DateTime
          List<String> dateParts = uptoDateString.split('-');
          int year = int.parse(dateParts[0]);
          int month = int.parse(dateParts[1]);
          int day = int.parse(dateParts[2]);

          DateTime uptoDate = DateTime(year, month, day);

          // Check if the current date is less than or equal to the 'Upto' date
          if (currentDate.isBefore(uptoDate) ||
              currentDate.isAtSameMomentAs(uptoDate)) {
            // Student is marked as absent
            return true;
          }
        }
      }
    } catch (e) {
      print('Error checking student absence: $e');
    }

    // Student is not marked as absent
    return false;
  }

  Widget _buildDriverInfo() {
    if (_driverData.isEmpty) {
      // Show a loading indicator if driver data is not available yet
      return Card(
        elevation: 3,
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Fetching driver data...',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16.0),
              LinearProgressIndicator(
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        elevation: 3,
        margin: EdgeInsets.symmetric(vertical: 8),
        child: DataTable(
          columnSpacing: 20.0,
          headingRowHeight: 40.0,
          dataRowHeight: 40.0,
          headingRowColor: MaterialStateColor.resolveWith(
              (states) => Colors.green), // Green background for header
          columns: [
            DataColumn(
              label: Text(
                'Driver Name',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white), // White text color for header
              ),
            ),
            DataColumn(
              label: Text(
                'Contact',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white), // White text color for header
              ),
            ),
            DataColumn(
              label: Text(
                'Bus',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white), // White text color for header
              ),
            ),
          ],
          rows: [
            DataRow(cells: [
              DataCell(Text(
                _driverData['driverName'] ?? '',
                style: TextStyle(
                  color: Colors.black,
                ),
              )),
              DataCell(Text(
                _driverData['phoneNumber'] ?? '',
                style: TextStyle(
                  color: Colors.black,
                ),
              )),
              DataCell(Text(
                _driverData['assignedBus'] ?? '',
                style: TextStyle(
                  color: Colors.black,
                ),
              )),
            ]),
          ],
        ),
      );
    }
  }

  Widget _buildMap() {
    return Stack(
      children: [
        Container(
          height: 300,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: LatLng(-1.286389, 36.817223),
              zoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              if (_routeCoordinates.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routeCoordinates,
                      color: Colors.blue,
                      strokeWidth: 3.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 80.0,
                    height: 80.0,
                    point: _driverLocation,
                    child: Tooltip(
                      message: 'Driver Info:\n'
                          'Name: ${_driverData['driverName']}\n'
                          'Email: ${_driverData['driverEmail']}\n'
                          'Phone: ${_driverData['driverPhone']}\n'
                          'Bus: ${_driverData['assignedBus']}',
                      child: Icon(
                        Icons.bus_alert,
                        color: Colors.red,
                        size: 30.0,
                      ),
                    ),
                  ),
                  Marker(
                    width: 80.0,
                    height: 80.0,
                    point: _guardianLocation,
                    child: Icon(
                      Icons.person_pin_circle,
                      color: Colors.green,
                      size: 30.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 16.0,
          right: 16.0,
          child: ElevatedButton(
            onPressed: () {
              // Call a method to fetch and draw the route
              _fetchRoute([_driverLocation, _guardianLocation]);
            },
            style: ElevatedButton.styleFrom(
              primary: Colors.black, // Background color
              onPrimary: Colors.white, // Text color
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(8.0), // Adjust the radius as needed
              ),
            ),
            child: Text('View Route'),
          ),
        ),
        if (_distance != 0.0 && _eta.isNotEmpty)
          Positioned(
            top: 16.0,
            left: 16.0,
            child: Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 6.0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Distance: ${_distance.toStringAsFixed(2)} km',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ETA: $_eta',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showAbsenceReportDialog() {
    String reason = '';
    String duration = '1 Day'; // Default duration
    int customDuration = 1; // Default custom duration

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title:
                  Text('Report Absence', style: TextStyle(color: Colors.black)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: duration,
                    items: [
                      DropdownMenuItem(child: Text('1 Day'), value: '1 Day'),
                      DropdownMenuItem(child: Text('1 Week'), value: '1 Week'),
                      DropdownMenuItem(child: Text('Custom'), value: 'Custom'),
                    ],
                    onChanged: (value) {
                      setState(() {
                        duration = value!;
                      });
                    },
                  ),
                  if (duration == 'Custom') ...[
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            style: TextStyle(color: Colors.black),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Custom Duration',
                              labelStyle: TextStyle(color: Colors.black),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                              ),
                            ),
                            onChanged: (value) {
                              customDuration = int.tryParse(value) ?? 1;
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: 'Days',
                            items: [
                              DropdownMenuItem(
                                  child: Text('Days'), value: 'Days'),
                              DropdownMenuItem(
                                  child: Text('Weeks'), value: 'Weeks'),
                            ],
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 10),
                  TextFormField(
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Reason for Absence',
                      labelStyle: TextStyle(color: Colors.black),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    onChanged: (value) {
                      reason = value;
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel', style: TextStyle(color: Colors.black)),
                ),
                TextButton(
                  onPressed: () {
                    _submitAbsenceReport(reason, duration, customDuration);
                    Navigator.pop(context);
                  },
                  child: Text('Submit', style: TextStyle(color: Colors.black)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitAbsenceReport(
      String reason, String duration, int customDuration) async {
    try {
      if (_students.isNotEmpty) {
        String studentID = _students[0]['studentId'];
        String assignedBus = _students[0]['assignedBus'];
        DateTime now = DateTime.now();
        String date = '${now.year}-${now.month}-${now.day}';
        String from_date = '${now.year}-${now.month}-${now.day}';

        // Adjust date based on duration
        if (duration == '1 Week') {
          now = now.add(Duration(days: 7));
          date = '${now.year}-${now.month}-${now.day}';
        } else if (duration == '1 Day') {
          now = now.add(Duration(days: 1));
          date = '${now.year}-${now.month}-${now.day}';
        } else if (duration == 'Custom') {
          if (customDuration != null) {
            if (duration == 'Days') {
              now = now.add(Duration(days: customDuration));
            } else if (duration == 'Weeks') {
              now = now.add(Duration(days: customDuration * 7));
            }
            date = '${now.year}-${now.month}-${now.day}';
          }
        }

        await _firestore.collection('AbsenseReport').add({
          'studentID': studentID,
          'assignedBus': assignedBus,
          'From': from_date,
          'Upto': date,
          'Reason': reason,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Absence reported successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      // Trigger UI refresh
      setState(() {});
    } catch (e) {
      print('Error submitting absence report: $e');
    }
  }
}
