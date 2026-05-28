import 'package:admin_dashboard_myfuture/themes/colors.dart';
import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {

Function()? onTap; 
    
MyButton({super.key, required this.onTap });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
      child: Container(
          padding: EdgeInsets.all(15),
          margin: EdgeInsets.symmetric(horizontal: 25),
          decoration: BoxDecoration(
              color: sideColor,
              borderRadius: BorderRadius.circular(8)
          ) ,
          child: Center(
              child: Text('Sign In',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
              ),),
          ),
      ),
    );
  }
}