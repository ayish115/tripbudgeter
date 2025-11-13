import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:tripbudgeter/User/archive.dart';
import 'package:tripbudgeter/User/contact.dart';
import 'package:tripbudgeter/User/createTrip.dart';
import 'package:tripbudgeter/User/expenses.dart';
import 'package:tripbudgeter/User/report.dart';
import 'package:tripbudgeter/User/tripDetail.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  static const bgColor = Color(0xFFF8FCFC);
  int activeTabIndex = 0;

  List<QueryDocumentSnapshot> availableTrips = [];
  List<QueryDocumentSnapshot> activeTrips = [];
  List<QueryDocumentSnapshot> completedTrips = [];

  bool loadingAvailable = true;
  bool loadingActive = true;
  bool loadingCompleted = true;

  final user = FirebaseAuth.instance.currentUser;

  // User currency info
  double userCurrencyRate = 1.0;
  String userCurrencySymbol = "\$";

  @override
  void initState() {
    super.initState();
    fetchUserCurrency().then((_) {
      fetchAvailableTrips();
      if (user != null) fetchUserTrips();
      else {
        loadingActive = false;
        loadingCompleted = false;
      }
    });
  }

  /// Fetch user currency info from Firestore
  Future<void> fetchUserCurrency() async {
    if (user == null) return;
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection("Users").doc(user!.uid).get();
      if (!userDoc.exists) return;

      final preferredCurrencyId = userDoc['preferredCurrencyId'];
      if (preferredCurrencyId == null) return;

      final currencyDoc = await FirebaseFirestore.instance
          .collection("currencies")
          .doc(preferredCurrencyId)
          .get();

      if (currencyDoc.exists) {
        final data = currencyDoc.data()!;
        setState(() {
          userCurrencyRate = (data['rate'] as num).toDouble();
          userCurrencySymbol = data['code'] ?? "\$";
        });
      }
    } catch (e) {
      print("Error fetching user currency: $e");
    }
  }

  /// Convert budget to user currency
  String convertBudget(dynamic budget) {
    double original = 0;
    if (budget is num) original = budget.toDouble();
    else if (budget is String) original = double.tryParse(budget) ?? 0;

    final converted = original * userCurrencyRate;
    return "$userCurrencySymbol${converted.toStringAsFixed(2)}";
  }

  /// Fetch available trips (Itineraries)
  Future<void> fetchAvailableTrips() async {
    setState(() => loadingAvailable = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("Itineraries")
          .orderBy("createdAt", descending: true)
          .get();
      setState(() => availableTrips = snapshot.docs);
    } catch (e) {
      print("Error fetching available trips: $e");
    } finally {
      setState(() => loadingAvailable = false);
    }
  }

  /// Fetch user trips (active and completed)
  Future<void> fetchUserTrips() async {
    setState(() {
      loadingActive = true;
      loadingCompleted = true;
    });

    try {
      final baseQuery = FirebaseFirestore.instance
          .collection("UserTrips")
          .where("userId", isEqualTo: user!.uid);

      final snapshot = await baseQuery.get();
      final docs = snapshot.docs;

      setState(() {
        final now = DateTime.now();

        activeTrips = docs.where((doc) {
          final data = doc.data();
          final endDate = (data['endDate'] as Timestamp?)?.toDate();
          return endDate == null || endDate.isAfter(now);
        }).toList();

        completedTrips = docs.where((doc) {
          final data = doc.data();
          final endDate = (data['endDate'] as Timestamp?)?.toDate();
          return endDate != null && endDate.isBefore(now);
        }).toList();
      });
    } catch (e) {
      print("Error fetching user trips: $e");
    } finally {
      setState(() {
        loadingActive = false;
        loadingCompleted = false;
      });
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
          "Trips",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0C1D1B),
            fontSize: 20,
            letterSpacing: -0.3,
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
          // Tabs
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFCDEAE8))),
            ),
            child: Row(
              children: [
                _TabButton(
                  title: "Available Trips",
                  active: activeTabIndex == 0,
                  onTap: () => setState(() => activeTabIndex = 0),
                ),
                _TabButton(
                  title: "Active Trips",
                  active: activeTabIndex == 1,
                  onTap: () => setState(() => activeTabIndex = 1),
                ),
                _TabButton(
                  title: "Completed Trips",
                  active: activeTabIndex == 2,
                  onTap: () => setState(() => activeTabIndex = 2),
                ),
              ],
            ),
          ),

          // Trip List
          Expanded(
            child: IndexedStack(
              index: activeTabIndex,
              children: [
                // Available Trips
                loadingAvailable
                    ? const Center(child: CircularProgressIndicator())
                    : availableTrips.isEmpty
                        ? const Center(
                            child: Text(
                              "No trips available",
                              style: TextStyle(
                                color: Color(0xFF45A19B),
                                fontSize: 16,
                              ),
                            ),
                          )
                        : _buildAvailableTripList(availableTrips),

                // Active Trips
                loadingActive
                    ? const Center(child: CircularProgressIndicator())
                    : activeTrips.isEmpty
                        ? const Center(
                            child: Text(
                              "No active trips available",
                              style: TextStyle(
                                color: Color(0xFF45A19B),
                                fontSize: 16,
                              ),
                            ),
                          )
                        : _buildTripList(activeTrips, activeTabIndex: 1),

                // Completed Trips
                loadingCompleted
                    ? const Center(child: CircularProgressIndicator())
                    : completedTrips.isEmpty
                        ? const Center(
                            child: Text(
                              "No completed trips available",
                              style: TextStyle(
                                color: Color(0xFF45A19B),
                                fontSize: 16,
                              ),
                            ),
                          )
                        : _buildTripList(completedTrips, activeTabIndex: 2),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00A398),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTripScreen()),
          );
        },
        child: const Icon(Icons.add, color: Color(0xFFF8FCFC)),
      ),
    );
  }

  /// Available Trips List
  Widget _buildAvailableTripList(List<QueryDocumentSnapshot> trips) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final doc = trips[index];
        final createdAt = (doc["createdAt"] as Timestamp?)?.toDate() ?? DateTime.now();
        final title = doc["tripName"] ?? "No Title";
        final locations = doc["destinationName"] ?? "";
        final budget = doc.data().toString().contains("budget") ? doc["budget"] : 0;

        return TripCard(
          date: DateFormat('MMM dd, yyyy').format(createdAt),
          title: title,
          locations: locations,
          budgetStatus: "Cost: ${convertBudget(budget)}",
          budgetOk: true,
          imageUrl: "assets/images/About.jpg",
          buttonText: "Active",
          onActivePressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TripDetailScreen(itinerary: doc)),
            );
          },
        );
      },
    );
  }

  /// Active & Completed Trips List
  Widget _buildTripList(
    List<QueryDocumentSnapshot> trips, {
    required int activeTabIndex,
  }) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final doc = trips[index];
        final startDate = (doc["startDate"] as Timestamp?)?.toDate() ?? DateTime.now();
        final endDate = (doc["endDate"] as Timestamp?)?.toDate() ?? DateTime.now();
        final title = doc["tripName"] ?? "No Title";
        final locations = doc["destinationName"] ?? "";
        final budget = doc.data().toString().contains("budget") ? doc["budget"] : 0;

        String buttonText;
        if (activeTabIndex == 1) {
          buttonText = "Expenses"; // Active Trips
        } else if (activeTabIndex == 2) {
          buttonText = "Generate Report"; // Completed Trips
        } else {
          buttonText = "View";
        }

        return TripCard(
          date:
              "${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd').format(endDate)}",
          title: title,
          locations: locations,
          budgetStatus: "Cost: ${convertBudget(budget)}",
          budgetOk: true,
          imageUrl: "assets/images/About.jpg",
          buttonText: buttonText,
          onActivePressed: () {
            if (activeTabIndex == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddExpensesScreen(userTrips: doc),
                ),
              );
            } else if (activeTabIndex == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReportScreen(tripDoc: doc)),
              );
            }
          },
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? const Color(0xFF00A398) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: active ? const Color(0xFF0C1D1B) : const Color(0xFF45A19B),
            ),
          ),
        ),
      ),
    );
  }
}

class TripCard extends StatelessWidget {
  final String date;
  final String title;
  final String locations;
  final String budgetStatus;
  final bool budgetOk;
  final String imageUrl;
  final VoidCallback? onActivePressed;
  final String buttonText;

  const TripCard({
    super.key,
    required this.date,
    required this.title,
    required this.locations,
    required this.budgetStatus,
    required this.budgetOk,
    required this.imageUrl,
    this.onActivePressed,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF45A19B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0C1D1B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locations,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF45A19B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4F3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          budgetOk ? Icons.check : Icons.close,
                          color: const Color(0xFF0C1D1B),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          budgetStatus,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0C1D1B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: onActivePressed != null
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF00A398),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: onActivePressed,
                        label: Text(
                          buttonText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ],
    );
  }
}
