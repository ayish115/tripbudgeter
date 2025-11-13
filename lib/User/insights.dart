import 'package:flutter/material.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xfff8fcfc);
    const textPrimary = Color(0xff0c1d1b);
    const textSecondary = Color(0xff45a19b);
    const buttonColor = Color(0xff00a398);
    const buttonTextColor = Color(0xfff8fcfc);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Padding(
          padding: EdgeInsets.only(left: 16), // Left padding for title
          child: Text(
            "Insights & Reports",
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
            padding: const EdgeInsets.only(right: 16), // Right padding for icon
            child: IconButton(
              icon: const Icon(
                Icons.help_outline,
                color: Color(0xFF0C1D1B),
                size: 28,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Budget overview + image side by side
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Budget overview box
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: backgroundColor,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Trip',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Budget Overview',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Remaining: \$1,250',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xffe6f4f3),
                              foregroundColor: textPrimary,
                              minimumSize: const Size(84, 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              // TODO: Navigate to Insights details
                            },
                            icon: const Icon(Icons.arrow_forward_ios, size: 18),
                            label: const Text(
                              'Go to Insights',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Image container
                  Expanded(
                    flex: 1,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          "https://lh3.googleusercontent.com/aida-public/AB6AXuAUjqMjEDyXvlUZuw_bOy40HbdCtqJL0ckYugsFpuzHcSJNP308-XJDYcbEfDOJPrNRBso83i-_yk0jmsRaP4G6sFwhdnhzQCdFaA7XVs4NZlzWQwiQHyZGWhmYmVQZqMlH7qxClbGvlW4sFiuhnzE7UwAX1ESnUpGGA6cp4iSJQ9YOf9zAFag4ITLJVA6oPf0wD2snhfRMtocdhZpkebpaOR3zqWva9HFHw6XrlRex8EiBjZmCf71XSCKuPqaWd0H0TA2QiLsYiuA",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Notifications & Alerts row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Notifications & Alerts',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: textPrimary,
                    ),
                    onPressed: () {
                      // TODO: Navigate to Notifications & Alerts
                    },
                  ),
                ],
              ),
            ),

            // Reports section title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text(
                'Reports',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.4,
                ),
              ),
            ),

            // Generate report button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: buttonTextColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    // TODO: Generate report logic
                  },
                  child: const Text(
                    'Generate Report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Past Reports row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Past Reports',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: textPrimary,
                    ),
                    onPressed: () {
                      // TODO: Navigate to Past Reports
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20), // spacing before bottom
          ],
        ),
      ),
    );
  }
}
