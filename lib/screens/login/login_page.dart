import 'package:admin_dashboard_myfuture/features/my_button.dart';
import 'package:admin_dashboard_myfuture/features/textfield.dart';
import 'package:admin_dashboard_myfuture/themes/colors.dart';
import 'package:admin_dashboard_myfuture/util/main_layout.dart'; // <--- WAJIB IMPORT MAIN LAYOUT
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
   LoginPage({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> signUserIn(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Sign In
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      // 2. Check Role
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      navigator.pop(); // Tutup loading circle

      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data();
        
        // 3. KALAU ADMIN -> MASUK MAIN LAYOUT
        if (data != null && data['role'] == 'admin') {
          navigator.pushReplacement(
            MaterialPageRoute(builder: (context) => const MainLayout()), 
          );
          return; 
        }
      }

      // 4. KALAU BUKAN ADMIN
      await FirebaseAuth.instance.signOut(); // Tendang keluar
      messenger.showSnackBar(
        const SnackBar(content: Text("Access Denied: Admins only!"), backgroundColor: Colors.red),
      );

    } on FirebaseAuthException catch (e) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(e.message ?? "Login Failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (Kod UI build awak kekal sama macam asal, tak perlu ubah) ...
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 77, 109, 206),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
             begin: Alignment.topLeft,
             end: AlignmentGeometry.bottomRight,
             colors: [Colors.white,sideColor]
          )
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 25.0),
                  padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 25.0),
                  decoration: BoxDecoration(
                      color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10,),
                      Image.asset('assets/logo/myfuture_logo.png', width: 400, height: 250,),
                      const SizedBox(height: 25,),
                      Text('ADMIN PORTAL', style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.bold,),),
                      const SizedBox(height: 25,),
                      MyTextField(controller: emailController, hintText: 'Email', obscureText: false,),
                      const SizedBox(height: 25,),      
                      MyTextField(controller: passwordController, hintText: 'Password', obscureText: true,),
                      const SizedBox(height: 25,),
                      MyButton(onTap: (){ signUserIn(context); }),
                      const SizedBox(height: 25,),
                      Text('', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}