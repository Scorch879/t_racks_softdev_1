import 'package:flutter/material.dart';

// This function can be called from any file that imports it
void showCustomSnackBar(BuildContext context, String message, {bool isError = true}) {
  // Hide any existing snackbars
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  
  // Show the new one
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError 
          ? Theme.of(context).colorScheme.error 
          : Colors.green, // Or your app's success color
    ),
  );
}