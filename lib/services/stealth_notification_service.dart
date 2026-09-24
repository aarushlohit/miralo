import 'package:flutter/material.dart';

/// Service for showing stealth notifications that disguise incoming private chats.
/// Never exposes the private sender name, username, or message text.
/// Uses the stealth notification message: "Miralo AI spawns !!!"
class StealthNotificationService {
  StealthNotificationService._();

  static const String stealthTitle = 'Miralo AI';
  static const String stealthBody = 'Miralo AI spawns !!!';

  /// Display a stealth notification in-app when a private message arrives
  /// and the user is not actively inside that specific chat.
  static void showStealthInAppNotification(BuildContext context, {VoidCallback? onTap}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF0A84FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    stealthTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    stealthBody,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: onTap != null
            ? SnackBarAction(
                label: 'VIEW',
                textColor: const Color(0xFF0A84FF),
                onPressed: onTap,
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
