import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; // Import the geolocator package
import 'package:bus_management_system/login_screens/parent_login.dart';
import 'package:bus_management_system/choose_role_page.dart';
import 'dart:math'; // for ID generation

class StudentRegistrationPage extends StatefulWidget {
  @override
  _StudentRegistrationPageState createState() =>
      _StudentRegistrationPageState();
}

class _StudentRegistrationPageState extends State<StudentRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _guardianNameController;
  late TextEditingController _guardianMobileController;
  late TextEditingController _guardianEmailController;
  late TextEditingController _guardianAddressController;
  late TextEditingController _studentNameController;
  late TextEditingController _studentAgeController;
  late TextEditingController _studentGradeController;
  late TextEditingController _studentGenderController;
  late TextEditingController _emergencyContactsController;
  late TextEditingController _medicalConcernsController;
  late TextEditingController _relationshipController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  bool _showStudentSection = false;

  @override
  void initState() {
    super.initState();
    _guardianNameController = TextEditingController();
    _guardianMobileController = TextEditingController();
    _guardianEmailController = TextEditingController();
    _guardianAddressController = TextEditingController();
    _studentNameController = TextEditingController();
    _studentAgeController = TextEditingController();
    _studentGradeController = TextEditingController();
    _studentGenderController = TextEditingController();
    _emergencyContactsController = TextEditingController();
    _medicalConcernsController = TextEditingController();
    _relationshipController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();

    // Get the current location when the page loads
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _latitudeController.text = position.latitude.toString();
      _longitudeController.text = position.longitude.toString();
    });
  }

  @override
  void dispose() {
    _guardianNameController.dispose();
    _guardianMobileController.dispose();
    _guardianEmailController.dispose();
    _guardianAddressController.dispose();
    _studentNameController.dispose();
    _studentAgeController.dispose();
    _studentGradeController.dispose();
    _studentGenderController.dispose();
    _emergencyContactsController.dispose();
    _medicalConcernsController.dispose();
    _relationshipController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  // fucntion to generate random srudent id
  String _generateShortId() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    const idLength = 4; // Adjust the length as needed
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      idLength,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // coordinates to of type double / number
      double latitude = double.tryParse(_latitudeController.text) ?? 0.0;
      double longitude = double.tryParse(_longitudeController.text) ?? 0.0;

      // Generate a unique short student ID
      String studentId = _generateShortId();

      final studentData = {
        'guardianName': _guardianNameController.text,
        'guardianMobile': _guardianMobileController.text,
        'guardianEmail': _guardianEmailController.text,
        'guardianAddress': _guardianAddressController.text,
        'studentName': _studentNameController.text,
        'studentAge': _studentAgeController.text,
        'studentGrade': _studentGradeController.text,
        'studentGender': _studentGenderController.text,
        'emergencyContacts': _emergencyContactsController.text,
        'medicalConcerns': _medicalConcernsController.text,
        'relationship': _relationshipController.text,
        'latitude': latitude,
        'longitude': longitude,
        'assignedBus': 'none',
        'studentId': studentId,
      };

      try {
        await FirebaseFirestore.instance
            .collection('Students')
            .add(studentData);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Student registration successful!'),
        ));
        // Redirect to the login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ParentLoginPage()),
        );
      } catch (e) {
        print('Error registering student: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to register student. Please try again later.'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Guardian Information',
                      style: TextStyle(
                          fontSize: 20.0, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20.0), // Added space between sections
                    TextFormField(
                      controller: _guardianNameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter guardian name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.0),
                    TextFormField(
                      controller: _guardianMobileController,
                      decoration: InputDecoration(
                        labelText: 'Mobile',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter guardian mobile';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.0),
                    TextFormField(
                      controller: _guardianEmailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter guardian email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.0),
                    TextFormField(
                      controller: _guardianAddressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter guardian address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.0),
                    if (_showStudentSection) ...[
                      Text(
                        'Student Information',
                        style: TextStyle(
                            fontSize: 20.0, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10.0),
                      // Add TextFormField widgets for student information here
                      TextFormField(
                        controller: _studentNameController,
                        decoration: InputDecoration(
                          labelText: 'Student Name',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter student name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10.0),
                      TextFormField(
                        controller: _studentAgeController,
                        decoration: InputDecoration(
                          labelText: 'Student Age',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter student age';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10.0),
                      TextFormField(
                        controller: _studentGradeController,
                        decoration: InputDecoration(
                          labelText: 'Student Grade',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter student grade';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10.0),
                      TextFormField(
                        controller: _studentGenderController,
                        decoration: InputDecoration(
                          labelText: 'Student Gender',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter student gender';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10.0),
                      TextFormField(
                        controller: _emergencyContactsController,
                        decoration: InputDecoration(
                          labelText: 'Emergency Contacts',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter emergency contacts';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10.0),
                      TextFormField(
                        controller: _medicalConcernsController,
                        decoration: InputDecoration(
                          labelText: 'Medical Concerns',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter medical concerns';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10.0),
                      TextFormField(
                        controller: _relationshipController,
                        decoration: InputDecoration(
                          labelText: 'Relationship',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter relationship';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10.0),
                      TextFormField(
                        controller: _latitudeController,
                        decoration: InputDecoration(
                          labelText: 'Latitude',
                        ),
                        keyboardType: TextInputType.number,
                        enabled: false, // Disable editing
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter latitude';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10.0),
                      TextFormField(
                        controller: _longitudeController,
                        decoration: InputDecoration(
                          labelText: 'Longitude',
                        ),
                        keyboardType: TextInputType.number,
                        enabled: false, // Disable editing
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter longitude';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 20.0),
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.white),
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.black),
                          overlayColor: MaterialStateProperty.all<Color>(
                              Colors.blue.shade700),
                          shape: MaterialStateProperty.all<OutlinedBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side: BorderSide(color: Colors.blue),
                            ),
                          ),
                        ),
                        child: Text('Register'),
                      ),
                      SizedBox(height: 10.0), // Add space between buttons
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showStudentSection = false;
                          });
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.black),
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.white),
                          overlayColor: MaterialStateProperty.all<Color>(
                              Colors.blue.shade700),
                          shape: MaterialStateProperty.all<OutlinedBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side: BorderSide(color: Colors.blue),
                            ),
                          ),
                        ),
                        child: Text('Back'),
                      ),
                    ],
                    if (!_showStudentSection)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showStudentSection = true;
                          });
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.black),
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.white),
                          overlayColor: MaterialStateProperty.all<Color>(
                              Colors.blue.shade700),
                          shape: MaterialStateProperty.all<OutlinedBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side: BorderSide(color: Colors.blue),
                            ),
                          ),
                        ),
                        child: Text('Next'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
