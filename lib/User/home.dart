import 'package:flutter/material.dart';
import 'package:tripbudgeter/User/about.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Static user data
  String fullName = '';

  // Static active trip
  Map<String, dynamic>? activeTrip = {
    'tripName': 'Tokyo Adventure',
    'budget': 1200,
    'imageUrl':
        'https://images.unsplash.com/photo-1559181567-c3190ca9959b?auto=format&fit=crop&w=800&q=60',
  };

  // Static recent expenses
  List<Map<String, dynamic>> recentExpenses = [
    {'notes': 'Lunch at Sushi Place', 'category': 'Food', 'amount': 45},
    {'notes': 'Museum Ticket', 'category': 'Entertainment', 'amount': 30},
    {'notes': 'Taxi Ride', 'category': 'Transport', 'amount': 20},
  ];

  // Static overview
  int totalTrips = 3;
  double totalSpent = 95;
  double remainingBudget = 1105;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FCFC),
        elevation: 0,
        title: const Text(
          "TripBudgeter",
          style: TextStyle(
            color: Color(0xFF0C1D1B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.help_outline, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Welcome
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Welcome, $fullName",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C1D1B),
                  ),
                ),
              ),
            ),

            // Overview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _overviewItem("Total Trips", "$totalTrips"),
                    _overviewItem(
                      "Total Spent",
                      "\$${totalSpent.toStringAsFixed(2)}",
                    ),
                    _overviewItem(
                      "Remaining",
                      "\$${remainingBudget.toStringAsFixed(2)}",
                    ),
                  ],
                ),
              ),
            ),

            // Active Trip
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Active Trip",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C1D1B),
                  ),
                ),
              ),
            ),
            if (activeTrip != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Ongoing",
                                style: TextStyle(
                                  color: Color(0xFF45A19B),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activeTrip!['tripName'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0C1D1B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "\$${_calculateRemainingBudget(activeTrip!)} remaining",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF45A19B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            activeTrip!['imageUrl'] ??
                                "https://via.placeholder.com/150",
                            fit: BoxFit.cover,
                            height: 100,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No active trips found."),
              ),

            // Recent Expenses
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Recent Expenses",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C1D1B),
                  ),
                ),
              ),
            ),
            ...recentExpenses.map(
              (e) => _expenseTile(
                e['notes'] ?? 'Expense',
                e['category'] ?? '',
                '-\$${e['amount'] ?? 0}',
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  int _calculateRemainingBudget(Map<String, dynamic> trip) {
    final budget = (trip['budget'] ?? 0).toDouble();
    final spent = recentExpenses.fold<double>(
      0.0,
      (sum, expense) => sum + ((expense['amount'] ?? 0).toDouble()),
    );
    return (budget - spent).toInt();
  }

  Widget _overviewItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0C1D1B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Color(0xFF45A19B)),
        ),
      ],
    );
  }

  static Widget _expenseTile(String name, String category, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF0C1D1B),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              Text(
                category,
                style: const TextStyle(color: Color(0xFF45A19B), fontSize: 14),
              ),
            ],
          ),
          Text(
            amount,
            style: const TextStyle(color: Color(0xFF0C1D1B), fontSize: 16),
          ),
        ],
      ),
    );
  }
}
