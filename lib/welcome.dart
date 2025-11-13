import 'package:flutter/material.dart';
import 'login.dart'; 
import 'register.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFC),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Section
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 3 / 2,
                      child: Image.network(
                        "https://lh3.googleusercontent.com/aida-public/AB6AXuD3YAC5EPxSnMDsGRiMXL43aT1rzJBqFhfAUjrB26VDwfEkWiajoz8-EnMdje04cSk4ClvpXiQyKHzQgAZzsZTiOIPmBHJUhFlUUsiZxXrixoj-hwrMq4oE44YghQc5-H0EdIxO7AhxncqooZrzv8atmNfVTBV_D778IzV175jP6HswKZJl8r_GCpTQnmmqB2RIEjpHmDtufRrSKRQp0v_fxbcA91_AuIm4S1LAeIcJkwWbH7agypJ4eTcHtzjKcLOMgRF5YXnWFKc",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const Text(
                  "TripBudgeter",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF0C1D1B),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Plan your trips, save your budget",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF0C1D1B), fontSize: 16),
                ),
              ],
            ),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  _buildButton(
                    text: "Login",
                    background: const Color(0xFF00A398),
                    textColor: const Color(0xFFF8FCFC),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildButton(
                    text: "Sign Up",
                    background: const Color(0xFFE6F4F3),
                    textColor: const Color(0xFF0C1D1B),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildButton({
    required String text,
    required Color background,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
      ),
    );
  }
}
