import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];

  @override
  void initState() {
    super.initState();
    _fetchDriverLocations();
  }

  Future<void> _fetchDriverLocations() async {
    // Mock data for demonstration
    // Replace this with your actual data retrieval logic
    List<Map<String, dynamic>> driversData = [
      {"latitude": 51.5, "longitude": -0.09},
      {"latitude": 51.6, "longitude": -0.10}
    ];

    setState(() {
      _markers = driversData.map((data) {
        double latitude = data['latitude'];
        double longitude = data['longitude'];

        return Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(latitude, longitude),
            child: Icon(
              Icons.place,
              color: Colors.black, // Set the color of the marker
              size: 40.0,
            ));
      }).toList();
    });

    // Fetch route between admin and drivers
    LatLng adminLocation = LatLng(51.5, -0.09); // Admin location (example)
    for (var data in driversData) {
      LatLng driverLocation = LatLng(data['latitude'], data['longitude']);
      await _fetchRoute(adminLocation, driverLocation);
    }
  }

  Future<void> _fetchRoute(LatLng startPoint, LatLng endPoint) async {
    final String apiKey = '7c30bb61-cba7-4f00-b1f3-4ae494ecb0a4';
    final String baseUrl = 'https://graphhopper.com/api/1/route';
    final String profile = 'car';
    final String coordinates =
        '${startPoint.latitude},${startPoint.longitude}&point=${endPoint.latitude},${endPoint.longitude}';
    final String url =
        '$baseUrl?point=$coordinates&vehicle=$profile&key=$apiKey&points_encoded=false';
    print(url);
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
        final decoded = json.decode(response.body);
        //print("Decoded: $decoded");
        if (decoded['paths'] != null && decoded['paths'].isNotEmpty) {
          List<dynamic> paths = decoded['paths'];
          // Access the 'points' field
          List<dynamic> points = paths[0]['points']['coordinates'];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(51.5, -0.09),
                  zoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  MarkerLayer(
                    markers: _markers,
                  ),
                  PolylineLayer(
                    polylines: _polylines,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
