import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddExpensesScreen extends StatefulWidget {
  final QueryDocumentSnapshot userTrips;

  const AddExpensesScreen({super.key, required this.userTrips});

  @override
  State<AddExpensesScreen> createState() => _AddExpensesScreenState();
}

class _AddExpensesScreenState extends State<AddExpensesScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  DateTime? _selectedDate;

  final Color bgColor = const Color(0xFFF8FCFC);
  final Color cardBgColor = const Color(0xFFE6F4F3);
  final Color primaryColor = const Color(0xFF00A398);

  // Filter states
  DateTime? selectedFilterDate;
  String? selectedFilterCategory;
  bool sortAmountAscending = true;

  // Currency
  String userCurrencySymbol = "\$";
  double userCurrencyRate = 1.0;

  CollectionReference get expensesCollection =>
      widget.userTrips.reference.collection('expenses');

  double tripBudget() {
    final budget = widget.userTrips.data().toString().contains('budget')
        ? widget.userTrips['budget']
        : 0;
    return (budget is int) ? budget.toDouble() : (budget as double);
  }

  @override
  void initState() {
    super.initState();
    _fetchUserCurrency();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  /// Fetch user's preferred currency
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

  /// Convert a number to user's currency for display
  String formatCurrency(dynamic amount) {
    double val = 0;
    if (amount is num) val = amount.toDouble();
    else if (amount is String) val = double.tryParse(amount) ?? 0;

    final converted = val * userCurrencyRate;
    return "$userCurrencySymbol${converted.toStringAsFixed(2)}";
  }

  Future<void> _pickDate() async {
    final tripStartDate = (widget.userTrips['startDate'] as Timestamp).toDate();
    final tripEndDate = (widget.userTrips['endDate'] as Timestamp).toDate();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? tripStartDate,
      firstDate: tripStartDate,
      lastDate: tripEndDate,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('MMM dd, yyyy').format(picked);
      });
    }
  }

  void _showAddExpenseModal({DocumentSnapshot? doc}) {
    final _formKey = GlobalKey<FormState>();

    if (doc != null) {
      // Show converted amount in user's currency
      final amountInUserCurrency = (doc['amount'] as num) * userCurrencyRate;
      _amountController.text = amountInUserCurrency.toStringAsFixed(2);
      _categoryController.text = doc['category'];
      _notesController.text = doc['notes'];
      _selectedDate = (doc['date'] as Timestamp).toDate();
      _dateController.text = DateFormat('MMM dd, yyyy').format(_selectedDate!);
    } else {
      _amountController.clear();
      _categoryController.clear();
      _notesController.clear();
      _dateController.clear();
      _selectedDate = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  doc != null ? "Edit Expense" : "Add Expense",
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0C1D1B)),
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _amountController,
                label: "Amount (${userCurrencySymbol})",
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Amount is required';
                  if (double.tryParse(value) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _categoryController,
                label: "Category",
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Category is required' : null,
              ),
              const SizedBox(height: 8),
              _buildTextField(controller: _notesController, label: "Notes"),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _dateController,
                label: "Expense Date",
                readOnly: true,
                onTap: _pickDate,
                validator: (value) => (_selectedDate == null) ? 'Select a date' : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await _addOrUpdateExpense(doc: doc);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                      doc != null ? "Update Expense" : "Add Expense",
                      style: const TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addOrUpdateExpense({DocumentSnapshot? doc}) async {
    try {
      // Convert entered amount back to USD for storage
      final amountInUSD = double.parse(_amountController.text) / userCurrencyRate;

      final data = {
        'amount': amountInUSD,
        'category': _categoryController.text,
        'notes': _notesController.text,
        'date': Timestamp.fromDate(_selectedDate!),
        'createdAt': Timestamp.now(),
      };

      if (doc != null) {
        await doc.reference.update(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Expense updated successfully!")),
        );
      } else {
        await expensesCollection.add(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Expense added successfully!")),
        );
      }

      // Clear fields & filters
      _amountController.clear();
      _categoryController.clear();
      _notesController.clear();
      _dateController.clear();
      _selectedDate = null;
      selectedFilterDate = null;
      selectedFilterCategory = null;

      setState(() {}); // Refresh instantly
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save expense")),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: cardBgColor,
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon:
            readOnly ? const Icon(Icons.calendar_today, color: Color(0xFF00A398)) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _filterButton({required String label, required VoidCallback onTap}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFFE7EDF3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0E141B),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF0E141B)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripName = widget.userTrips["tripName"] ?? "No Title";
    final budget = tripBudget();
    final tripStartDate = (widget.userTrips['startDate'] as Timestamp).toDate();
    final tripEndDate = (widget.userTrips['endDate'] as Timestamp).toDate();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Expenses',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0C1D1B),
            fontSize: 20,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseModal(),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: expensesCollection.orderBy('date', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            var expenses = snapshot.data?.docs ?? [];

            // Apply filters
            if (selectedFilterDate != null) {
              expenses = expenses.where((doc) {
                final date = (doc['date'] as Timestamp).toDate();
                return date.year == selectedFilterDate!.year &&
                    date.month == selectedFilterDate!.month &&
                    date.day == selectedFilterDate!.day;
              }).toList();
            }

            if (selectedFilterCategory != null) {
              expenses = expenses
                  .where((doc) => doc['category'] == selectedFilterCategory)
                  .toList();
            }

            // Sort
            expenses.sort((a, b) {
              final amountA = (a['amount'] as num).toDouble();
              final amountB = (b['amount'] as num).toDouble();
              return sortAmountAscending
                  ? amountA.compareTo(amountB)
                  : amountB.compareTo(amountA);
            });

            double totalExpense = expenses.fold(
                0,
                (sum, exp) => sum +
                    ((exp['amount'] is int)
                        ? (exp['amount'] as int).toDouble()
                        : exp['amount'] as double));
            final remaining = budget - totalExpense;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Budget Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tripName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0C1D1B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_balance_wallet,
                                    color: Colors.black54),
                                const SizedBox(width: 8),
                                Text(formatCurrency(budget),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.money_off, color: Colors.black54),
                                const SizedBox(width: 8),
                                Text(formatCurrency(totalExpense),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.trending_up, color: Colors.black54),
                            const SizedBox(width: 8),
                            Text("Remaining: ${formatCurrency(remaining)}",
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (totalExpense / budget).clamp(0, 1),
                          color: remaining >= 0 ? Colors.green : Colors.red,
                          backgroundColor: Colors.grey.shade300,
                          minHeight: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "All Expenses",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterButton(
                          label: "Date",
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedFilterDate ?? tripStartDate,
                              firstDate: tripStartDate,
                              lastDate: tripEndDate,
                            );
                            if (picked != null) {
                              setState(() {
                                selectedFilterDate = picked;
                                selectedFilterCategory = null;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        _filterButton(
                          label: "Category",
                          onTap: () async {
                            final snapshot = await expensesCollection.get();
                            final categories = snapshot.docs
                                .map((e) => e['category'].toString())
                                .toSet()
                                .toList();

                            showModalBottomSheet(
                              context: context,
                              builder: (context) => ListView(
                                shrinkWrap: true,
                                children: categories.map((cat) {
                                  return ListTile(
                                    title: Text(cat),
                                    onTap: () {
                                      setState(() {
                                        selectedFilterCategory = cat;
                                        selectedFilterDate = null;
                                      });
                                      Navigator.pop(context);
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _filterButton(
                          label: "Amount",
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: const Text("Low to High"),
                                    onTap: () {
                                      setState(() {
                                        sortAmountAscending = true;
                                        selectedFilterDate = null;
                                        selectedFilterCategory = null;
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    title: const Text("High to Low"),
                                    onTap: () {
                                      setState(() {
                                        sortAmountAscending = false;
                                        selectedFilterDate = null;
                                        selectedFilterCategory = null;
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: expenses.isEmpty
                      ? const Center(child: Text("No expenses found"))
                      : ListView.separated(
                          itemCount: expenses.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final expense = expenses[index];
                            final amount = expense["amount"] ?? 0;
                            final category = expense["category"] ?? "";
                            final notes = expense["notes"] ?? "";
                            final date = (expense["date"] as Timestamp?)?.toDate();

                            return Card(
                              color: cardBgColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(
                                  "$category - ${formatCurrency(amount)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (notes.isNotEmpty) Text("Notes: $notes"),
                                    if (date != null)
                                      Text(
                                        "Date: ${DateFormat('MMM dd, yyyy').format(date)}",
                                      ),
                                  ],
                                ),
                                leading: const Icon(
                                  Icons.attach_money,
                                  color: Colors.teal,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.black87,
                                  ),
                                  onPressed: () => _showAddExpenseModal(doc: expense),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
