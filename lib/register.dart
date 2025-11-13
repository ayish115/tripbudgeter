import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tripbudgeter/User/onboarding.dart';
import 'package:tripbudgeter/login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female'];

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _signUp() async {
  final name = _nameController.text.trim();
  final email = _emailController.text.trim();
  final age = _ageController.text.trim();
  final gender = _selectedGender;
  final role = "User";
  final password = _passwordController.text.trim();
  final confirmPassword = _confirmPasswordController.text.trim();

  if (name.isEmpty ||
      email.isEmpty ||
      age.isEmpty ||
      gender == null ||
      password.isEmpty ||
      confirmPassword.isEmpty) {
    _showMessage("Please fill all fields");
    return;
  }

  if (password != confirmPassword) {
    _showMessage("Passwords do not match");
    return;
  }

  if (!_agreeToTerms) {
    _showMessage("You must agree to the terms");
    return;
  }

  setState(() => _isLoading = true);

  try {
    final userCred = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    const defaultRate = {
      "rate": 1,
    };

    await FirebaseFirestore.instance
        .collection("Users")
        .doc(userCred.user!.uid)
        .set({
      "fullName": name,
      "email": email,
      "age": int.tryParse(age) ?? 0,
      "gender": gender,
      "role": role,
      "currencyRate": defaultRate["rate"],
      "preferredCurrencyId": "",
      "currencyName": "US Dollar",
      "createdAt": DateTime.now(),
      "userId": userCred.user!.uid,
    });

    log("Sign Up Successful");
    _showMessage("Sign Up Successful! Welcome, $name");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => OnboardingPage()),
      (route) => false,
    );
  } catch (error) {
    _showMessage(
      error is FirebaseAuthException
          ? error.message ?? "Signup failed"
          : "Failed to save user data: $error",
    );
  } finally {
    setState(() => _isLoading = false);
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
                    _buildTextField("Full Name", _nameController),
                    _buildTextField("Email Address", _emailController),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            "Age",
                            _ageController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _buildGenderDropdown()),
                      ],
                    ),
                    _buildPasswordField(
                      "Password",
                      _passwordController,
                      obscure: _obscurePassword,
                      toggle: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    _buildPasswordField(
                      "Confirm Password",
                      _confirmPasswordController,
                      obscure: _obscureConfirmPassword,
                      toggle: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    _buildTermsCheckbox(),
                    const SizedBox(height: 20),
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
                        onPressed: _isLoading ? null : _signUp,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Sign Up",
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
            _buildLoginLink(),
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
            "Sign Up",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C1D1B),
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Create an account to get started!",
            style: TextStyle(fontSize: 15, color: Color(0xFF45A19B)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String placeholder, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(color: Color(0xFF45A19B)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      items: _genders
          .map((gender) => DropdownMenuItem<String>(
                value: gender,
                child: Text(gender, style: const TextStyle(color: Color(0xFF0C1D1B))),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedGender = value),
      decoration: InputDecoration(
        hintText: "Gender",
        hintStyle: const TextStyle(color: Color(0xFF45A19B)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE6F4F3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE6F4F3)),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String placeholder, TextEditingController controller,
      {required bool obscure, required VoidCallback toggle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(color: Color(0xFF45A19B)),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF45A19B)),
            onPressed: toggle,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
          activeColor: const Color(0xFF00A398),
        ),
        const Expanded(
          child: Text(
            "I agree to the Terms of Service and Privacy Policy",
            style: TextStyle(color: Color(0xFF0C1D1B), fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        },
        child: const Text(
          "Already have an account? Log In",
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
