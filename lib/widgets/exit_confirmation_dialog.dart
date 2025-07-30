import 'package:aeria_assignment/utils/constants.dart';
import 'package:aeria_assignment/utils/utilities.dart';
import 'package:flutter/material.dart';

class ExitConfirmationDialog extends StatelessWidget {
  const ExitConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: const Text(
        exitAppText,
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
      ),
      content: const Text(
        exitConfirmationText,
        style: TextStyle(color: Colors.black87),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: primaryBlue),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Utilities.closeApp(),
          style: TextButton.styleFrom(foregroundColor: primaryRed),
          child: const Text('Exit'),
        ),
      ],
    );
  }
}
