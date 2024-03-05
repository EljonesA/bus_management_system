// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:geolocator/geolocator.dart';
// import 'driver_map_screen.dart'; // Import the MapScreen

// class DriverPage extends StatefulWidget {
//   @override
//   _DriverPageState createState() => _DriverPageState();
// }

// class _DriverPageState extends State<DriverPage> {
//   String? _selectedDriver;
//   Map<String, dynamic>? _selectedDriverData;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Driver Dashboard'),
//         backgroundColor: Colors.black, // Uber black color
//       ),
//       body: Center(
//         child: SingleChildScrollView(
//           child: Container(
//             padding: EdgeInsets.all(16.0),
//             decoration: BoxDecoration(
//               color: Colors.grey[200], // Uber grey color
//               borderRadius: BorderRadius.circular(15.0),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildDriverDropdown(),
//                 SizedBox(height: 20),
//                 _selectedDriverData != null
//                     ? _buildDriverDetails()
//                     : Text('Select a driver to view details'),
//                 SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: _shareLocation,
//                   child: Text('Share Location'),
//                   style: ElevatedButton.styleFrom(
//                     primary: Colors.black, // Uber black color
//                     onPrimary: Colors.white, // Uber white color
//                     elevation: 3,
//                     padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDriverDropdown() {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 20.0),
//       decoration: BoxDecoration(
//         color: Colors.white, // Uber white color
//         borderRadius: BorderRadius.circular(10.0),
//       ),
//       child: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('Drivers').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Text('Error: ${snapshot.error}');
//           }

//           if (!snapshot.hasData) {
//             return CircularProgressIndicator();
//           }

//           List<DropdownMenuItem<String>> items = [];
//           for (var doc in snapshot.data!.docs) {
//             String? driverName = doc['driverName'];
//             if (driverName != null) {
//               items.add(
//                 DropdownMenuItem(
//                   value: driverName,
//                   child: Text(driverName),
//                 ),
//               );
//             }
//           }

//           return DropdownButtonFormField(
//             value: _selectedDriver,
//             onChanged: (newValue) {
//               setState(() {
//                 _selectedDriver = newValue as String?;
//                 _selectedDriverData = null; // Reset selected driver data
//                 _fetchDriverDetails();
//               });
//             },
//             items: items,
//             decoration: InputDecoration(
//               labelText: 'Select Driver',
//               border: InputBorder.none,
//             ),
//           );
//         },
//       ),
//     );
//   }

//   void _fetchDriverDetails() async {
//     if (_selectedDriver != null) {
//       DocumentSnapshot snapshot = await FirebaseFirestore.instance
//           .collection('Drivers')
//           .where('driverName', isEqualTo: _selectedDriver)
//           .get()
//           .then((querySnapshot) => querySnapshot.docs.first);

//       setState(() {
//         _selectedDriverData = snapshot.data() as Map<String, dynamic>?;
//       });
//     }
//   }

//   Widget _buildDriverDetails() {
//     return Container(
//       padding: EdgeInsets.all(16.0),
//       margin: EdgeInsets.only(top: 20.0),
//       decoration: BoxDecoration(
//         color: Colors.white, // Uber white color
//         borderRadius: BorderRadius.circular(10.0),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: _selectedDriverData!.entries.map((entry) {
//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 entry.key,
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//               SizedBox(height: 5),
//               Text(
//                 entry.value.toString(),
//                 style: TextStyle(
//                   color: Colors.black54,
//                 ),
//               ),
//               SizedBox(height: 10),
//             ],
//           );
//         }).toList(),
//       ),
//     );
//   }

//   Future<void> _shareLocation() async {
//     LocationPermission permission = await Geolocator.requestPermission();
//     if (permission == LocationPermission.denied) {
//       // Handle denied permission
//       return;
//     }

//     Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);

//     if (_selectedDriver != null) {
//       await FirebaseFirestore.instance
//           .collection('Drivers')
//           .where('driverName', isEqualTo: _selectedDriver)
//           .get()
//           .then((querySnapshot) {
//         querySnapshot.docs.forEach((doc) {
//           doc.reference.update({
//             'latitude': position.latitude,
//             'longitude': position.longitude,
//           });
//         });
//       });

//       // Navigate to the MapScreen
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => MapScreen()),
//       );
//     }
//   }
// }
