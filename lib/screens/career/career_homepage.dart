import 'package:admin_dashboard_myfuture/screens/career/manageCareer.dart';
import 'package:flutter/material.dart';
import 'package:admin_dashboard_myfuture/themes/colors.dart'; // Your theme
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'career_cheatsheet.dart'; // Import the Cheatsheet

class CareerHomepage extends StatelessWidget {
  const CareerHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 193, 203, 235), // Use your cream background
      appBar: AppBar(
        title: const Text("Career Management",
        style: TextStyle(
          fontWeight: FontWeight.bold
        ),),
        backgroundColor: const Color.fromARGB(255, 193, 203, 235),
      ),
      
      // THE "ADD" BUTTON
      // We call the function explicitly imported from manageCareer.dart
      floatingActionButton: FloatingActionButton.extended(
        label: const Text("Add New Career"),
        backgroundColor: sidebarBlack,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        onPressed: () {
          // We call the public function 'showCareerDialog' from manageCareer.dart
          showCareerDialog(context, null); 
        },
      ),

      // THE BODY: Combines both widgets
      body: const SingleChildScrollView(
        child: Column(
          children: [
            // 1. The Cheatsheet (Top)
            CareerTypeCheatsheet(),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(thickness: 2,
              color: sideColor,),
            ),

            // 2. The List (Bottom)
            CareerManage(), 
          ],
        ),
      ),
    );
  }
}