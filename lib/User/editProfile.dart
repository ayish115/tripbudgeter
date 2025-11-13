import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color bg = const Color(0xFFF8FCFC);
  final Color cardBgColor = const Color(0xFFe6f4f3);

  late TextEditingController _nameController;
  late TextEditingController _photoController;

  File? _selectedImageFile;        // Mobile selected image
  Uint8List? _selectedImageBytes;  // Web selected image
  String? savedImagePath;          // Mobile saved path
  String? photoBase64;             // Web Base64 string
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _photoController = TextEditingController();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userEmail = user.email ?? '';
      _loadUserData(user.uid);
    }
  }

  Future<void> _loadUserData(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        _nameController.text = data['fullName'] ?? '';
        _photoController.text = data['photoUrl'] ?? '';
        savedImagePath = data['localPhotoPath'];
        photoBase64 = data['photoBase64'];
      }
      setState(() {});
    }
  }

  Future<void> _pickProfileImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: kIsWeb,
    );

    if (result != null) {
      if (kIsWeb) {
        _selectedImageBytes = result.files.single.bytes;
      } else {
        if (result.files.single.path != null) {
          _selectedImageFile = File(result.files.single.path!);
        }
      }
      setState(() {});
    }
  }

  Future<String?> _saveImageLocally() async {
    if (kIsWeb) return null;

    if (_selectedImageFile == null) return savedImagePath;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(_selectedImageFile!.path);
      final localFile = await _selectedImageFile!.copy('${dir.path}/$fileName');
      return localFile.path;
    } catch (e) {
      print('Error saving image locally: $e');
      return savedImagePath;
    }
  }

Future<void> _saveProfile() async {
  if (!_formKey.currentState!.validate()) return;

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  if (mounted) Navigator.pop(context); // Navigate back immediately

  try {
    // Prepare variables
    String? localPath = await _saveImageLocally();
    String? finalBase64 = photoBase64;
    String? finalPhotoUrl = _photoController.text.isNotEmpty ? _photoController.text : null;

    if (kIsWeb) {
      if (_selectedImageBytes != null) {
        // Web: store Base64 only, ignore file path
        finalBase64 = base64Encode(_selectedImageBytes!);
        localPath = null;
        finalPhotoUrl = null;
      }
    } else {
      if (_selectedImageFile != null) {
        // Mobile: store local path only, ignore Base64
        finalBase64 = null;
        finalPhotoUrl = null;
      }
    }

    // Update Firestore
    await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
      'fullName': _nameController.text.trim(),
      'localPhotoPath': localPath,
      'photoBase64': finalBase64,
      'photoUrl': finalPhotoUrl,
    }, SetOptions(merge: true));

    // Update FirebaseAuth profile name
    try {
      await user.updateDisplayName(_nameController.text.trim());
    } catch (e) {
      debugPrint('Error updating display name: $e');
    }
  } catch (e) {
    debugPrint('Error saving profile: $e');
  }
}

  @override
  void dispose() {
    _nameController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarImage;

    if (kIsWeb) {
      if (_selectedImageBytes != null) {
        avatarImage = MemoryImage(_selectedImageBytes!);
      } else if (photoBase64 != null) {
        avatarImage = MemoryImage(base64Decode(photoBase64!));
      }
    } else {
      if (_selectedImageFile != null) {
        avatarImage = FileImage(_selectedImageFile!);
      } else if (savedImagePath != null) {
        avatarImage = FileImage(File(savedImagePath!));
      } else if (_photoController.text.isNotEmpty) {
        avatarImage = AssetImage(_photoController.text);
      }
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0C1D1B),
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: cardBgColor,
                    backgroundImage: avatarImage,
                    child: avatarImage == null && _nameController.text.isNotEmpty
                        ? Text(
                            _nameController.text[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(userEmail, style: const TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    filled: true,
                    fillColor: cardBgColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Name cannot be empty' : null,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _photoController,
                      decoration: InputDecoration(
                        labelText: 'Profile Photo',
                        hintText: _selectedImageFile != null || _selectedImageBytes != null
                            ? 'Photo selected'
                            : savedImagePath != null || photoBase64 != null
                                ? 'Current photo selected'
                                : 'Select a photo (optional)',
                        filled: true,
                        fillColor: cardBgColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: const Icon(Icons.photo_camera),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF45A19B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 