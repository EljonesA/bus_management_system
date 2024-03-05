import 'package:bus_management_system/admin/add_bus.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageBusesPage extends StatefulWidget {
  @override
  _ManageBusesPageState createState() => _ManageBusesPageState();
}

class _ManageBusesPageState extends State<ManageBusesPage> {
  late Future<QuerySnapshot> buses;
  int _hoveredRowIndex = -1;

  @override
  void initState() {
    super.initState();
    // Fetch bus data from Firestore when the widget is initialized
    buses = FirebaseFirestore.instance.collection('Buses').get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Buses'),
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
          future: buses,
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              // Build the table if bus data is available
              return _buildDataTable(snapshot.data!);
            } else {
              return Center(child: Text('No buses found.'));
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _addBus(), // Function to be called when the button is pressed
        tooltip: 'Add Bus',
        child: Icon(Icons.add),
      ),
    );
  }

  void _addBus() {
    // navigate to page to add bus
    Navigator.push(
      context,
      MaterialPageRoute(builder: ((context) => AddBusesPage())),
    );
    // Refresh bus data after adding new bus
    setState(() {
      buses = FirebaseFirestore.instance.collection('Buses').get();
    });
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
              'Bus Model',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Capacity',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Assigned Driver',
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
              });
            },
            cells: [
              DataCell(Text(data['Model'] ?? 'N/A')),
              DataCell(Text(data['Capacity']?.toString() ?? 'N/A')),
              DataCell(Text(data['assignedDriver'] ?? 'N/A')),
              DataCell(
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _assignDriver(document),
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
                      child: Text('Assign Driver'),
                    ),
                    SizedBox(width: 8), // Add some space between buttons
                    ElevatedButton(
                      onPressed: () => _deleteBus(document),
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

  Future<void> _assignDriver(DocumentSnapshot busDocument) async {
    final drivers =
        await FirebaseFirestore.instance.collection('Drivers').get();
    List<String> driverNames =
        drivers.docs.map((doc) => doc['driverName'] as String).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Add a golden border
        ),
        title: Text(
          'Assign Driver',
          style: TextStyle(color: Colors.black),
        ),
        content: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: DropdownButton<String>(
            dropdownColor: Colors.white,
            items: driverNames.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(color: Colors.black),
                ),
              );
            }).toList(),
            onChanged: (String? selectedDriver) {
              if (selectedDriver != null) {
                _updateBusDriver(busDocument, selectedDriver);
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _updateBusDriver(
      DocumentSnapshot busDocument, String selectedDriver) async {
    try {
      // Check if the selected driver is already assigned to a bus
      final assignedBusSnapshot = await FirebaseFirestore.instance
          .collection('Buses')
          .where('assignedDriver', isEqualTo: selectedDriver)
          .get();

      if (assignedBusSnapshot.docs.isNotEmpty) {
        // If driver already has an assigned bus, prompt user for reassignment
        final bool reassign = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color.fromARGB(
                255, 4, 35, 61), // Set background color to white
            title: Text(
              'Driver Already Assigned',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
                'The selected driver is already assigned to a bus. Do you want to reassign them?'),
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

        if (!reassign) {
          return; // If user chooses not to reassign, exit the method
        }
      }

      // Update the new bus with the selected driver
      await busDocument.reference.update({'assignedDriver': selectedDriver});

      if (assignedBusSnapshot.docs.isNotEmpty) {
        // If the driver was previously assigned to a bus, update the previous bus
        final previousBusDocument = assignedBusSnapshot.docs.first;
        await previousBusDocument.reference.update({'assignedDriver': 'None'});
      }
      _showSuccessDialog();
      // Refresh bus data after assigning driver
      setState(() {
        buses = FirebaseFirestore.instance.collection('Buses').get();
      });
    } catch (e) {
      print("Document ID: ${busDocument.id}");
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
          'Driver assigned successfully',
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
          'Failed to assign driver',
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

  void _deleteBus(DocumentSnapshot<Object?>? selectedBus) async {
    if (selectedBus != null) {
      try {
        await selectedBus.reference.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bus deleted successfully')),
        );
        // Refresh the bus list after deletion
        setState(() {
          buses = FirebaseFirestore.instance.collection('Buses').get();
        });
      } catch (e) {
        print('Error deleting bus: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete bus')),
        );
      }
    }
  }
}
