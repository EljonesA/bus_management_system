import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class ParentViewPage extends StatefulWidget {
  @override
  _ParentViewPageState createState() => _ParentViewPageState();
}

class _ParentViewPageState extends State<ParentViewPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    print('First: $guardianEmail');
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Students')
          .where('guardianEmail', isEqualTo: guardianEmail)
          .get();

      print(guardianEmail);

      setState(() {
        _students = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });

      print("Data: $_students");

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
        child: Padding(
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
          return Center(
            child:
                CircularProgressIndicator(), // or any other loading indicator
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        if (snapshot.hasData) {
          List<Map<String, dynamic>> students = snapshot.data!;
          return SingleChildScrollView(
            child: Center(
              child: Card(
                color: Colors.white, // Background color
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
                          'Property',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Value',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    rows: [
                      DataRow(cells: [
                        DataCell(Text(
                          'Student ID',
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        )),
                        DataCell(Text(
                          students
                              .map((student) => student['studentId'] ?? '')
                              .join(','),
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        )),
                      ]),
                      DataRow(cells: [
                        DataCell(Text(
                          'Name',
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        )),
                        DataCell(Text(
                          students
                              .map((student) => student['studentName'] ?? '')
                              .join(','),
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        )),
                      ]),
                      DataRow(cells: [
                        DataCell(Text(
                          'Grade',
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        )),
                        DataCell(Text(
                          students
                              .map((student) => student['studentGrade'] ?? '')
                              .join(','),
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        )),
                      ]),
                      DataRow(cells: [
                        DataCell(Text(
                          'Medical Concerns',
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        )),
                        DataCell(Text(
                          students
                              .map(
                                  (student) => student['medicalConcerns'] ?? '')
                              .join(','),
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        )),
                      ]),
                      DataRow(cells: [
                        DataCell(Text(
                          'Guardian Name',
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        )),
                        DataCell(Text(
                          students
                              .map((student) => student['guardianName'] ?? '')
                              .join(','),
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        )),
                      ]),
                      DataRow(cells: [
                        DataCell(Text(
                          'Guardian Contact',
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        )),
                        DataCell(Text(
                          students
                              .map((student) => student['guardianMobile'] ?? '')
                              .join(','),
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        )),
                      ]),
                      DataRow(cells: [
                        DataCell(Text(
                          'Assigned Bus',
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        )),
                        DataCell(Text(
                          students
                              .map((student) => student['assignedBus'] ?? '')
                              .join(','),
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        )),
                      ]),
                      DataRow(cells: [
                        DataCell(Text(
                          'Status',
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        )),
                        DataCell(
                          Wrap(
                            children: students.map((student) {
                              return Icon(
                                student['isAbsent']
                                    ? Icons.circle
                                    : Icons.check_circle,
                                color: student['isAbsent']
                                    ? Colors.red
                                    : Colors.green,
                              );
                            }).toList(),
                          ),
                        ),
                      ]),
                      DataRow(cells: [
                        DataCell(Text(
                          'Revoke',
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        )),
                        DataCell(
                          Wrap(
                            children: students.map((student) {
                              return ElevatedButton(
                                onPressed: () {
                                  _revokeAbsenteism(student['studentId']);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: Text('Mark Present'),
                              );
                            }).toList(),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
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
        // Check if studentId is not null
        if (student['studentId'] != null) {
          // Fetch absence status for each student
          bool isAbsent = await _isStudentAbsent(student['studentId']);
          student['isAbsent'] = isAbsent;
          studentsWithStatus.add(student);
        } else {
          print('Student ID is null for student: ${student.toString()}');
        }
      }
    } catch (e) {
      print('Error fetching student data with absence status: $e');
    }

    return studentsWithStatus;
  }

// function to determine absence status
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
      // Show "No Bus assigned" message if driver data is empty
      sendEmailNotification();
      return Card(
        elevation: 3,
        margin: EdgeInsets.symmetric(vertical: 8),
        color: Colors.grey[350], // table background color
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bus not assigned yet to the student. Admin has been notified.',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Display driver information if available
      return SingleChildScrollView(
        child: Center(
          child: Container(
            width: double.infinity,
            child: Card(
              elevation: 3,
              margin: EdgeInsets.symmetric(vertical: 8),
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
                      'Property',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Value',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                rows: [
                  DataRow(cells: [
                    DataCell(Text(
                      'Name',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    )),
                    DataCell(Text(
                      _driverData['driverName'] ?? '',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    )),
                  ]),
                  DataRow(cells: [
                    DataCell(Text(
                      'ID',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    )),
                    DataCell(Text(
                      _driverData['empID'] ?? '',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    )),
                  ]),
                  DataRow(cells: [
                    DataCell(Text(
                      'Assigned Bus',
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
                  DataRow(cells: [
                    DataCell(Text(
                      'Contact',
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
                  ]),
                  DataRow(cells: [
                    DataCell(Text(
                      'Email Address',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    )),
                    DataCell(Text(
                      _driverData['driverEmail'] ?? '',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    )),
                  ]),
                  DataRow(cells: [
                    DataCell(Text(
                      'Gender',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    )),
                    DataCell(Text(
                      _driverData['driverGender'] ?? '',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    )),
                  ]),
                  DataRow(cells: [
                    DataCell(Text(
                      'National ID',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    )),
                    DataCell(Text(
                      _driverData['driverNationalID'] ?? '',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    )),
                  ]),
                  DataRow(cells: [
                    DataCell(Text(
                      'License Number',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    )),
                    DataCell(Text(
                      _driverData['driverLicenceNumber'] ?? '',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    )),
                  ]),
                  DataRow(cells: [
                    DataCell(Text(
                      'Bus Status',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    )),
                    DataCell(Text(
                      _driverData['status'] ?? '',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    )),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<void> sendEmailNotification() async {
    String username = 'topbus112@gmail.com'; // Your Gmail address
    String password = 'TopBusupport07'; // Your Gmail password

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username)
      ..recipients.add('eljones.odongo@gmail.com') // Admin's email address
      ..subject = 'New Student Waiting for Bus Assignment'
      ..text =
          'A new student is waiting to be assigned a bus. Please take action as soon as possible.';

    try {
      final sendReport = await send(message, smtpServer);
      print('Email sent: ${sendReport.toString()}');
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  Widget _buildMap() {
    return Stack(
      children: [
        Container(
          height: 500,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.green, // Set border color here
              width: 3.0, // Set border width here
            ),
          ),
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
                      message: '    Driver Info:\n'
                          'Name: ${_driverData['driverName']}\n'
                          'Email: ${_driverData['driverEmail']}\n'
                          'Phone: ${_driverData['phoneNumber']}\n'
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
              backgroundColor: Colors.black, // Set background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: BorderSide(color: Colors.green, width: 2), // Green border
              ),
              title: Text(
                'Report Absence',
                style: TextStyle(color: Colors.white), // Text color
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    dropdownColor:
                        Colors.black, // Set dropdown background color
                    value: duration,
                    items: [
                      DropdownMenuItem(
                          child: Text('1 Day',
                              style: TextStyle(color: Colors.white)),
                          value: '1 Day'),
                      DropdownMenuItem(
                          child: Text('1 Week',
                              style: TextStyle(color: Colors.white)),
                          value: '1 Week'),
                      DropdownMenuItem(
                          child: Text('Custom',
                              style: TextStyle(color: Colors.white)),
                          value: 'Custom'),
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
                            style: TextStyle(color: Colors.white), // Text color
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Custom Duration',
                              labelStyle:
                                  TextStyle(color: Colors.white), // Label color
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
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
                            dropdownColor:
                                Colors.black, // Set dropdown background color
                            value: 'Days',
                            items: [
                              DropdownMenuItem(
                                  child: Text('Days',
                                      style: TextStyle(color: Colors.white)),
                                  value: 'Days'),
                              DropdownMenuItem(
                                  child: Text('Weeks',
                                      style: TextStyle(color: Colors.white)),
                                  value: 'Weeks'),
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
                    style: TextStyle(color: Colors.white), // Text color
                    decoration: InputDecoration(
                      labelText: 'Reason for Absence',
                      labelStyle: TextStyle(color: Colors.white), // Label color
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
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
                  child: Text('Cancel',
                      style: TextStyle(color: Colors.white)), // Text color
                ),
                TextButton(
                  onPressed: () {
                    _submitAbsenceReport(reason, duration, customDuration);
                    Navigator.pop(context);
                  },
                  child: Text('Submit',
                      style: TextStyle(color: Colors.white)), // Text color
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
            decoration: InputDecoration(
              hintText: 'Enter your feedback',
              hintStyle: TextStyle(color: Colors.white),
            ),
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: BorderSide(color: Colors.green, width: 2.0),
          ),
          contentTextStyle: TextStyle(color: Colors.white),
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
        );
      },
    );
  }

  Future<void> _submitFeedback(String feedback) async {
    try {
      // You can customize this logic to submit feedback to Firestore
      await _firestore.collection('Feedback').add({
        'parentEmail': _guardianEmail,
        'guardianName': _students[0]['guardianName'],
        'feedback': feedback,
        'Driver': _driverData['driverName'],
        'timestamp': FieldValue.serverTimestamp(),
        'Tag': 'Guardian',
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
}
