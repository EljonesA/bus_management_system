import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriversMainPage extends StatefulWidget {
  @override
  _DriversMainPageState createState() => _DriversMainPageState();
}

class _DriversMainPageState extends State<DriversMainPage> {
  late Future<QuerySnapshot> drivers;
  int _hoveredRowIndex = -1;
  DocumentSnapshot<Object?>? selectedDriver; // Updated type

  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch driver data from Firestore when the widget is initialized
    drivers = FirebaseFirestore.instance.collection('Drivers').get();
  }

  @override
  void dispose() {
    _driverNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Drivers'),
        actions: [
          // Signout Button
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                // Navigate to the login page after signout
                Navigator.of(context).pushReplacementNamed('/login');
              } catch (e) {
                print('Error signing out: $e');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: FutureBuilder(
          future: drivers,
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              // Build the table if driver data is available
              return _buildDataTable(snapshot.data!);
            } else {
              return Center(child: Text('No drivers found.'));
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDriverDialog,
        tooltip: 'Add Driver',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildDataTable(QuerySnapshot snapshot) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor:
            MaterialStateColor.resolveWith((states) => Color(0xFF007AFF)),
        columns: [
          DataColumn(
            label: Text(
              'Driver Name',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Phone Number',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Assigned Bus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Manage',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        rows: List<DataRow>.generate(snapshot.docs.length, (index) {
          final document = snapshot.docs[index];
          final data = document.data() as Map<String, dynamic>;
          return DataRow(
            color: MaterialStateColor.resolveWith((states) {
              return index == _hoveredRowIndex
                  ? Color.fromARGB(255, 102, 187, 243)
                  : Colors.transparent;
            }),
            onSelectChanged: (_) {
              setState(() {
                _hoveredRowIndex = _hoveredRowIndex == index ? -1 : index;
                selectedDriver = _hoveredRowIndex == index ? document : null;
              });
            },
            cells: [
              DataCell(Text(data['driverName'] ?? 'N/A')),
              DataCell(Text(data['phoneNumber'] ?? 'N/A')),
              DataCell(Text(data['assignedBus'] ?? 'N/A')),
              DataCell(
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _assignBus(document),
                      style: ElevatedButton.styleFrom(
                        primary: Color(0xFF132e57), // Background color
                        onPrimary: Colors.white, // Text color
                        textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        elevation: 8, // Elevation for a sleek look
                        padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8), // Padding for the button
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20), // Rounded corners
                        ),
                      ),
                      child: Text('Assign Bus'),
                    ),
                    SizedBox(width: 8),
                    if (selectedDriver != null &&
                        selectedDriver!.id ==
                            document
                                .id) // Only show delete button if driver is selected
                      ElevatedButton(
                        onPressed: () => _deleteDriver(selectedDriver!),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.red, // Background color
                          onPrimary: Colors.white, // Text color
                          textStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          elevation: 8, // Elevation for a sleek look
                          padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8), // Padding for the button
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(20), // Rounded corners
                          ),
                        ),
                        child: Text('Delete'),
                      ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _assignBus(DocumentSnapshot driverDocument) async {
    final buses = await FirebaseFirestore.instance.collection('Buses').get();
    List<String> busNames =
        buses.docs.map((doc) => doc['Model'] as String).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Assign Bus',
          style: TextStyle(color: Colors.black),
        ),
        content: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: DropdownButton<String>(
            dropdownColor: Colors.white,
            items: busNames.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(color: Colors.black),
                ),
              );
            }).toList(),
            onChanged: (String? selectedBus) async {
              if (selectedBus != null) {
                final assignedDriverSnapshot = await FirebaseFirestore.instance
                    .collection('Drivers')
                    .where('assignedBus', isEqualTo: selectedBus)
                    .get();
                if (assignedDriverSnapshot.docs.isNotEmpty) {
                  // Bus already has a driver assigned
                  final bool proceed = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color.fromARGB(255, 3, 63, 112),
                      title: Text(
                        'Bus Already Assigned',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: Text(
                        'The selected bus is already assigned to a driver. Do you want to proceed?',
                        style: TextStyle(color: Colors.white),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false), // No
                          child: Text('No'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true), // Yes
                          child: Text('Yes'),
                        ),
                      ],
                    ),
                  );

                  if (!proceed) {
                    return; // If user chooses not to proceed, exit the method
                  }
                }

                _updateDriverBus(driverDocument, selectedBus);
                Navigator.pop(context);
                if (assignedDriverSnapshot.docs.isNotEmpty) {
                  // If the driver was previously assigned to a bus, update the previous bus
                  final previousBusDocument = assignedDriverSnapshot.docs.first;
                  await previousBusDocument.reference
                      .update({'assignedBus': 'None'});
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _updateDriverBus(
      DocumentSnapshot driverDocument, String selectedBus) async {
    try {
      await driverDocument.reference.update({'assignedBus': selectedBus});
      _showSuccessDialog();
      setState(() {
        drivers = FirebaseFirestore.instance.collection('Drivers').get();
      });
    } catch (e) {
      print("Document ID: ${driverDocument.id}");
      print(e);
      _showFailureDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          'Success',
          style: TextStyle(color: const Color.fromARGB(255, 8, 230, 16)),
        ),
        content: Text(
          'Bus assigned successfully',
          style: TextStyle(color: const Color.fromARGB(255, 8, 230, 16)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          'Failed',
          style: TextStyle(color: Colors.red),
        ),
        content: Text(
          'Failed to assign bus',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAddDriverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        title: Text(
          'Add Driver',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _driverNameController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Driver Name',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _phoneNumberController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              // Add driver record to Firestore
              if (_driverNameController.text.isNotEmpty &&
                  _phoneNumberController.text.isNotEmpty) {
                try {
                  FirebaseFirestore.instance.collection('Drivers').add({
                    'driverName': _driverNameController.text,
                    'phoneNumber': _phoneNumberController.text,
                    'assignedBus': 'None', // Set default value
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Driver added successfully')),
                  );
                } catch (e) {
                  print('Error adding driver: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add driver')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please fill in all fields')),
                );
              }
            },
            child: Text(
              'Add',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteDriver(DocumentSnapshot<Object?>? selectedDriver) async {
    if (selectedDriver != null) {
      try {
        await selectedDriver.reference.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Driver deleted successfully')),
        );
        // Refresh the data and trigger a rebuild
        setState(() {
          drivers = FirebaseFirestore.instance.collection('Drivers').get();
        });
      } catch (e) {
        print('Error deleting driver: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete driver')),
        );
      }
    }
  }
}
