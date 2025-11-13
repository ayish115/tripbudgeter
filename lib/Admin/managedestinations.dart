import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tripbudgeter/Admin/drawer.dart';

class ManageDestinationsPage extends StatefulWidget {
  const ManageDestinationsPage({super.key});

  @override
  State<ManageDestinationsPage> createState() => _ManageDestinationsPageState();
}

class _ManageDestinationsPageState extends State<ManageDestinationsPage> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();

  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addOrEditDestination({DocumentSnapshot? doc}) {
    if (doc != null) {
      final data = doc.data() as Map<String, dynamic>;
      _cityController.text = data["cityName"] ?? "";
      _countryController.text = data["countryName"] ?? "";
      _latitudeController.text = (data["latitude"] ?? "").toString();
      _longitudeController.text = (data["longitude"] ?? "").toString();
    } else {
      _cityController.clear();
      _countryController.clear();
      _latitudeController.clear();
      _longitudeController.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(doc == null ? "Add Destination" : "Edit Destination"),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: "City Name"),
                  validator: (value) =>
                      value!.isEmpty ? "City name is required" : null,
                ),
                TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(labelText: "Country Name"),
                  validator: (value) =>
                      value!.isEmpty ? "Country name is required" : null,
                ),
                TextFormField(
                  controller: _latitudeController,
                  decoration: const InputDecoration(labelText: "Latitude"),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return "Latitude is required";
                    final lat = double.tryParse(value);
                    if (lat == null || lat < -90 || lat > 90) {
                      return "Enter a valid latitude (-90 to 90)";
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _longitudeController,
                  decoration: const InputDecoration(labelText: "Longitude"),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return "Longitude is required";
                    final lng = double.tryParse(value);
                    if (lng == null || lng < -180 || lng > 180) {
                      return "Enter a valid longitude (-180 to 180)";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final destinationData = {
                  "cityName": _cityController.text.trim(),
                  "countryName": _countryController.text.trim(),
                  "latitude": double.parse(_latitudeController.text),
                  "longitude": double.parse(_longitudeController.text),
                  "createdAt": FieldValue.serverTimestamp(),
                };

                if (doc == null) {
                  await FirebaseFirestore.instance
                      .collection("Destinations")
                      .add(destinationData);
                } else {
                  await FirebaseFirestore.instance
                      .collection("Destinations")
                      .doc(doc.id)
                      .update(destinationData);
                }

                Navigator.pop(context);
              }
            },
            child: Text(doc == null ? "Add" : "Update"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDestination(String id) async {
    await FirebaseFirestore.instance
        .collection("Destinations")
        .doc(id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FCFC),
        title: const Text("Manage Destinations"),
      ),
      drawer: const AdminMenuDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.search, color: Color(0xFF45A19B)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: "Search Destinations",
                          hintStyle: TextStyle(color: Color(0xFF45A19B)),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Color(0xFF0C1D1B)),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("Destinations")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading destinations"));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final city = (data["cityName"] ?? "").toString().toLowerCase();
                    final country = (data["countryName"] ?? "").toString().toLowerCase();
                    final search = _searchController.text.toLowerCase();
                    return search.isEmpty ||
                        city.contains(search) ||
                        country.contains(search);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No destinations found",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF45A19B),
                          child: Icon(Icons.location_on, color: Colors.white),
                        ),
                        title: Text(
                          "${data["cityName"] ?? "Unknown City"}, ${data["countryName"] ?? "Unknown Country"}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Lat: ${data["latitude"] ?? "--"} • Lng: ${data["longitude"] ?? "--"}",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _addOrEditDestination(doc: doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteDestination(doc.id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Add button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A398),
                  foregroundColor: const Color(0xFFF8FCFC),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  "Add Destination",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => _addOrEditDestination(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
