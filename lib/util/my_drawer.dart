import 'package:admin_dashboard_myfuture/screens/login/login_page.dart';
import 'package:admin_dashboard_myfuture/themes/colors.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- 1. WAJIB IMPORT NI
import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({
    super.key,
    required this.selectedIndex,
    required this.onMenuItemTap,
  });

  final int selectedIndex;
  final Function(int) onMenuItemTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgCream,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/logo/myfuture_logo.png'),
          const SizedBox(height: 50),

          _buildMenuItem(0, "Dashboard", Icons.grid_view),
          _buildMenuItem(1, "Careers & Edu", Icons.work),
          _buildMenuItem(2, "Universities", Icons.school),
          _buildMenuItem(3, "Scholarships", Icons.attach_money),
          _buildMenuItem(4, "Assessments", Icons.assessment),
          _buildMenuItem(5, "Report", Icons.analytics),

          const Spacer(),
          _buildLogoutItem(context),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, String title, IconData icon) {
    final bool isActive = selectedIndex == index;
    return InkWell(
      onTap: () => onMenuItemTap(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            if (isActive)
              Container(width: 4, height: 20, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: sideColor, borderRadius: BorderRadius.circular(2))),
            Icon(icon, color: isActive ? sideColor : textDark, size: 20),
            const SizedBox(width: 15),
            Text(title, style: TextStyle(color: isActive ? sideColor : textDark, fontSize: 14, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return InkWell(
      onTap: () => _showLogoutConfirmation(context),
      child: Row(
        children: const [
          SizedBox(width: 14),
          Icon(Icons.logout_rounded, color: textDark, size: 20),
          SizedBox(width: 15),
          Text("Log out", style: TextStyle(color: textDark, fontSize: 14)),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to quit?"),
          actions: [
            // Butang STAY
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: const Text("Stay", style: TextStyle(color: Colors.grey)),
            ),
            
            // Butang YES (LOGOUT) - GANTI KOD INI
            TextButton(
              onPressed: () async {
                // 1. Tutup Dialog dulu
                Navigator.of(context).pop(); 
                
                // 2. Sign Out dari Firebase
                await FirebaseAuth.instance.signOut();

                // 3. PAKSA NAVIGATE BALIK KE ROOT ('/')
                // Ini akan buang page '/home' atau Dashboard dari skrin
                // dan panggil semula AuthGate di main.dart
                if (context.mounted) {
                   Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
              child: const Text("Yes, Log out", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}