import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tripbudgeter/Admin/contactquery.dart';
import 'package:tripbudgeter/Admin/dashboard.dart';
import 'package:tripbudgeter/Admin/managecurrency.dart';
import 'package:tripbudgeter/Admin/managedestinations.dart';
import 'package:tripbudgeter/Admin/manageitinerary.dart';
import 'package:tripbudgeter/Admin/manageuser.dart';
import 'package:tripbudgeter/Admin/updateabout.dart';
import 'package:tripbudgeter/welcome.dart';

class AdminMenuDrawer extends StatelessWidget {
  const AdminMenuDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00A398), Color(0xFF008B82)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: Color(0xFF00A398),
                    size: 30,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Admin Menu',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTileTheme(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  iconColor: const Color(0xFF00A398),
                  textColor: Colors.black87,
                  child: Column(
                    children: [
                      _menuItem(
                        context,
                        Icons.dashboard,
                        'Admin Dashboard',
                        'Overview & quick links',
                        () => _navigate(context, const AdminDashboard()),
                      ),
                      _menuItem(
                        context,
                        Icons.location_on,
                        'Manage Destinations',
                        'Add, edit, delete locations',
                        () => _navigate(context, const ManageDestinationsPage()),
                      ),
                      _menuItem(
                        context,
                        Icons.route,
                        'Manage Itineraries',
                        'View and add trip itineraries',
                        () => _navigate(context, const ManageItineraryScreen()),
                      ),
                      _menuItem(
                        context,
                        Icons.currency_exchange,
                        'Manage Currency',
                        'Exchange rates',
                        () => _navigate(context, const ManageCurrenciesScreen()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF8FCFC),
                foregroundColor: const Color.fromARGB(255, 255, 91, 91),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                "Logout",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onPressed: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, size: 26),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      hoverColor: Colors.teal.withOpacity(0.1),
    );
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
