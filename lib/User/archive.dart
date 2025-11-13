import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tripbudgeter/User/contact.dart';
import 'report_download_stub.dart' if (dart.library.html) 'report_download_web.dart';
import 'package:intl/intl.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
  final TextEditingController _searchController = TextEditingController();

  static const primaryColor = Color(0xFF00A398);
  static const backgroundColor = Color(0xFFF8FCFC);
  final Color cardBgColor = const Color(0xFFE6F4F3);
  static const iconColor = Color(0xFF555555);

  String generateCsv(List<dynamic> expenses) {
    List<List<String>> rows = [
      ['Date', 'Category', 'Amount', 'Notes'],
    ];

    for (var exp in expenses) {
      final date = exp['date'] ?? '';
      final category = exp['category'] ?? '';
      final amount = exp['amount'] ?? 0;
      final notes = exp['notes'] ?? '';

      rows.add([
        date.toString(),
        category,
        amount.toString(),
        notes,
      ]);
    }

    return rows
        .map((r) => r
            .map((e) => '"${e.toString().replaceAll('"', '""')}"')
            .join(','))
        .join('\n');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
     appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Padding(
          padding: EdgeInsets.only(left: 16), // Left padding for title
          child: Text(
            "Past Reports",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C1D1B),
              fontSize: 20,
              letterSpacing: -0.3,
            ),
          ),
        ),
        actions: [
    Padding(
      padding: const EdgeInsets.only(right: 16),
      child: IconButton(
        icon: const Icon(
          Icons.help_outline,
          size: 28,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ContactUsScreen()),
          );
        },
      ),
    ),
  ],
      ),
      
      body: Column(
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
                        hintText: "Search Trips",
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

          // Reports List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .where('userId', isEqualTo: user!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var reports = snapshot.data!.docs;

                // Filter by search input
                if (_searchController.text.isNotEmpty) {
                  final query = _searchController.text.toLowerCase();
                  reports = reports
                      .where((r) =>
                          (r['tripName'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains(query))
                      .toList();
                }

                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.archive_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No archived reports found",
                          style: TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }

                reports.sort((a, b) {
                  final dateA = DateTime.tryParse(a['generatedAt'] ?? '') ?? DateTime(2000);
                  final dateB = DateTime.tryParse(b['generatedAt'] ?? '') ?? DateTime(2000);
                  return dateB.compareTo(dateA);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final tripName = report['tripName'] ?? 'Trip';
                    final fromDate = report['fromDate'] != null
                        ? DateTime.tryParse(report['fromDate'])
                        : null;
                    final toDate = report['toDate'] != null
                        ? DateTime.tryParse(report['toDate'])
                        : null;
                    final generatedAt = report['generatedAt'] != null
                        ? DateTime.tryParse(report['generatedAt'])
                        : null;
                    final expenses = report['expenses'] ?? [];

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: cardBgColor,
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tripName,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            if (fromDate != null && toDate != null)
                              Row(
                                children: [
                                  const Icon(Icons.date_range, size: 18, color: iconColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${DateFormat('MMM dd, yyyy').format(fromDate)} - ${DateFormat('MMM dd, yyyy').format(toDate)}",
                                    style: const TextStyle(color: iconColor),
                                  ),
                                ],
                              ),
                            if (generatedAt != null)
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 18, color: iconColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Generated: ${dateFormat.format(generatedAt)}",
                                    style: const TextStyle(color: iconColor),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Download CSV
                                ElevatedButton.icon(
                                  onPressed: () {
                                    if (expenses.isNotEmpty) {
                                      final csv = generateCsv(expenses);
                                      final fileName =
                                          "${tripName}_Report_${DateTime.now().millisecondsSinceEpoch}.csv";
                                      downloadFileWeb(Uint8List.fromList(csv.codeUnits), fileName);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text("No expenses to generate CSV")),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.download, size: 20),
                                  label: const Text("Download"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Delete icon
                                IconButton(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text("Confirm Delete"),
                                        content: const Text(
                                            "Are you sure you want to delete this report?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(false),
                                            child: const Text("Cancel"),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.of(ctx).pop(true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red[600],
                                            ),
                                            child: const Text("Delete"),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('reports')
                                            .doc(report.id)
                                            .delete();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text("Report deleted successfully")),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text("Failed to delete report: $e")),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.delete, color: Color.fromARGB(255, 87, 87, 87)),
                                  tooltip: "Delete Report",
                                ),
                              ],
                            ),
                          ],
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
    );
  }
}
