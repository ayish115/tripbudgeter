import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final bgColor = const Color(0xFFF8FCFC);
  final cardBgColor = const Color(0xFFE6F4F3);

  late TextEditingController _tripNameController;
  late TextEditingController _budgetController;
  late TextEditingController _destinationController;

  DateTime? _startDate;
  DateTime? _endDate;

  String? _selectedDestinationId;
  String? _selectedDestinationName;

  // Currency
  String userCurrencySymbol = "\$"; // default
  double userCurrencyRate = 1.0; // conversion rate to USD

  @override
  void initState() {
    super.initState();
    _tripNameController = TextEditingController();
    _budgetController = TextEditingController();
    _destinationController = TextEditingController();
    _fetchUserCurrency();
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    _budgetController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

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

  Future<void> _pickDate({required bool isStart}) async {
    DateTime now = DateTime.now();
    DateTime initialDate = isStart ? now : (_startDate ?? now).add(const Duration(days: 1));

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: isStart ? now : (_startDate ?? now).add(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;

          // Reset end date if it's before start date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _createTrip() async {
  if (_formKey.currentState!.validate() &&
      (_selectedDestinationId != null || _destinationController.text.isNotEmpty) &&
      _startDate != null &&
      _endDate != null) {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Parse the entered budget
    double enteredBudget = 0;
    try {
      enteredBudget = double.parse(_budgetController.text.trim());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid budget format')),
      );
      return;
    }

    // Convert budget to USD
    double budgetInUSD = enteredBudget / userCurrencyRate;

    String destinationName = _destinationController.text.trim();
    if (_selectedDestinationName != null && _selectedDestinationName!.isNotEmpty) {
      destinationName = _selectedDestinationName!;
    }

    // Ensure all dates are stored as Timestamp
    Timestamp startTimestamp = Timestamp.fromDate(_startDate!);
    Timestamp endTimestamp = Timestamp.fromDate(_endDate!);

    await FirebaseFirestore.instance.collection("UserTrips").add({
      'userId': user.uid,
      'tripName': _tripNameController.text.trim(),
      'destinationId': _selectedDestinationId ?? '',
      'destinationName': destinationName,
      'budget': budgetInUSD, // <-- store USD
      'startDate': startTimestamp,
      'endDate': endTimestamp,
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip created successfully')),
    );

    Navigator.pop(context);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill all fields and select dates')),
    );
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
        title: const Text(
          'Create Trip',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0C1D1B),
            fontSize: 20,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Trip Name
                TextFormField(
                  controller: _tripNameController,
                  decoration: InputDecoration(
                    labelText: 'Trip Name',
                    filled: true,
                    fillColor: cardBgColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter trip name' : null,
                ),
                const SizedBox(height: 16),

                // Destination (Editable)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Destinations')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final destinations = snapshot.data!.docs;
                    return Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        return destinations
                            .map((doc) => doc['cityName'].toString())
                            .where((city) => city
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase()))
                            .toList();
                      },
                      onSelected: (selection) {
                        setState(() {
                          _destinationController.text = selection;
                          final selectedDoc = destinations.firstWhere(
                              (doc) => doc['cityName'] == selection);
                          _selectedDestinationId = selectedDoc.id;
                          _selectedDestinationName = selection;
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        _destinationController = controller;
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          decoration: InputDecoration(
                            labelText: 'Destination',
                            filled: true,
                            fillColor: cardBgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Enter destination' : null,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Budget
                TextFormField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Budget (${userCurrencySymbol})',
                    filled: true,
                    fillColor: cardBgColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter budget';
                    final val = double.tryParse(value);
                    if (val == null || val <= 0) return 'Enter a valid budget';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Start & End Date
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickDate(isStart: true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _startDate == null
                                ? 'Select Start Date'
                                : DateFormat('MMM dd, yyyy').format(_startDate!),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickDate(isStart: false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _endDate == null
                                ? 'Select End Date'
                                : DateFormat('MMM dd, yyyy').format(_endDate!),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Create Trip Button
                ElevatedButton(
                  onPressed: _createTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF45A19B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Create Trip',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
