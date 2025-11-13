import 'package:flutter/material.dart';
import 'package:tripbudgeter/Admin/drawer.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FCFC),
        title: const Text('Admin Dashboard'),
      ),
      drawer: const AdminMenuDrawer(), // Reusable drawer
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome text
              const Text(
                "Welcome, Alex! 👋",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C1D1B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Here’s what’s happening today in your dashboard.",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF45A19B),
                ),
              ),

              const SizedBox(height: 20),

              // Dashboard grid
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _dashboardItems.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemBuilder: (context, index) {
                      final item = _dashboardItems[index];
                      return _dashboardCard(
                        icon: item['icon'] as IconData,
                        title: item['title'] as String,
                        subtitle: item['subtitle'] as String,
                        onTap: () {
                          // Handle navigation
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _dashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCDEAE8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF0C1D1B), size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C1D1B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF45A19B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final List<Map<String, dynamic>> _dashboardItems = [
  {
    "icon": Icons.flight,
    "title": "Manage Trips",
    "subtitle": "Add, edit, or delete trips",
  },
  {
    "icon": Icons.location_on,
    "title": "Manage Destinations",
    "subtitle": "Manage locations for trips",
  },
  {
    "icon": Icons.attach_money,
    "title": "Manage Currencies",
    "subtitle": "Update currency info",
  },
  {
    "icon": Icons.group,
    "title": "User Management",
    "subtitle": "View and manage user accounts",
  },
  {
    "icon": Icons.bar_chart,
    "title": "Reports",
    "subtitle": "Generate and view reports",
  },
  {
    "icon": Icons.notifications,
    "title": "Notifications",
    "subtitle": "Manage global alerts",
  },
];
