import 'package:admin_dashboard_myfuture/themes/colors.dart';
import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final controller;
  final String hintText;
  final bool obscureText;


  const MyTextField({super.key,
  required this.controller,
  required this.hintText,
  required this.obscureText
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: TextField(
                  //control what user edit in the textfield
                  controller: controller,
                  obscureText: obscureText,

                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(15)
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white)
                    ),
                    fillColor: Colors.grey.shade100,
                    filled: true,
                    hintText: hintText,

                  ),
                ),
              );
  }
}