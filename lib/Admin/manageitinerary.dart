import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tripbudgeter/Admin/drawer.dart';

class ItineraryDetailScreen extends StatelessWidget {
  final DocumentSnapshot itinerary;
  const ItineraryDetailScreen({Key? key, required this.itinerary})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FCFC),
        title: Text(itinerary["tripName"] ?? "Itinerary Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: Colors.grey.shade300,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itinerary["tripName"] ?? "",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C1D1B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InfoRow(
                      label: "Destination",
                      value: itinerary["destinationName"] ?? "",
                    ),
                    InfoRow(
                      label: "Budget",
                      value: itinerary["budget"] != null
                          ? "\$${itinerary["budget"].toString()}"
                          : "",
                    ),
                    InfoRow(
                      label: "Details",
                      value: itinerary["details"] ?? "",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable info row widget
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const InfoRow({Key? key, required this.label, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C1D1B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF0C1D1B)),
            ),
          ),
        ],
      ),
    );
  }
}

class ManageItineraryScreen extends StatefulWidget {
  const ManageItineraryScreen({Key? key}) : super(key: key);

  @override
  State<ManageItineraryScreen> createState() => _ManageItineraryScreenState();
}

class _ManageItineraryScreenState extends State<ManageItineraryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController searchController = TextEditingController();

  List<QueryDocumentSnapshot> itineraries = [];
  List<QueryDocumentSnapshot> filteredItineraries = [];

  @override
  void initState() {
    super.initState();
    _loadItineraries();
  }

  Future<void> _loadItineraries() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection("Itineraries")
          .orderBy("createdAt", descending: true)
          .get();
      setState(() {
        itineraries = snapshot.docs;
        filteredItineraries = snapshot.docs;
      });
    } catch (e) {
      debugPrint("Error loading itineraries: $e");
    }
  }

  void _filterItineraries(String query) {
    setState(() {
      filteredItineraries = itineraries.where((doc) {
        final tripName = (doc["tripName"] ?? "").toString().toLowerCase();
        return tripName.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _addItinerary() async {
    _addOrEditItinerary();
  }

  void _addOrEditItinerary({DocumentSnapshot? doc}) async {
    QuerySnapshot destSnapshot =
        await _firestore.collection("Destinations").get();
    List<QueryDocumentSnapshot> destinations = destSnapshot.docs;

    if (destinations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add destinations first.")),
      );
      return;
    }

    String? selectedDestinationId = doc?["destinationId"];
    String? selectedDestinationName;

    if (selectedDestinationId != null) {
      final match = destinations.firstWhere(
        (d) => d.id == selectedDestinationId,
        orElse: () => destinations.first,
      );
      selectedDestinationName = match["cityName"];
    }

    final tripNameController = TextEditingController(
      text: doc?["tripName"] ?? "",
    );
    final costController = TextEditingController(
      text: doc?["budget"]?.toString() ?? "",
    );
    final detailsController = TextEditingController(
      text: doc?["details"] ?? "",
    );

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(doc == null ? "Add Itinerary" : "Edit Itinerary"),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: tripNameController,
                  decoration: const InputDecoration(labelText: "Trip Name"),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Required" : null,
                ),
                DropdownButtonFormField<String>(
                  value: selectedDestinationId,
                  decoration:
                      const InputDecoration(labelText: "Select Destination"),
                  items: destinations.map((d) {
                    return DropdownMenuItem<String>(
                      value: d.id,
                      child: Text("${d['cityName']} (${d['countryName']})"),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDestinationId = value;
                      selectedDestinationName = destinations.firstWhere(
                        (d) => d.id == value,
                      )["cityName"];
                    });
                  },
                  validator: (value) =>
                      value == null ? "Please select a destination" : null,
                ),
                TextFormField(
                  controller: costController,
                  decoration: const InputDecoration(labelText: "Budget"),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Required";
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed < 0) {
                      return "Enter a valid budget";
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: detailsController,
                  decoration: const InputDecoration(labelText: "Details"),
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
              if (!formKey.currentState!.validate()) return;

              final data = {
                "tripName": tripNameController.text.trim(),
                "destinationId": selectedDestinationId,
                "destinationName": selectedDestinationName,
                "budget": double.parse(costController.text),
                "details": detailsController.text.trim(),
                "createdAt": FieldValue.serverTimestamp(),
              };

              try {
                if (doc == null) {
                  await _firestore.collection("Itineraries").add(data);
                } else {
                  await _firestore
                      .collection("Itineraries")
                      .doc(doc.id)
                      .update(data);
                }
                await _loadItineraries();
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error saving: $e")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteItinerary(String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content:
            const Text("Are you sure you want to delete this itinerary?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection("Itineraries").doc(docId).delete();
                await _loadItineraries();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error deleting: $e")),
                );
              }
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FCFC),
        title: const Text('Manage Itineraries'),
      ),
      drawer: const AdminMenuDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: "Search Itineraries",
                          hintStyle: TextStyle(color: Color(0xFF45A19B)),
                          border: InputBorder.none,
                        ),
                        style:
                            const TextStyle(color: Color(0xFF0C1D1B)),
                        onChanged: _filterItineraries,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Existing Itineraries",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C1D1B),
                  ),
                ),
              ),
            ),

            // Itinerary List
            Expanded(
              child: filteredItineraries.isEmpty
                  ? const Center(child: Text("No itineraries found"))
                  : ListView.builder(
                      itemCount: filteredItineraries.length,
                      itemBuilder: (context, index) {
                        final doc = filteredItineraries[index];
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         
                          title: Text(
                            (doc["tripName"] ?? "No Name").toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${doc["destinationName"] ?? ""} | Budget: \$${doc["budget"] ?? ""}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.info_outline),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ItineraryDetailScreen(itinerary: doc),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    _deleteItinerary(doc.id),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Add Button
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
                  "Add Itinerary",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: _addItinerary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
