import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_management_system/choose_role_page.dart';

class AddBusesPage extends StatefulWidget {
  @override
  _AddBusesPageState createState() => _AddBusesPageState();
}

class _AddBusesPageState extends State<AddBusesPage> {
  String _selectedFuelType = 'Diesel';
  String _selectedInsuranceProvider = 'CIC Insurance';
  String _selectedTransmission = 'Auto';

  final _formKey = GlobalKey<FormState>();

  // Declare controllers for each form field
  final TextEditingController busNumberController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController insurancePolicyNumberController =
      TextEditingController();
  final TextEditingController lastMaintenanceDateController =
      TextEditingController(text: 'n/a');
  final TextEditingController licensePlateNumberController =
      TextEditingController();
  final TextEditingController makeController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController nextMaintenanceDateController =
      TextEditingController(text: 'n/a');
  final TextEditingController safetyFeaturesController =
      TextEditingController();
  final TextEditingController seatingCapacityController =
      TextEditingController();
  final TextEditingController vinController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController assignedDriverController =
      TextEditingController(text: 'none');
  final TextEditingController busNumberDuplicateController =
      TextEditingController();

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
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: busNumberController,
                        decoration: InputDecoration(labelText: 'Bus Number'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter bus number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: colorController,
                        decoration: InputDecoration(labelText: 'Color'),
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedFuelType,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedFuelType = newValue!;
                          });
                        },
                        items: ['Diesel', 'Petrol']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(labelText: 'Fuel Type'),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: insurancePolicyNumberController,
                        decoration: InputDecoration(
                            labelText: 'Insurance Policy Number'),
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedInsuranceProvider,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedInsuranceProvider = newValue!;
                          });
                        },
                        items: ['CIC Insurance', 'Britam']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration:
                            InputDecoration(labelText: 'Insurance Provider'),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: lastMaintenanceDateController,
                        decoration: InputDecoration(
                            labelText: 'Last Maintenance Date',
                            hintText: 'n/a'),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: licensePlateNumberController,
                        decoration:
                            InputDecoration(labelText: 'License Plate Number'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter license plate number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: makeController,
                        decoration: InputDecoration(labelText: 'Make'),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: modelController,
                        decoration: InputDecoration(labelText: 'Model'),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: nextMaintenanceDateController,
                        decoration: InputDecoration(
                            labelText: 'Next Maintenance Date',
                            hintText: 'n/a'),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: safetyFeaturesController,
                        decoration:
                            InputDecoration(labelText: 'Safety Features'),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: seatingCapacityController,
                        decoration:
                            InputDecoration(labelText: 'Seating Capacity'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter seating capacity';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedTransmission,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedTransmission = newValue!;
                          });
                        },
                        items: ['Auto', 'Manual']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(labelText: 'Transmission'),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: vinController,
                        decoration: InputDecoration(
                            labelText: 'Vehicle Identification Number (VIN)'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter VIN';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: yearController,
                        decoration: InputDecoration(labelText: 'Year'),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: assignedDriverController,
                        decoration: InputDecoration(
                            labelText: 'Assigned Driver', hintText: 'none'),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: busNumberDuplicateController,
                        decoration:
                            InputDecoration(labelText: 'Bus Number Duplicate'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter bus number duplicate';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Process form data
                            Map<String, dynamic> busData = {
                              'Bus Number': busNumberController.text,
                              'Color': colorController.text,
                              'Fuel Type': _selectedFuelType,
                              'Insurance Policy Number':
                                  insurancePolicyNumberController.text,
                              'Insurance Provider': _selectedInsuranceProvider,
                              'Last Maintenance Date':
                                  lastMaintenanceDateController.text,
                              'License Plate Number':
                                  licensePlateNumberController.text,
                              'Make': makeController.text,
                              'Model': modelController.text,
                              'Next Maintenance Date':
                                  nextMaintenanceDateController.text,
                              'Safety Features': safetyFeaturesController.text,
                              'Seating Capacity':
                                  int.parse(seatingCapacityController.text),
                              'Transmission': _selectedTransmission,
                              'Vehicle Identification Number (VIN)':
                                  vinController.text,
                              'Year': yearController.text,
                              'assignedDriver': assignedDriverController.text,
                              'busNumber': busNumberDuplicateController.text,
                            };

                            // Access the 'Buses' collection in Firestore and add the bus data
                            FirebaseFirestore.instance
                                .collection('Buses')
                                .add(busData)
                                .then((value) {
                              // Clear form fields after successful submission
                              busNumberController.clear();
                              colorController.clear();
                              insurancePolicyNumberController.clear();
                              lastMaintenanceDateController.clear();
                              licensePlateNumberController.clear();
                              makeController.clear();
                              modelController.clear();
                              nextMaintenanceDateController.clear();
                              safetyFeaturesController.clear();
                              seatingCapacityController.clear();
                              vinController.clear();
                              yearController.clear();
                              assignedDriverController.clear();
                              busNumberDuplicateController.clear();

                              // Show success message to user
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Bus information added successfully',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor:
                                      Colors.green, // Success color
                                ),
                              );
                            }).catchError((error) {
                              // Show error message to user if submission fails
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to add bus information: $error',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.red, // Error color
                                ),
                              );
                            });
                          }
                        },
                        child: Text(
                          'Submit',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.green, // Background color
                          onPrimary: Colors.white, // Text color
                          side: BorderSide(
                              color: Colors.white, width: 2), // Border
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    busNumberController.dispose();
    colorController.dispose();
    insurancePolicyNumberController.dispose();
    lastMaintenanceDateController.dispose();
    licensePlateNumberController.dispose();
    makeController.dispose();
    modelController.dispose();
    nextMaintenanceDateController.dispose();
    safetyFeaturesController.dispose();
    seatingCapacityController.dispose();
    vinController.dispose();
    yearController.dispose();
    assignedDriverController.dispose();
    busNumberDuplicateController.dispose();
    super.dispose();
  }
}
