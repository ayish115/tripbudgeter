import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tripbudgeter/Admin/dashboard.dart';
import 'package:tripbudgeter/User/mainlayout.dart';
import 'package:tripbudgeter/register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

 Future<void> _login() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    _showMessage("Please enter email and password");
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Sign in with Firebase Auth
    final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Check if user exists in Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userCred.user!.uid)
        .get();

    if (!userDoc.exists) {
      _showMessage("User data not found in database");
      await FirebaseAuth.instance.signOut();
      setState(() => _isLoading = false);
      return;
    }

    // Get role
    final role = userDoc.data()?['role'] ?? 'User';

    setState(() => _isLoading = false);

    _showMessage("Login Successful! Welcome");

    // Navigate based on role
    if (role == "Admin") {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => AdminDashboard()),
        (Route<dynamic> route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => MainLayout()),
        (Route<dynamic> route) => false,
      );
    }
  } on FirebaseAuthException catch (e) {
    setState(() => _isLoading = false);
    if (e.code == 'user-not-found') {
      _showMessage("User not found. Please register.");
    } else if (e.code == 'wrong-password') {
      _showMessage("Incorrect password. Try again.");
    } else {
      _showMessage(e.message ?? "Login failed");
    }
  } catch (e) {
    setState(() => _isLoading = false);
    _showMessage("An error occurred: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    _buildTitle(),
                    const SizedBox(height: 30),
                    _buildTextField("Email or Username", _emailController),
                    _buildPasswordField(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Color(0xFF45A19B),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A398),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Log In",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildSignUpLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF0C1D1B)),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          const Text(
            "TripBudgeter",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C1D1B),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF0C1D1B)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Center(
      child: Column(
        children: const [
          Text(
            "Login",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C1D1B),
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Welcome back! Please log in to continue.",
            style: TextStyle(fontSize: 15, color: Color(0xFF45A19B)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String placeholder, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(color: Color(0xFF45A19B)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE6F4F3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE6F4F3)),
          ),
        ),
        style: const TextStyle(color: Color(0xFF0C1D1B)),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          hintText: "Password",
          hintStyle: const TextStyle(color: Color(0xFF45A19B)),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF45A19B),
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE6F4F3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE6F4F3)),
          ),
        ),
        style: const TextStyle(color: Color(0xFF0C1D1B)),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          );
        },
        child: const Text(
          "Don't have an account? Sign Up",
          style: TextStyle(
            color: Color(0xFF45A19B),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
