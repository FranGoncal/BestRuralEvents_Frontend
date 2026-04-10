import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class ToastHelper {
  static void showSuccess(String message) {
    Fluttertoast.showToast(
      msg: "✅ $message",
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  static void showError(String message) {
    Fluttertoast.showToast(
      msg: "❌ $message",
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  static void showWarning(String message) {
    Fluttertoast.showToast(
      msg: "⚠️ $message",
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );
  }
}