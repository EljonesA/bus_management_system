import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    // Fetch driver IDs from Firestore
    // This part remains unchanged
  }

  Future<void> _fetchDriverLocation(String driverId) async {
    // Fetch driver location using driverId from Firestore
    // This part remains unchanged
  }

  Future<void> _navigateToParentLocation() async {
    // Get the current position of the parent
    // This part remains unchanged
  }

  Future<List<LatLng>> _fetchRouteCoordinates(
      LatLng origin, LatLng destination) async {
    // Make a request to OSRM API to fetch route coordinates
    String url =
        'http://router.project-osrm.org/route/v1/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> routes = data['routes'];
      if (routes.isNotEmpty) {
        List<dynamic> geometry = routes[0]['geometry']['coordinates'];
        List<LatLng> coordinates = [];
        geometry.forEach((coord) {
          double lat = coord[1]; // Latitude
          double lng = coord[0]; // Longitude
          coordinates.add(LatLng(lat, lng));
        });
        return coordinates;
      }
    }
    return [];
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
                  zoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _polylines,
                        strokeWidth: 4,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  MarkerLayer(markers: [
                    Marker(
                        point: _driverLocation,
                        child: Icon(
                          Icons.person_pin_circle,
                          color: Colors.orange, // Set the color of the marker
                          size: 40.0,
                        ))
                  ])
                ]),
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
            onPressed: () async {
              // Example: Fetch route coordinates between two points
              LatLng origin = LatLng(51.5, -0.1); // Example origin coordinates
              LatLng destination =
                  LatLng(51.6, -0.2); // Example destination coordinates
              List<LatLng> routeCoordinates =
                  await _fetchRouteCoordinates(origin, destination);
              setState(() {
                _polylines = routeCoordinates;
              });
            },
            child: Text('View Route'),
          ),
        ],
      ),
    );
  }
}
