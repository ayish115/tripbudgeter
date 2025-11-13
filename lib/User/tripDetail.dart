import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TripDetailScreen extends StatefulWidget {
  final QueryDocumentSnapshot itinerary;

  const TripDetailScreen({super.key, required this.itinerary});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  String userCurrencySymbol = "\$"; // default
  double userCurrencyRate = 1.0;   // default

  @override
  void initState() {
    super.initState();
    _fetchUserCurrency();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  /// Fetch user's preferred currency symbol and rate
  Future<void> _fetchUserCurrency() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();

    if (userDoc.exists) {
      final preferredCurrencyId = userDoc['preferredCurrencyId'];
      if (preferredCurrencyId != null) {
        final currencyDoc = await FirebaseFirestore.instance
            .collection('currencies')
            .doc(preferredCurrencyId)
            .get();

        if (currencyDoc.exists) {
          final data = currencyDoc.data()!;
          setState(() {
            userCurrencySymbol = data['code'] ?? "\$";
            userCurrencyRate = (data['rate'] ?? 1).toDouble();
          });
        }
      }
    }
  }

  String convertBudget(dynamic budget) {
    double original = 0;
    if (budget is num) original = budget.toDouble();
    else if (budget is String) original = double.tryParse(budget) ?? 0;

    final converted = original * userCurrencyRate;
    return "$userCurrencySymbol${converted.toStringAsFixed(2)}";
  }

  Future<void> _pickStartDate() async {
    DateTime now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now, // Start date cannot be in the past
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _startDateController.text = DateFormat("dd/MM/yyyy").format(picked);

        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
          _endDateController.clear();
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select start date first")),
      );
      return;
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!.add(const Duration(days: 1)),
      firstDate: _startDate!.add(const Duration(days: 1)), // End must be after start
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
        _endDateController.text = DateFormat("dd/MM/yyyy").format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.itinerary;
    const Color primaryColor = Color(0xFF00A398);
    const Color bgColor = Color(0xFFF8FCFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: const Text(
          "Trip Details",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0C1D1B),
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trip Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc["tripName"] ?? "Trip",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0C1D1B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _infoRow(Icons.flight_takeoff, "Trip Name", doc["tripName"]),
                      const SizedBox(height: 12),
                      _infoRow(Icons.location_on, "Destination", doc["destinationName"]),
                      const SizedBox(height: 12),
                      _infoRow(
                        Icons.attach_money,
                        "Budget",
                        convertBudget(doc["budget"]),
                      ),
                      const SizedBox(height: 12),
                      _infoRow(
                        Icons.notes,
                        "Details",
                        (doc["details"] ?? "").toString().isNotEmpty
                            ? doc["details"]
                            : "No details",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Start Date
                _buildDateField(
                  label: "Start Date",
                  controller: _startDateController,
                  onTap: _pickStartDate,
                  validator: (value) =>
                      value!.isEmpty ? "Please select a start date" : null,
                ),
                const SizedBox(height: 16),

                // End Date
                _buildDateField(
                  label: "End Date",
                  controller: _endDateController,
                  onTap: _pickEndDate,
                  validator: (value) {
                    if (value!.isEmpty) return "Please select an end date";
                    if (_startDate != null &&
                        _endDate != null &&
                        _endDate!.isBefore(_startDate!)) {
                      return "End date must be after start date";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.check_circle,
                      color: Color(0xFFE6F4F3),
                    ),
                    label: const Text(
                      "Confirm Trip",
                      style: TextStyle(fontSize: 16, color: Color(0xFFE6F4F3)),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        await FirebaseFirestore.instance.collection("UserTrips").add({
                          "userId": user.uid,
                          "tripId": doc.id,
                          "tripName": doc["tripName"],
                          "destinationName": doc["destinationName"],
                          "budget": doc["budget"],
                          "startDate": _startDate,
                          "endDate": _endDate,
                          "createdAt": Timestamp.now(),
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Trip added successfully!"),
                          ),
                        );

                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFE6F4F3),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF00A398)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onTap: onTap,
      validator: validator,
    );
  }

  Widget _infoRow(IconData icon, String title, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F4F3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF00A398), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value ?? "",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C1D1B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
