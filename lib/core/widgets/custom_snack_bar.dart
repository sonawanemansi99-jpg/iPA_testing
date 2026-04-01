import 'package:flutter/material.dart';

class CustomSnackBar {
  // Theme colors from your app
  static const Color saffron = Color(0xFFFF6700);
  static const Color dangerRed = Color(0xFFCC2200);
  static const Color navyBlue = Color(0xFF002868);

  /// The core builder method
  static void show({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    if (!context.mounted) return;
    // 1. Instantly hide any currently showing snackbar so they don't queue up
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // 2. Show the new custom snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            // Expanded prevents RenderFlex overflow if the message is too long!
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16), // Adds floating padding around the edges
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── CONVENIENCE METHODS ───

  /// Call this for success messages (Uses Saffron theme)
  static void showSuccess(BuildContext context, String message) {
    show(
      context: context,
      message: message,
      backgroundColor: saffron,
      icon: Icons.check_circle,
    );
  }

  /// Call this for errors or catch blocks (Uses Red theme)
  static void showError(BuildContext context, String message) {
    show(
      context: context,
      message: message,
      backgroundColor: dangerRed,
      icon: Icons.error_outline,
    );
  }

  /// Call this for general info (Uses Navy Blue theme)
  static void showInfo(BuildContext context, String message) {
    show(
      context: context,
      message: message,
      backgroundColor: navyBlue,
      icon: Icons.info_outline,
    );
  }
}