import 'package:admin_dashboard_myfuture/screens/homepage/homepage.dart';
import 'package:admin_dashboard_myfuture/screens/login/login_page.dart';
import 'package:admin_dashboard_myfuture/util/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Dengar status login dari Firebase (Live)
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        // 1. Kalau tengah loading (tengah check dengan server)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Kalau User WUJUD (Dah Login)
        if (snapshot.hasData) {
          return  MainLayout();
        }

        // 3. Kalau User TIADA (Belum Login / Dah Logout)
        else {
          return LoginPage();
        }
      },
    );
  }
}