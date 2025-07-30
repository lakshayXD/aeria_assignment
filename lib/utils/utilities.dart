import 'package:flutter/services.dart';

class Utilities{
  static bool isNullOrBlank(String? data) => data?.trim().isEmpty ?? true;

  ///method to close the app
  static void closeApp() {
    SystemNavigator.pop();
  }
}