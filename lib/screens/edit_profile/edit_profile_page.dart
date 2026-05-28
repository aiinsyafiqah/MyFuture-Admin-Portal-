import 'dart:io';

import 'package:admin_dashboard_myfuture/themes/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  User? user;
  String? photoUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    photoUrl = user?.photoURL;
    _loadFromUsersCollection();
  }

  Future<void> _loadFromUsersCollection() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['photoUrl'] != null) {
          setState(() => photoUrl = data['photoUrl'] as String?);
        }
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() => _loading = true);
    try {
      final uid = user!.uid;
      final ref = FirebaseStorage.instance.ref().child('admin_profiles').child('$uid.jpg');

      // Support web and mobile file upload
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        final f = File(picked.path);
        await ref.putFile(f);
      }

      final url = await ref.getDownloadURL();

      // Update FirebaseAuth profile
      await user!.updatePhotoURL(url);

      // Update in users collection if exists
      await FirebaseFirestore.instance.collection('users').doc(uid).set({'photoUrl': url}, SetOptions(merge: true));

      setState(() => photoUrl = url);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated')));
    } catch (e) {
      final err = e.toString();
      print('Upload failed: $err');

      String msg = 'Upload failed: $err';
      if (kIsWeb && err.toLowerCase().contains('cors')) {
        msg = 'Upload failed due to CORS. Please configure your Storage bucket CORS headers.';
      }

      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    final current = _currentPassCtrl.text.trim();
    final nw = _newPassCtrl.text.trim();

    setState(() => _loading = true);
    try {
      final cred = EmailAuthProvider.credential(email: user!.email!, password: current);
      await user!.reauthenticateWithCredential(cred);
      await user!.updatePassword(nw);

      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
      _currentPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'Error';
      if (e.code == 'wrong-password') msg = 'Current password is incorrect';
      if (e.code == 'weak-password') msg = 'New password is too weak';
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = user?.email ?? 'Unknown';
    final name = user?.displayName ?? 'Administrator';

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 20
      ),), 
      backgroundColor: Colors.transparent,),
      backgroundColor: const Color.fromARGB(255, 193, 203, 235),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Centered avatar and profile text
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                        child: photoUrl == null ? const Icon(Icons.person, size: 40) : null,
                      ),
                      Positioned(
                        right: -6,
                        bottom: -6,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt_rounded, color: Color.fromARGB(255, 100, 136, 241)),
                          onPressed: _loading ? null : _pickAndUploadImage,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Plain form (no Card)
            const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _currentPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter current password' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter new password';
                      if (v.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm New Password', border: OutlineInputBorder()),
                    validator: (v) => (v != _newPassCtrl.text) ? 'Passwords do not match' : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _changePassword,
                      child: _loading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Update Password'),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
