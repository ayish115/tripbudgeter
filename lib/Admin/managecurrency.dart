import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tripbudgeter/Admin/drawer.dart';

class ManageCurrenciesScreen extends StatefulWidget {
  const ManageCurrenciesScreen({Key? key}) : super(key: key);

  @override
  State<ManageCurrenciesScreen> createState() => _ManageCurrenciesScreenState();
}

class _ManageCurrenciesScreenState extends State<ManageCurrenciesScreen> {
  final CollectionReference currenciesRef = FirebaseFirestore.instance
      .collection('currencies');

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  void _openCurrencyDialog({String? docId, Map<String, dynamic>? data}) {
    if (data != null) {
      _codeController.text = data['code'];
      _nameController.text = data['name'];
      _rateController.text = data['rate'].toString();
    } else {
      _codeController.clear();
      _nameController.clear();
      _rateController.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(docId == null ? "Add Currency" : "Edit Currency"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: "Code"),
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: _rateController,
              decoration: const InputDecoration(labelText: "Rate"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_codeController.text.isNotEmpty &&
                  _nameController.text.isNotEmpty &&
                  double.tryParse(_rateController.text) != null) {
                final currencyData = {
                  "code": _codeController.text,
                  "name": _nameController.text,
                  "rate": double.parse(_rateController.text),
                };
                if (docId == null) {
                  currenciesRef.add(currencyData);
                } else {
                  currenciesRef.doc(docId).update(currencyData);
                }
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteCurrency(String docId) {
    currenciesRef.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FCFC),
        title: const Text('Manage Currencies'),
      ),
      drawer: const AdminMenuDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
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
                          hintText: "Search Currencies",
                          hintStyle: TextStyle(color: Color(0xFF45A19B)),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Color(0xFF0C1D1B)),
                        onChanged: (value) {
                          setState(() {}); // Trigger rebuild for filtering
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Existing Currencies Title
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Existing Currencies",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C1D1B),
                  ),
                ),
              ),
            ),

            // Currency List from Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: currenciesRef.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  final filteredDocs = docs.where((doc) {
                    final code = doc['code'].toString().toLowerCase();
                    final name = doc['name'].toString().toLowerCase();
                    final search = _searchController.text.toLowerCase();
                    return search.isEmpty ||
                        code.contains(search) ||
                        name.contains(search);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No currencies found",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF45A19B),
                          child: Text(
                            doc['code'],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          doc['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Rate: ${doc['rate']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _openCurrencyDialog(
                                docId: doc.id,
                                data: doc.data() as Map<String, dynamic>,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteCurrency(doc.id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Add Currency Button
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
                  "Add Currency",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => _openCurrencyDialog(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
