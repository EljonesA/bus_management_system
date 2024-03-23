import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_management_system/choose_role_page.dart';

class ManageStudentsPage extends StatefulWidget {
  @override
  _ManageStudentsPageState createState() => _ManageStudentsPageState();
}

class _ManageStudentsPageState extends State<ManageStudentsPage> {
  late Future<QuerySnapshot> students;
  int _hoveredRowIndex = -1;

  @override
  void initState() {
    super.initState();
    // Fetch student data from Firestore when the widget is initialized
    students = FirebaseFirestore.instance.collection('Students').get();
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
          future: students,
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              // Build the table if student data is available
              return _buildDataTable(snapshot.data!);
            } else {
              return Center(child: Text('No students found.'));
            }
          },
        ),
      ),
    );
  }

  Widget _buildDataTable(QuerySnapshot snapshot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20), // Add spacing between the text and the table
        Text(
          'Manage Students',
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
            color:
                Colors.white, // Set the background color of the table to white
            child: DataTable(
              headingRowColor:
                  MaterialStateColor.resolveWith((states) => Colors.green),
              dataRowColor:
                  MaterialStateColor.resolveWith((states) => Colors.white),
              dataRowHeight: 60,
              columns: [
                DataColumn(
                  label: Text(
                    'Student Name',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Grade',
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
                    'Guardian Name',
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
                    DataCell(Text(
                      data['studentName'] ?? 'N/A',
                      style: TextStyle(color: Colors.black),
                    )),
                    DataCell(Text(
                      data['studentGrade'] ?? 'N/A',
                      style: TextStyle(color: Colors.black),
                    )),
                    DataCell(Text(
                      data['assignedBus'] ?? 'N/A',
                      style: TextStyle(color: Colors.black),
                    )),
                    DataCell(Text(
                      data['guardianName'] ?? 'N/A',
                      style: TextStyle(color: Colors.black),
                    )),
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
                          SizedBox(width: 8), // Add some space between buttons
                          ElevatedButton(
                            onPressed: () => _deleteStudent(document),
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

  Future<void> _assignBus(DocumentSnapshot studentDocument) async {
    final buses = await FirebaseFirestore.instance.collection('Buses').get();
    List<String> busNames =
        buses.docs.map((doc) => doc['Model'] as String).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black, // Set background color to black
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: BorderSide(
              color: Colors.green, width: 2), // Set border color and width
        ),
        title: Text(
          'Assign Bus',
          style:
              TextStyle(color: Colors.white), // Set title text color to white
        ),
        content: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: DropdownButton<String>(
            dropdownColor:
                Colors.black, // Set dropdown background color to black
            items: busNames.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                      color: Colors
                          .white), // Set dropdown item text color to white
                ),
              );
            }).toList(),
            onChanged: (String? selectedBus) {
              if (selectedBus != null) {
                _updateStudentBus(studentDocument, selectedBus);
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _updateStudentBus(
      DocumentSnapshot studentDocument, String selectedBus) async {
    try {
      await studentDocument.reference.update({'assignedBus': selectedBus});
      _showSuccessDialog();
      // Refresh the student list after assigning bus
      setState(() {
        students = FirebaseFirestore.instance.collection('Students').get();
      });
    } catch (e) {
      print("Document ID: ${studentDocument.id}");
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

  void _deleteStudent(DocumentSnapshot<Object?>? selectedStudent) async {
    if (selectedStudent != null) {
      try {
        await selectedStudent.reference.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student deleted successfully')),
        );
        // Refresh the student list after deletion
        setState(() {
          students = FirebaseFirestore.instance.collection('Students').get();
        });
      } catch (e) {
        print('Error deleting student: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete student')),
        );
      }
    }
  }
}
