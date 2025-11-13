import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'report_download_stub.dart' if (dart.library.html) 'report_download_web.dart';

class ReportScreen extends StatefulWidget {
  final QueryDocumentSnapshot tripDoc;
  const ReportScreen({super.key, required this.tripDoc});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime? startDate;
  DateTime? endDate;

  late DateTime tripStartDate;
  late DateTime tripEndDate;

  final Color bgColor = const Color(0xFFF8FCFC);
  final Color cardBgColor = const Color(0xFFE6F4F3);
  final Color primaryColor = const Color(0xFF00A398);

  final dateFormat = DateFormat('MMM dd, yyyy');
  String userCurrencySymbol = "\$";
  double userCurrencyRate = 1.0;

  CollectionReference get expensesCollection =>
      widget.tripDoc.reference.collection('expenses');

  @override
  void initState() {
    super.initState();
    tripStartDate = (widget.tripDoc['startDate'] as Timestamp).toDate();
    tripEndDate = (widget.tripDoc['endDate'] as Timestamp).toDate();
    _fetchUserCurrency();
  }

  Future<void> _fetchUserCurrency() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
    if (!userDoc.exists) return;

    final preferredCurrencyId = userDoc['preferredCurrencyId'];
    if (preferredCurrencyId == null) return;

    final currencyDoc = await FirebaseFirestore.instance
        .collection('currencies')
        .doc(preferredCurrencyId)
        .get();
    if (!currencyDoc.exists) return;

    final data = currencyDoc.data()!;
    setState(() {
      userCurrencySymbol = data['code'] ?? "\$";
      userCurrencyRate = (data['rate'] ?? 1).toDouble();
    });
  }

  String formatCurrency(dynamic amount) {
    double val = 0;
    if (amount is num) val = amount.toDouble();
    else if (amount is String) val = double.tryParse(amount) ?? 0;
    final converted = val * userCurrencyRate;
    return "$userCurrencySymbol${converted.toStringAsFixed(2)}";
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? tripStartDate,
      firstDate: tripStartDate,
      lastDate: tripEndDate,
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
        if (endDate != null && endDate!.isBefore(startDate!)) endDate = startDate;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? tripEndDate,
      firstDate: tripStartDate,
      lastDate: tripEndDate,
    );
    if (picked != null) {
      setState(() {
        endDate = picked;
        if (startDate != null && startDate!.isAfter(endDate!)) startDate = endDate;
      });
    }
  }

  Future<void> _generateCsvReport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Query query = expensesCollection;
    if (startDate != null) query = query.where('date', isGreaterThanOrEqualTo: startDate);
    if (endDate != null) {
      final endOfDay = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59, 999);
      query = query.where('date', isLessThanOrEqualTo: endOfDay);
    }

    final snapshot = await query.get();
    final expenses = snapshot.docs;
    if (expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No data to generate report.")),
      );
      return;
    }

    // Build CSV content
    List<List<String>> rows = [
      ['Date', 'Category', 'Amount', 'Notes'],
    ];

    List<Map<String, dynamic>> expenseDataForArchive = [];

    for (var exp in expenses) {
      final date = (exp['date'] as Timestamp?)?.toDate();
      final amount = double.tryParse(exp['amount']?.toString() ?? '0') ?? 0 * userCurrencyRate;
      final category = exp['category'] ?? '';
      final notes = exp['notes'] ?? '';

      rows.add([
        date != null ? DateFormat('yyyy-MM-dd HH:mm').format(date) : '',
        category,
        amount.toStringAsFixed(2),
        notes,
      ]);

      expenseDataForArchive.add({
        'expenseId': exp.id,
        'category': category,
        'amount': amount,
        'notes': notes,
        'date': date?.toIso8601String(),
      });
    }

    // Save report to Firestore
    await FirebaseFirestore.instance.collection('reports').add({
      'tripId': widget.tripDoc.id,
      'tripName': widget.tripDoc['tripName'] ?? '',
      'userId': user.uid,
      'fromDate': (startDate ?? tripStartDate).toIso8601String(),
      'toDate': (endDate ?? tripEndDate).toIso8601String(),
      'generatedAt': DateTime.now().toIso8601String(),
      'expenses': expenseDataForArchive,
    });

    // Convert rows to CSV string
    String csv = rows.map((r) => r.map((e) => '"${e.replaceAll('"', '""')}"').join(',')).join('\n');
    final fileName = "${widget.tripDoc['tripName'] ?? 'Trip'}_Report_${DateTime.now().millisecondsSinceEpoch}.csv";

    if (kIsWeb) {
      downloadFileWeb(Uint8List.fromList(csv.codeUnits), fileName);
    } else {
      String? path = await FilePicker.platform.saveFile(dialogTitle: 'Save CSV Report', fileName: fileName);
      if (path == null) return;
      final file = File(path);
      await file.writeAsBytes(Uint8List.fromList(csv.codeUnits), flush: true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("CSV report saved at: $path")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "${widget.tripDoc['tripName'] ?? 'Trip'} Reports",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0C1D1B),
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: cardBgColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "Generate Report",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0C1D1B)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.date_range, color: Color(0xFF0C1D1B)),
                            label: Text(
                              startDate != null ? "From: ${dateFormat.format(startDate!)}" : "Select Start Date",
                              style: const TextStyle(color: Color(0xFF0C1D1B)),
                            ),
                            onPressed: _pickStartDate,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.date_range, color: Color(0xFF0C1D1B)),
                            label: Text(
                              endDate != null ? "To: ${dateFormat.format(endDate!)}" : "Select End Date",
                              style: const TextStyle(color: Color(0xFF0C1D1B)),
                            ),
                            onPressed: _pickEndDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text("Generate CSV Report & Save to Archive"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _generateCsvReport,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: expensesCollection.orderBy('date', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final expenses = snapshot.data!.docs;
                  if (expenses.isEmpty) return const Center(child: Text("No expenses found"));
                  return ListView.separated(
                    itemCount: expenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final exp = expenses[index];
                      final amount = double.tryParse(exp['amount']?.toString() ?? '0') ?? 0;
                      final category = exp['category'] ?? '';
                      final notes = exp['notes'] ?? '';
                      final date = (exp['date'] as Timestamp?)?.toDate();

                      return Card(
                        color: cardBgColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(
                            "$category - ${formatCurrency(amount)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (notes.isNotEmpty) Text("Notes: $notes"),
                              if (date != null) Text("Date: ${dateFormat.format(date)}"),
                            ],
                          ),
                          leading: const Icon(Icons.attach_money, color: Colors.teal),
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
