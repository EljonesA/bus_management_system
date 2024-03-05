import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

class ParentViewPage extends StatefulWidget {
  @override
  _ParentViewPageState createState() => _ParentViewPageState();
}

class _ParentViewPageState extends State<ParentViewPage> {
  late String _selectedDriverId;
  late LatLng _driverLocation =
      LatLng(-1.286389, 36.817223); // default Nairobi coordinates
  List<String> _driverIds = [];
  List<LatLng> _polylines = []; // List to hold polylines
  late MapController _mapController = MapController(); // Define MapController

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
        _selectedDriverId = _driverIds[1]; // Set the default selected ID
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

    print('Driver location fetched: $latitude, $longitude');

    setState(() {
      _driverLocation = LatLng(latitude, longitude);
    });
  }

  Future<void> _navigateToParentLocation() async {
    // Get the current position of the parent
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    LatLng parentLocation = LatLng(position.latitude, position.longitude);
    print('Parent location: $parentLocation');
    print('Driver location: $_driverLocation');

    setState(() {
      _polylines = [
        _driverLocation,
        parentLocation,
      ];
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
                initialCenter: _driverLocation,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  tileProvider: CancellableNetworkTileProvider(),
                ),
                PolylineLayer(polylines: [
                  Polyline(
                    points: _polylines,
                    strokeWidth: 4,
                    color: Colors.blue,
                  ),
                ]),
                MarkerLayer(markers: [
                  Marker(
                      point: _driverLocation,
                      width: 80,
                      height: 80,
                      child: Icon(
                        Icons.person_pin_circle,
                        color: Colors.red, // Set the color of the marker
                        size: 40.0,
                      ))
                ])
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
          ElevatedButton(
            onPressed: _navigateToParentLocation,
            child: Text('View Route'),
          ),
        ],
      ),
    );
  }
}
