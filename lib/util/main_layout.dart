import 'package:admin_dashboard_myfuture/screens/admin_report/report.dart';
import 'package:admin_dashboard_myfuture/screens/assessment/assessment_page.dart';
import 'package:admin_dashboard_myfuture/screens/career/career_homepage.dart';

import 'package:admin_dashboard_myfuture/screens/homepage/homepage.dart';
import 'package:admin_dashboard_myfuture/screens/scholarships/scholarships_dashboard.dart';
import 'package:admin_dashboard_myfuture/screens/university/university_page.dart';
import 'package:admin_dashboard_myfuture/util/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:admin_dashboard_myfuture/themes/colors.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // 1. Variable to track which page is active
  int _selectedIndex = 0;

  // 2. List of all your content widgets
  final List<Widget> _pages = [
    const AdminHomepage(),      // Index 0
    const CareerHomepage(),          // Index 1
    const UniversityPage(),          // Index 2
    const ScholarshipPage(),
    const AssessmentPage(),  // Index 4 (Added your new page)
    const AdminReportPage(),
  ];

  // 3. Function to change the page
  void _onMenuSelect(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream, // Your background color
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------
          // LEFT SIDE: The Static Sidebar
          // ------------------------------------------------
          SizedBox(
            width: 250,
            // We pass the function & current index to the sidebar
            child: MyDrawer(
              selectedIndex: _selectedIndex,
              onMenuItemTap: _onMenuSelect, 
            ),
          ),

          // ------------------------------------------------
          // RIGHT SIDE: The Changing Content
          // ------------------------------------------------
          Expanded(
            // IndexedStack keeps the state of pages (doesn't reload them when switching)
            // If you want them to reload every time, just use: child: _pages[_selectedIndex]
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }
}