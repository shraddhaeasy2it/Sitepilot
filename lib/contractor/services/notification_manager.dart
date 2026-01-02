// notification_manager.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  
  NotificationManager._internal();
  
  void showInAppNotification({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onTap,
  }) {
    // Show SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("💬 $title: $message"),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        action: onTap != null ? SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: onTap,
        ) : null,
      )
    );
    
    // Show Toast
    Fluttertoast.showToast(
      msg: "💬 $title: $message",
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      fontSize: 14.0,
      gravity: ToastGravity.TOP,
      toastLength: Toast.LENGTH_LONG,
    );
  }
  
  void showMessageNotification(String senderName, String message, {VoidCallback? onTap}) {
    // This can be called from anywhere in the app
    // It finds the current context using a GlobalKey
    // For simplicity, we'll use Fluttertoast which doesn't need context
    Fluttertoast.showToast(
      msg: "💬 $senderName: $message",
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      fontSize: 14.0,
      gravity: ToastGravity.TOP,
      toastLength: Toast.LENGTH_LONG,
    );
  }
}