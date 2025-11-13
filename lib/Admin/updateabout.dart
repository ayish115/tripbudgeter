import 'package:flutter/material.dart';
import 'package:tripbudgeter/Admin/drawer.dart';

class UpdateAboutScreen extends StatefulWidget {
  const UpdateAboutScreen({Key? key}) : super(key: key);

  @override
  State<UpdateAboutScreen> createState() => _UpdateAboutScreenState();
}

class _UpdateAboutScreenState extends State<UpdateAboutScreen> {
  final TextEditingController aboutController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FCFC),
        title: const Text(
          "Update About",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      drawer: const AdminMenuDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "About Us",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: aboutController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: "Enter About Us information...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Save logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("About Us updated successfully!")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Update",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
