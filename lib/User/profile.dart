import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tripbudgeter/User/contact.dart';
import 'package:tripbudgeter/User/editProfile.dart';
import 'package:tripbudgeter/welcome.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final textColorPrimary = const Color(0xFF0c1d1b);
  final accentColor = const Color(0xFF45a19b);
  final bgColor = const Color(0xFFf8fcfc);
  final cardBgColor = const Color(0xFFe6f4f3);

  String userName = '';
  String userEmail = '';
  String userGender = 'Not Specified';
  String userAge = 'Not Specified';
  String userCurrency = 'Not Specified';
  String? userPhotoUrl;
  String? preferredCurrencyId;

  String? photoBase64;
  String? localPhotoPath;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    setState(() {
      userName = (data['fullName'] ?? user.displayName) ?? 'No Name';
      userEmail = data['email'] ?? user.email ?? 'No Email';
      userGender = data['gender'] ?? 'Not Specified';
      userAge = (data['age']?.toString()) ?? 'Not Specified';
      userCurrency = (data['currencyName']?.toString()) ?? 'Not Specified';
      preferredCurrencyId = data['preferredCurrencyId'];

      userPhotoUrl = data['photoUrl'];
      photoBase64 = data['photoBase64'];
      localPhotoPath = data['localPhotoPath'];
    });
  }

  ImageProvider? _getProfileImage() {
    if (kIsWeb) {
      if (photoBase64?.isNotEmpty ?? false) {
        try {
          return MemoryImage(base64Decode(photoBase64!));
        } catch (e) {
          debugPrint('Error decoding base64: $e');
        }
      }
      if (userPhotoUrl?.startsWith('http') ?? false) {
        return NetworkImage(userPhotoUrl!);
      }
    } else {
      if (localPhotoPath != null && File(localPhotoPath!).existsSync()) {
        return FileImage(File(localPhotoPath!));
      }
      if (photoBase64?.isNotEmpty ?? false) {
        try {
          return MemoryImage(base64Decode(photoBase64!));
        } catch (e) {
          debugPrint('Error decoding base64: $e');
        }
      }
      if (userPhotoUrl?.startsWith('assets/') ?? false) {
        return AssetImage(userPhotoUrl!);
      }
    }
    return null;
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
  }

  Future<void> _editAge() async {
    final controller = TextEditingController(text: userAge);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Age'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter Age'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );

    if (result?.isNotEmpty ?? false) {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('Users').doc(user!.uid).update({'age': int.tryParse(result!)});
      setState(() => userAge = result);
    }
  }

  Future<void> _editGender() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Gender'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(value: 'Male', groupValue: userGender, onChanged: (val) => Navigator.pop(context, val), title: const Text('Male')),
            RadioListTile<String>(value: 'Female', groupValue: userGender, onChanged: (val) => Navigator.pop(context, val), title: const Text('Female')),
          ],
        ),
      ),
    );

    if (result != null) {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('Users').doc(user!.uid).update({'gender': result});
      setState(() => userGender = result);
    }
  }

  Future<void> _editCurrency() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('currencies').orderBy('name').get();
      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No currencies available')));
        return;
      }

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Select Currency'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: snapshot.docs.length,
              itemBuilder: (_, index) {
                final doc = snapshot.docs[index];
                final data = doc.data();
                return ListTile(
                  title: Text(data['name'] ?? 'Unknown'),
                  subtitle: Text("\$${data['rate'] ?? '0'}"),
                  onTap: () => Navigator.pop(context, {'id': doc.id, 'name': data['name'], 'rate': data['rate']}),
                );
              },
            ),
          ),
        ),
      );

      if (result != null) {
        final user = FirebaseAuth.instance.currentUser;
        await FirebaseFirestore.instance.collection('Users').doc(user!.uid).update({
          'currencyRate': result['rate'],
          'preferredCurrencyId': result['id'],
          'currencyName': result['name'],
        });
        setState(() {
          userCurrency = result['name'];
          preferredCurrencyId = result['id'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching currencies: $e')));
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
       body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Avatar & Info
                    CircleAvatar(
                      radius: 64,
                      backgroundColor: cardBgColor,
                      backgroundImage: _getProfileImage(),
                      child: _getProfileImage() == null
                          ? Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : '',
                              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: textColorPrimary),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(userName, style: TextStyle(color: textColorPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(userEmail, style: TextStyle(color: accentColor, fontSize: 16)),
                    const SizedBox(height: 16),

                    // Edit Profile Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cardBgColor,
                            foregroundColor: textColorPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                            );
                            _fetchUserData(); 
                          },
                          child: const Text("Edit Profile"),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Details
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Details', style: TextStyle(color: textColorPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildEditableDetailCard(Icons.person_outline, "Gender", userGender, _editGender),
                    const SizedBox(height: 10),
                    _buildEditableDetailCard(Icons.cake_outlined, "Age", userAge, _editAge),
                    const SizedBox(height: 10),
                    _buildEditableDetailCard(Icons.attach_money, "Preferred Currency", userCurrency, _editCurrency),
                  ],
                ),
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _logout,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text("Logout", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableDetailCard(IconData icon, String title, String value, VoidCallback onEdit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: cardBgColor, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: textColorPrimary, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: textColorPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(value, style: TextStyle(color: accentColor, fontSize: 14)),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.edit, color: Colors.grey), onPressed: onEdit)
          ],
        ),
      ),
    );
  }
}
