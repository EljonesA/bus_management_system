import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_management_system/admin/manage_students.dart';
import 'package:bus_management_system/admin/manage_drivers.dart';
import 'package:bus_management_system/admin/manage_buses.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bus_management_system/choose_role_page.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class MarkerData {
  final Marker marker;
  final String driver;

  MarkerData({required this.marker, required this.driver});
}

class _AdminPageState extends State<AdminPage> {
  List<Marker> _markers = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late MapController _mapController;
  String dereva = '';

  @override
  void initState() {
    super.initState();
    _fetchDriverLocations();
    _mapController = MapController();
  }

  Future<void> _fetchDriverLocations() async {
    QuerySnapshot driversSnapshot =
        await FirebaseFirestore.instance.collection('Drivers').get();

    List<Marker> markers = [];
    for (var doc in driversSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      double latitude = data['latitude'] as double;
      double longitude = data['longitude'] as double;
      String driver = data['driverName'] as String;
      String assignedBus = data['assignedBus'] as String;

      dereva = driver;

      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(latitude, longitude),
          child: Container(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.directions_bus,
                  color: Colors.red,
                  size: 30.0,
                ),
                Positioned(
                  top: -5,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
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
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
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
              // navigate back to login screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ChooseRolePage()),
              );
            },
          ),
        ],
      ),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width *
            0.3, // Adjust the width as needed
        child: Drawer(
          child: Container(
            color: Colors.grey[
                350], // Set the background color of the drawer/navigation menu
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                Container(
                  height: 150, // Adjust the height of the header as needed
                  color: Colors.green, // Set the background color of the header
                  child: Center(
                    child: Text(
                      'Admin Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.directions_bus,
                      color: Colors.black), // Add an icon before the text
                  title: Text('Buses', style: TextStyle(color: Colors.black)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ManageBusesPage()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.drive_eta,
                      color: Colors.black), // Add an icon before the text
                  title: Text('Drivers', style: TextStyle(color: Colors.black)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DriversMainPage()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.school,
                      color: Colors.black), // Add an icon before the text
                  title:
                      Text('Students', style: TextStyle(color: Colors.black)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ManageStudentsPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: DashboardCard(
                    title: 'Buses',
                    collection: 'Buses',
                    icon: Icons.directions_bus,
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: DashboardCard(
                    title: 'Students',
                    collection: 'Students',
                    icon: Icons.school,
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: DashboardCard(
                    title: 'Drivers',
                    collection: 'Drivers',
                    icon: Icons.drive_eta,
                  ),
                ),
              ],
            ),
            // for spacing between the cards & guardian feedback section
            SizedBox(height: 20.0),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Feedback')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    List<DocumentSnapshot> feedbackDocs = snapshot.data!.docs;
                    List<DocumentSnapshot> guardianFeedback = [];
                    List<DocumentSnapshot> driverIssues = [];

                    feedbackDocs.forEach((doc) {
                      if (doc['Tag'] == 'Guardian') {
                        guardianFeedback.add(doc);
                      } else if (doc['Tag'] == 'Driver') {
                        driverIssues.add(doc);
                      }
                    });

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: 20.0),
                                Text(
                                  'Guardian Feedback',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 10.0),
                                Container(
                                  color: Colors
                                      .black, // Set the background color to black
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 10.0,
                                    runSpacing: 10.0,
                                    children:
                                        guardianFeedback.map((feedbackDoc) {
                                      return Card(
                                        elevation: 5.0,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Feedback: ${feedbackDoc['feedback']}',
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SizedBox(height: 5.0),
                                              Text(
                                                'Guardian Name: ${feedbackDoc['guardianName']}',
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SizedBox(height: 5.0),
                                              Text(
                                                'Email: ${feedbackDoc['parentEmail']}',
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SizedBox(height: 5.0),
                                              Text(
                                                'Driver: ${feedbackDoc['Driver']}',
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SizedBox(height: 5.0),
                                              Text(
                                                'Submission Date: ${feedbackDoc['timestamp'].toDate().toString()}',
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                SizedBox(height: 20.0),
                                Text(
                                  'Driver Issues',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 10.0),
                                Container(
                                  color: Colors
                                      .black, // Set the background color to black
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 10.0,
                                    runSpacing: 10.0,
                                    children: driverIssues.map((feedbackDoc) {
                                      return Card(
                                        elevation: 5.0,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Feedback: ${feedbackDoc['feedback']}',
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SizedBox(height: 5.0),
                                              Text(
                                                'Driver Name: ${feedbackDoc['Driver']}',
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SizedBox(height: 5.0),
                                              Text(
                                                'Driver Email: ${feedbackDoc['driverEmail']}',
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SizedBox(height: 5.0),
                                              Text(
                                                'Submission Date: ${feedbackDoc['timestamp'].toDate().toString()}',
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              flex: 2, // value to increase map height
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.green, // Apply your theme color here
                    width: 2.0,
                  ),
                ),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        center: LatLng(-0.1566522, 36.1463934),
                        zoom: 13.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        ),
                        MarkerLayer(
                          markers: _markers.map((marker) {
                            return Marker(
                              width: marker.width,
                              height: marker.height,
                              point: marker.point,
                              child: Tooltip(
                                message: 'Bus Info:\n'
                                    'Driver: loading... \n',
                                child: marker.child,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 20.0,
                      right: 20.0,
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _mapController.move(_mapController.center,
                                  _mapController.zoom + 1);
                            },
                            style: ElevatedButton.styleFrom(
                              primary:
                                  Colors.green, // Apply your theme color here
                              shape: CircleBorder(),
                            ),
                            child: Icon(Icons.add, color: Colors.white),
                          ),
                          SizedBox(height: 10.0),
                          ElevatedButton(
                            onPressed: () {
                              _mapController.move(_mapController.center,
                                  _mapController.zoom - 1);
                            },
                            style: ElevatedButton.styleFrom(
                              primary:
                                  Colors.green, // Apply your theme color here
                              shape: CircleBorder(),
                            ),
                            child: Icon(Icons.remove, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String collection;
  final IconData icon;

  DashboardCard(
      {required this.title, required this.collection, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5.0,
      color: Colors.black, // Apply your theme color here
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(
          color: Colors.green, // Apply your theme color here
          width: 2.0,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Apply your theme color here
              ),
            ),
            SizedBox(height: 10.0),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection(collection).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  int totalCount = snapshot.data!.docs.length;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: Colors.white, // Apply your theme color here
                        size: 24.0,
                      ),
                      SizedBox(width: 5.0),
                      Text(
                        totalCount.toString(),
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Apply your theme color here
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
