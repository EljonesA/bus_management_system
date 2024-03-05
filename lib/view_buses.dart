import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewBusesPage extends StatefulWidget {
  @override
  _ViewBusesPageState createState() => _ViewBusesPageState();
}

class _ViewBusesPageState extends State<ViewBusesPage> {
  String _selectedBusPlateNumber = ''; // Store the selected bus plate number
  Map<String, dynamic>?
      _selectedBusDetails; // Store the details of the selected bus

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Buses'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField(
              value: _selectedBusPlateNumber,
              onChanged: (newValue) {
                setState(() {
                  _selectedBusPlateNumber = newValue.toString();
                  _fetchBusDetails(); // Fetch details when a new bus is selected
                });
              },
              items: _buildDropdownItems(), // Build dropdown items
              decoration: InputDecoration(labelText: 'Select Bus Plate Number'),
            ),
            SizedBox(height: 20),
            _selectedBusDetails != null
                ? _buildBusDetailsView() // Display bus details if available
                : Container(),
          ],
        ),
      ),
    );
  }

  // Fetch bus details based on the selected bus plate number
  void _fetchBusDetails() {
    FirebaseFirestore.instance
        .collection('Buses')
        .where('License Plate Number', isEqualTo: _selectedBusPlateNumber)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _selectedBusDetails = querySnapshot.docs.first.data();
        });
      }
    }).catchError((error) {
      print('Error fetching bus details: $error');
    });
  }

  // Build dropdown items from Firestore data
  List<DropdownMenuItem<String>> _buildDropdownItems() {
    List<DropdownMenuItem<String>> items = [];

    // Fetch bus plate numbers from Firestore
    FirebaseFirestore.instance.collection('Buses').get().then((querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        String plateNumber = doc['License Plate Number'];
        items.add(DropdownMenuItem(
          value: plateNumber,
          child: Text(plateNumber),
        ));
      });
    }).catchError((error) {
      print('Error fetching bus plate numbers: $error');
    });

    return items;
  }

  // Build the bus details view
  Widget _buildBusDetailsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bus Details:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        SizedBox(height: 10),
        // You can structure the display of bus details based on your requirements
        // For example:
        Text('Bus Number: ${_selectedBusDetails!['Bus Number']}'),
        Text('Bus Type: ${_selectedBusDetails!['Bus Type']}'),
        Text('Operation Status: ${_selectedBusDetails!['Operation Status']}'),
        // Add more details as needed
      ],
    );
  }
}
