import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WaitingMode extends StatefulWidget {
  @override
  _WaitingModeState createState() => _WaitingModeState();
}

class _WaitingModeState extends State<WaitingMode> {
  late CollectionReference _passengerLocations;
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _passengerLocations =
        FirebaseFirestore.instance.collection('passengerLocations');
    _getPassengerLocations();
  }

  void _getPassengerLocations() {
    _passengerLocations.snapshots().listen((snapshot) {
      for (var doc in snapshot.docs) {
        print("Document ID: ${doc.id}");
        print("Document data: ${doc.data()}");

        double? latitude = doc['latitude'];
        double? longitude = doc['longitude'];

        // Check if latitude and longitude are not null
        if (latitude != null && longitude != null) {
          setState(() {
            _markers.add(
              Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(latitude, longitude),
              ),
            );
          });
        } else {
          print("Latitude or longitude is null for document: ${doc.id}");
        }
      }
    }, onError: (error) {
      print("Error retrieving passenger locations: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Waiting Mode'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(0, 0),
          zoom: 15,
        ),
        markers: Set<Marker>.of(_markers),
      ),
    );
  }
}
