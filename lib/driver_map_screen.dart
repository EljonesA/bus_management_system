// map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  late StreamSubscription<Position>? locationStreamSubscription;

  static const LatLng _initialPosition = LatLng(-18.9216855, 47.5725194);
  late List<User> _userList = [];

  @override
  void initState() {
    super.initState();
    locationStreamSubscription =
        Geolocator.getPositionStream().listen((Position position) async {
      await FirestoreService.updateUserLocation('nA7DXYrq1hoKumg3q9fu',
          LatLng(position.latitude, position.longitude));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<User>>(
        stream: FirestoreService.userCollectionStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          _userList = snapshot.data!;
          final List<Marker> markers = _buildMarkers();
          return FlutterMap(
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
            ],
            options: MapOptions(
              center: _initialPosition,
              zoom: 14.0,
            ),
            //MarkerLayerOptions(markers: markers),
          );
        },
      ),
    );
  }

  List<Marker> _buildMarkers() {
    return _userList.map((user) {
      return Marker(
          width: 80.0,
          height: 80.0,
          point: user.location,
          child: Icon(
            Icons.person_pin_circle,
            color: Colors.orange, // Set the color of the marker
            size: 40.0,
          ));
    }).toList();
  }

  @override
  void dispose() {
    super.dispose();
    if (locationStreamSubscription != null) {
      locationStreamSubscription!.cancel();
    }
  }
}

class FirestoreService {
  static Stream<List<User>> userCollectionStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return User(
                name: data['name'] ?? '',
                location: LatLng(
                  data['location']['latitude'],
                  data['location']['longitude'],
                ),
              );
            }).toList());
  }

  static Future<void> updateUserLocation(String userId, LatLng location) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        }
      });
    } catch (e) {
      print('Error updating user location: $e');
      throw e;
    }
  }
}

class User {
  final String name;
  final LatLng location;

  User({required this.name, required this.location});
}
