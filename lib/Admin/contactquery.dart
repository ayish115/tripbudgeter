import 'package:flutter/material.dart';
import 'package:tripbudgeter/Admin/drawer.dart';

class ContactQueryScreen extends StatefulWidget {
  const ContactQueryScreen({Key? key}) : super(key: key);

  @override
  State<ContactQueryScreen> createState() => _ContactQueryScreenState();
}

class _ContactQueryScreenState extends State<ContactQueryScreen> {
  // Sample data — replace with API/backend fetch
  List<Map<String, String>> queries = [
    {
      "name": "John Doe",
      "email": "john@example.com",
      "message": "What is the refund policy for bookings?"
    },
    {
      "name": "Sarah Khan",
      "email": "sarah@example.com",
      "message": "Can I change my booking dates?"
    },
  ];

  final TextEditingController replyController = TextEditingController();

  void _replyToUser(String email) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Reply to $email"),
          content: TextField(
            controller: replyController,
            decoration: const InputDecoration(
              hintText: "Type your reply here...",
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                replyController.clear();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Send reply via backend/email API
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Reply sent to $email")),
                );
                Navigator.pop(context);
                replyController.clear();
              },
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FCFC),
        title: const Text("Contact Queries", style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      drawer: const AdminMenuDrawer(),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: queries.length,
        itemBuilder: (context, index) {
          final query = queries[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(query["name"] ?? ""),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(query["email"] ?? "", style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 5),
                  Text(query["message"] ?? ""),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.reply, color: Colors.blue),
                onPressed: () => _replyToUser(query["email"] ?? ""),
              ),
            ),
          );
        },
      ),
    );
  }
}
