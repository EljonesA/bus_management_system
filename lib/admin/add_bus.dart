import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddBusesPage extends StatefulWidget {
  @override
  _AddBusesPageState createState() => _AddBusesPageState();
}

class _AddBusesPageState extends State<AddBusesPage> {
  String _selectedOperationStatus = 'In Service';
  String _selectedEmergencyKit = 'Yes';
  String _selectedCCTVCamera = 'Yes';

  final _formKey = GlobalKey<FormState>();

  // Declare controllers for each form field
  final TextEditingController busNumberController = TextEditingController();
  final TextEditingController licensePlateNumberController =
      TextEditingController();
  final TextEditingController busTypeController = TextEditingController();
  final TextEditingController fuelLevelController = TextEditingController();
  final TextEditingController anyIssuesController = TextEditingController();
  final TextEditingController totalCapacityController = TextEditingController();
  final TextEditingController manufacturerController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController vinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Buses'),
        backgroundColor: Colors.black, // Uber black color
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextFormField(
                    controller: busNumberController, // Add controller
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
                    controller: licensePlateNumberController, // Add controller
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
                    controller: busTypeController, // Add controller
                    decoration: InputDecoration(labelText: 'Bus Type'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter bus type';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedOperationStatus,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedOperationStatus = newValue!;
                      });
                    },
                    items: ['In Service', 'Out of Service']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: InputDecoration(labelText: 'Operation Status'),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: fuelLevelController, // Add controller
                    decoration: InputDecoration(labelText: 'Fuel Level'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter fuel level';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: anyIssuesController, // Add controller
                    decoration: InputDecoration(labelText: 'Any Issues'),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: totalCapacityController, // Add controller
                    decoration: InputDecoration(labelText: 'Total Capacity'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter total capacity';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedEmergencyKit,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedEmergencyKit = newValue!;
                      });
                    },
                    items: ['Yes', 'No']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration:
                        InputDecoration(labelText: 'Emergency Kit Available'),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: manufacturerController, // Add controller
                    decoration: InputDecoration(labelText: 'Manufacturer'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter manufacturer';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: modelController, // Add controller
                    decoration: InputDecoration(labelText: 'Model'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter model';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: vinController, // Add controller
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
                  DropdownButtonFormField<String>(
                    value: _selectedCCTVCamera,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCCTVCamera = newValue!;
                      });
                    },
                    items: ['Yes', 'No']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration:
                        InputDecoration(labelText: 'CCTV Camera Availability'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Process form data
                        Map<String, dynamic> busData = {
                          'Bus Number': busNumberController.text,
                          'License Plate Number':
                              licensePlateNumberController.text,
                          'Bus Type': busTypeController.text,
                          'Operation Status': _selectedOperationStatus,
                          'Fuel Level': fuelLevelController.text,
                          'Any Issues': anyIssuesController.text,
                          'Total Capacity': totalCapacityController.text,
                          'Emergency KitAvailable': _selectedEmergencyKit,
                          'Manufacturer': manufacturerController.text,
                          'Model': modelController.text,
                          'Vehicle Identification Number (VIN)':
                              vinController.text,
                          'CCTV Camera Availaibility': _selectedCCTVCamera,
                        };

                        // Access the 'Buses' collection in Firestore and add the bus data
                        FirebaseFirestore.instance
                            .collection('Buses')
                            .add(busData)
                            .then((value) {
                          // Clear form fields after successful submission
                          busNumberController.clear();
                          licensePlateNumberController.clear();
                          busTypeController.clear();
                          fuelLevelController.clear();
                          anyIssuesController.clear();
                          totalCapacityController.clear();
                          manufacturerController.clear();
                          modelController.clear();
                          vinController.clear();
                          // Show success message to user
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Bus information added successfully',
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.green, // Success color
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
                      style: TextStyle(color: Colors.black), // Uber black color
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.white, // Uber white color
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    busNumberController.dispose();
    licensePlateNumberController.dispose();
    busTypeController.dispose();
    fuelLevelController.dispose();
    anyIssuesController.dispose();
    totalCapacityController.dispose();
    manufacturerController.dispose();
    modelController.dispose();
    vinController.dispose();
    super.dispose();
  }
}
