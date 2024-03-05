import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParentViewPage extends StatefulWidget {
  @override
  _ParentViewPageState createState() => _ParentViewPageState();
}

class _ParentViewPageState extends State<ParentViewPage> {
  late String _selectedDriverId;
  late LatLng _driverLocation;
  List<String> _driverIds = [];

  @override
  void initState() {
    super.initState();
    _selectedDriverId = ''; // Initialize with an empty string
    _fetchDriverIds();
  }

  Future<void> _fetchDriverIds() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('Drivers').get();

    setState(() {
      _driverIds = querySnapshot.docs.map((doc) => doc.id).toList(); // Get IDs
      if (_driverIds.isNotEmpty) {
        _selectedDriverId = _driverIds[0]; // Set the default selected ID
        _fetchDriverLocation(_selectedDriverId);
      }
    });
  }

  Future<void> _fetchDriverLocation(String driverId) async {
    DocumentSnapshot driverSnapshot = await FirebaseFirestore.instance
        .collection('Drivers')
        .doc(driverId)
        .get();

    double latitude = driverSnapshot['latitude'];
    double longitude = driverSnapshot['longitude'];

    setState(() {
      _driverLocation = LatLng(latitude, longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Parent View')),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: _driverLocation,
                zoom: 10.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: _selectedDriverId,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedDriverId = newValue;
                  _fetchDriverLocation(_selectedDriverId);
                });
              }
            },
            items: _driverIds.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text('Driver ID: $value'),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
