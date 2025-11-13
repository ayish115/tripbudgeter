import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FCFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C1D1B)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "About Us",
          style: TextStyle(
            color: Color(0xFF0C1D1B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Name
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  "TripBudgeter",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C1D1B),
                  ),
                ),
              ),

              // Description
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  "TripBudgeter is your ultimate travel companion, designed to simplify your trip planning and expense management. Whether you're embarking on a solo adventure or a group expedition, our app empowers you to create and manage budgets effortlessly. Track your spending in real-time, collaborate with fellow travelers, and gain valuable insights into your travel expenses. With TripBudgeter, you can focus on enjoying your journey while staying in control of your finances.",
                  style: TextStyle(fontSize: 16, color: Color(0xFF0C1D1B)),
                ),
              ),

              // Key Features
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  "Key Features",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C1D1B),
                  ),
                ),
              ),

              const FeatureItem(
                icon: Icons.people,
                title: "Collaborative Budgeting",
                subtitle: "Collaborate with friends and family on shared trip budgets.",
              ),
              const FeatureItem(
                icon: Icons.currency_exchange,
                title: "Multi-Currency Support",
                subtitle: "Manage expenses in multiple currencies with real-time exchange rates.",
              ),
              const FeatureItem(
                icon: Icons.bar_chart,
                title: "Expense Reporting",
                subtitle: "Generate detailed reports to analyze your spending patterns.",
              ),

              // Contact Us
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  "Contact Us",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C1D1B),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: const [
                    CircleAvatar(
                      backgroundColor: Color(0xFFE6F4F3),
                      child: Icon(Icons.email, color: Color(0xFF0C1D1B)),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "support@tripbudgeter.com",
                        style: TextStyle(fontSize: 16, color: Color(0xFF0C1D1B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const FeatureItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE6F4F3),
            child: Icon(icon, color: const Color(0xFF0C1D1B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0C1D1B),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF45A19B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
