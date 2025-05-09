import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

/// Helper class for handling permissions required by the app
class PermissionHelper {
  // Method channel to communicate with native code for notification permissions
  static const platform = MethodChannel('com.example.bank_transaction_tracker/notification_permission');

  /// Check and request all required permissions
  static Future<bool> checkAndRequestPermissions() async {
    final smsPermissions = await checkAndRequestSmsPermissions();
    final notificationPermissions = await checkAndRequestNotificationPermissions();
    
    return smsPermissions && notificationPermissions;
  }

  /// Check and request SMS permissions
  static Future<bool> checkAndRequestSmsPermissions() async {
    try {
      // Check SMS permissions
      final receiveStatus = await Permission.sms.status;
      
      if (receiveStatus.isGranted) {
        return true;
      }

      // Request permissions if not granted
      final result = await Permission.sms.request();
      return result.isGranted;
    } catch (e) {
      debugPrint('Error checking SMS permissions: $e');
      return false;
    }
  }

  /// Check and request notification access permissions
  static Future<bool> checkAndRequestNotificationPermissions() async {
    try {
      // Check notification access using platform channel
      final bool hasPermission = await platform.invokeMethod('isNotificationListenerEnabled');
      
      if (hasPermission) {
        return true;
      }

      // Open notification listener settings if not granted
      await platform.invokeMethod('openNotificationListenerSettings');
      
      // We can't programmatically check if user granted permission after settings screen
      // so we'll assume they didn't and return false
      return false;
    } catch (e) {
      debugPrint('Error checking notification permissions: $e');
      return false;
    }
  }

  /// Check if app has foreground service permission
  static Future<bool> hasForegroundServicePermission() async {
    if (await Permission.ignoreBatteryOptimizations.isGranted) {
      return true;
    }
    return false;
  }

  /// Request foreground service permission
  static Future<bool> requestForegroundServicePermission() async {
    if (await Permission.ignoreBatteryOptimizations.isGranted) {
      return true;
    }
    
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  /// Open app settings
  static Future<void> openAppSettings() async {
    try {
      await AppSettings.openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
    }
  }

  /// Open notification settings
  static Future<void> openNotificationSettings() async {
    try {
      await platform.invokeMethod('openNotificationListenerSettings');
    } catch (e) {
      debugPrint('Error opening notification settings: $e');
      // Fallback to app settings if specific notification settings can't be opened
      await openAppSettings();
    }
  }

  /// Show permission explanation dialog
  static Future<void> showPermissionExplanationDialog(
    BuildContext context,
    String title,
    String message,
    String buttonText,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// Show SMS permission rationale
  static Future<bool> showSmsPermissionRationale(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SMS Permission Required'),
        content: const Text(
          'This app needs to read your SMS messages to automatically detect '
          'and log bank transactions. We only process messages from bank '
          'senders and do not read your personal messages.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Deny'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  /// Show notification permission rationale
  static Future<bool> showNotificationPermissionRationale(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Access Required'),
        content: const Text(
          'This app needs access to your notifications to detect bank transaction '
          'notifications. We only process notifications from banking apps that '
          'you select in the settings.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Deny'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
}
