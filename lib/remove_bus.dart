import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:responsive_table/responsive_table.dart';

class RemoveBusPage extends StatefulWidget {
  @override
  _RemoveBusPageState createState() => _RemoveBusPageState();
}

class _RemoveBusPageState extends State<RemoveBusPage> {
  List<DatatableHeader> _headers = [];
  List<Map<String, dynamic>> _busData = [];
  List<Map<String, dynamic>> _selectedBuses = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    await _fetchBusData();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchBusData() async {
    try {
      // Fetch bus data from Firestore
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('Buses').get();

      // Process fetched data
      List<Map<String, dynamic>> buses = [];
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        buses.add(data);
      }

      // Set bus data and headers
      _busData = buses;
      if (_headers.isEmpty) {
        _headers = _busData.isNotEmpty ? _getHeaders(_busData.first) : [];
      }
    } catch (error) {
      print('Error fetching bus data: $error');
    }
  }

  List<DatatableHeader> _getHeaders(Map<String, dynamic> data) {
    return data.keys.map((key) {
      return DatatableHeader(
        text: key,
        value: key,
        show: true,
        sortable: true,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Remove Bus'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildDataTable(),
    );
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              width: MediaQuery.of(context).size.width,
              child: ResponsiveDatatable(
                headers: _headers,
                source: _busData,
                selecteds: _selectedBuses,
                isLoading: _isLoading,
                footers: [
                  ElevatedButton(
                    onPressed: () {
                      _removeSelectedBuses();
                    },
                    child: Text('Remove Selected Buses'),
                  ),
                ],
                onSelect: (value, item) {
                  if (value != null) {
                    setState(() {
                      _selectedBuses.add(item);
                    });
                  } else {
                    setState(() {
                      _selectedBuses.remove(item);
                    });
                  }
                },
                onSelectAll: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedBuses = List.from(_busData);
                    });
                  } else {
                    setState(() {
                      _selectedBuses.clear();
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _removeSelectedBuses() {
    // Implement bus removal logic here
    // for (var bus in _selectedBuses) {
    //   FirebaseFirestore.instance.collection('Buses').doc(bus['id']).delete();
    // }
    setState(() {
      _selectedBuses.clear();
    });
  }
}
