import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tripbudgeter/Admin/drawer.dart';

class ManageUserScreen extends StatefulWidget {
  const ManageUserScreen({Key? key}) : super(key: key);

  @override
  State<ManageUserScreen> createState() => _ManageUserScreenState();
}

class _ManageUserScreenState extends State<ManageUserScreen> {
  final TextEditingController searchController = TextEditingController();
  final CollectionReference<Map<String, dynamic>> usersRef =
      FirebaseFirestore.instance.collection('users');

  String searchQuery = "";

  void _updateUserStatus(String docId, String currentStatus) {
    String newStatus = currentStatus == "Active" ? "Blocked" : "Active";
    usersRef.doc(docId).update({"status": newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FCFC),
        title: const Text("Manage Users"),
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
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: "Search Users",
                          hintStyle: TextStyle(color: Color(0xFF45A19B)),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Color(0xFF0C1D1B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Existing Users Title
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Existing Users",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C1D1B),
                  ),
                ),
              ),
            ),

            // User List
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: usersRef.where("role", isEqualTo: "User").snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No users found",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  final users = snapshot.data!.docs.where((doc) {
                    final name = (doc.data()['fullName'] ?? "").toLowerCase();
                    final email = (doc.data()['email'] ?? "").toLowerCase();
                    return searchQuery.isEmpty ||
                        name.contains(searchQuery) ||
                        email.contains(searchQuery);
                  }).toList();

                  if (users.isEmpty) {
                    return const Center(
                      child: Text(
                        "No users found",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final data = users[index].data();
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: data['image'] != null && data['image'] != ""
                              ? Image.network(
                                  data['image'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey.shade300,
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                        title: Text(
                          data['fullName'] ?? "",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['email'] ?? ""),
                            Text(
                              "Status: ${data['status'] ?? 'Active'}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: (data['status'] ?? 'Active') == "Active"
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _updateUserStatus(
                            users[index].id,
                            data['status'] ?? "Active",
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
