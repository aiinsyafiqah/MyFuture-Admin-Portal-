import 'package:admin_dashboard_myfuture/themes/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adapt grid count based on width
        int crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.8, // Adjust shape of cards
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _buildStatCard(cardYellow, "Patients", "14 pers", Icons.bar_chart),
            _buildStatCard(cardPink, "Visits", "24 min", Icons.show_chart),
            _buildStatCard(cardGreen, "Conditions", "Stable", Icons.shield_outlined),
            _buildStatCard(cardBlue, "Sessions", "03:45 h", Icons.videocam_outlined),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(Color color, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Icon(icon, color: Colors.black45),
            ],
          ),
          
          // You can add charts here later
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
          
          Row(
            children: [
               Container(width: 5, height: 25, color: Colors.black12, margin: EdgeInsets.only(right: 5)),
               Container(width: 5, height: 15, color: Colors.black12, margin: EdgeInsets.only(right: 5)),
               Container(width: 5, height: 35, color: Colors.black26, margin: EdgeInsets.only(right: 5)),
            ],
          )
        ],
      ),
    );
  }
}