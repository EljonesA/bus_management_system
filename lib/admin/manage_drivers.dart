import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_management_system/choose_role_page.dart';

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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _licenceNumberController =
      TextEditingController();
  final TextEditingController _nationalIDController = TextEditingController();
  final TextEditingController _emergencyContactController =
      TextEditingController();
  final TextEditingController _empIDController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

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
        backgroundColor: Color.fromARGB(
            255, 86, 150, 88), // Set the background color of the app bar
        elevation: 0, // Remove the elevation (shadow) of the app bar
        foregroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SchollyBus Mate',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.exit_to_app,
            ),
            onPressed: () {
              // navigate back to login screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ChooseRolePage()),
              );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20), // Add spacing between the text and the table
        Text(
          'Manage Drivers',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        SizedBox(
            height:
                10), // Add additional spacing between the text and the table
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            color: Colors.white, // Set background color of DataTable to white
            child: DataTable(
              headingRowColor:
                  MaterialStateColor.resolveWith((states) => Colors.green),
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
                      selectedDriver =
                          _hoveredRowIndex == index ? document : null;
                    });
                  },
                  cells: [
                    DataCell(
                      Text(
                        data['driverName'] ?? 'N/A',
                        style: TextStyle(
                          color: Colors.black, // Set font color to black
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        data['phoneNumber'] ?? 'N/A',
                        style: TextStyle(
                          color: Colors.black, // Set font color to black
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        data['assignedBus'] ?? 'N/A',
                        style: TextStyle(
                          color: Colors.black, // Set font color to black
                        ),
                      ),
                    ),
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
                                borderRadius: BorderRadius.circular(
                                    20), // Rounded corners
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
                                  borderRadius: BorderRadius.circular(
                                      20), // Rounded corners
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
          ),
        ),
      ],
    );
  }

  Future<void> _assignBus(DocumentSnapshot driverDocument) async {
    final buses = await FirebaseFirestore.instance.collection('Buses').get();
    List<String> busNames =
        buses.docs.map((doc) => doc['Model'] as String).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black, // Set background color to white
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: BorderSide(
              color: Colors.green, width: 2), // Set border color and width
        ),
        title: Text(
          'Assign Bus',
          style:
              TextStyle(color: Colors.white), // Set title text color to black
        ),
        content: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: DropdownButton<String>(
            dropdownColor:
                Colors.white, // Set dropdown background color to white
            items: busNames.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                      color: Colors
                          .black), // Set dropdown item text color to black
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
                      backgroundColor:
                          Colors.black, // Set background color to black
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: BorderSide(
                            color: Colors.green,
                            width: 2), // Set border color and width
                      ),
                      title: Text(
                        'Bus Already Assigned',
                        style: TextStyle(
                            color:
                                Colors.white), // Set title text color to white
                      ),
                      content: Text(
                        'The selected bus is already assigned to a driver. Do you want to proceed?',
                        style: TextStyle(
                            color: Colors
                                .white), // Set content text color to white
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false), // No
                          child: Text('No',
                              style: TextStyle(
                                  color: Colors
                                      .white)), // Set button text color to white
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true), // Yes
                          child: Text('Yes',
                              style: TextStyle(
                                  color: Colors
                                      .white)), // Set button text color to white
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
        content: SingleChildScrollView(
          child: Column(
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
              TextField(
                controller: _emailController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              TextField(
                controller: _addressController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Address',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              TextField(
                controller: _genderController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Gender',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              TextField(
                controller: _licenceNumberController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Licence Number',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              TextField(
                controller: _nationalIDController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'National ID',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              TextField(
                controller: _emergencyContactController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Emergency Contact',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              TextField(
                controller: _empIDController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Employee ID',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              TextField(
                controller: _latitudeController,
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Latitude',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              TextField(
                controller: _longitudeController,
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Longitude',
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
                  _phoneNumberController.text.isNotEmpty &&
                  _emailController.text.isNotEmpty &&
                  _addressController.text.isNotEmpty &&
                  _genderController.text.isNotEmpty &&
                  _licenceNumberController.text.isNotEmpty &&
                  _nationalIDController.text.isNotEmpty &&
                  _emergencyContactController.text.isNotEmpty &&
                  _empIDController.text.isNotEmpty &&
                  _latitudeController.text.isNotEmpty &&
                  _longitudeController.text.isNotEmpty) {
                try {
                  FirebaseFirestore.instance.collection('Drivers').add({
                    'assignedBus': 'None', // Set default value
                    'driverName': _driverNameController.text,
                    'phoneNumber': _phoneNumberController.text,
                    'driverEmail': _emailController.text,
                    'driverAddress': _addressController.text,
                    'driverGender': _genderController.text,
                    'driverLicenceNumber': _licenceNumberController.text,
                    'driverNationalID': _nationalIDController.text,
                    'emergencyContact': _emergencyContactController.text,
                    'empID': _empIDController.text,
                    'latitude': double.parse(_latitudeController.text),
                    'longitude': double.parse(_longitudeController.text),
                    'status': 'off-route',
                    'driverLicenceExpiry': 'n/a',
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
