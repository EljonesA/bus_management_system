import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PassengerMode extends StatefulWidget {
  @override
  _PassengerModeState createState() => _PassengerModeState();
}

class _PassengerModeState extends State<PassengerMode> {
  late Position _currentPosition;
  final CollectionReference _passengerLocations =
      FirebaseFirestore.instance.collection('passengerLocations');

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });
    _uploadLocationToFirestore(position.latitude, position.longitude);
  }

  void _uploadLocationToFirestore(double latitude, double longitude) {
    _passengerLocations.add({
      'latitude': latitude,
      'longitude': longitude,
    }).then((value) {
      print("Location uploaded successfully!");
    }).catchError((error) {
      print("Failed to upload location: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Passenger Mode'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Latitude: ${_currentPosition.latitude ?? 'Loading...'}'),
            Text('Longitude: ${_currentPosition.longitude ?? 'Loading...'}'),
          ],
        ),
      ),
    );
  }
}
