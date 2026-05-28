import 'package:admin_dashboard_myfuture/themes/colors.dart';
import 'package:flutter/material.dart';

class MyTile extends StatelessWidget {
  const MyTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
            padding: const EdgeInsets.all(8.0),
              child: Container(
                color: secondaryWritingColor,
                height: 80,
                      ),
          );
  }
}