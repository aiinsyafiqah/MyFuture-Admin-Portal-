import 'package:flutter/material.dart';

class CareerTypeCheatsheet extends StatelessWidget {
  const CareerTypeCheatsheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Career Types Cheatsheet (Holland Code)",
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 10),
            // Your cheatsheet content goes here
            _buildCheatRow("R", "Realistic", "Doers (Hands-on, tools)"),
            _buildCheatRow("I", "Investigative", "Thinkers (Science, logic)"),
            _buildCheatRow("A", "Artistic", "Creators (Design, writing)"),
            _buildCheatRow("S", "Social", "Helpers (Teaching, nursing)"),
            _buildCheatRow("E", "Enterprising", "Persuaders (Business, sales)"),
            _buildCheatRow("C", "Conventional", "Organizers (Data, numbers)"),
          ],
        ),
      ),
    );
  }

  // A simple helper method to keep the build method clean
  Widget _buildCheatRow(String code, String name, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$code: ",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "- $desc",
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}