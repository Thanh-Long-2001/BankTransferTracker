import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';

import '../models/transaction.dart';
import 'transaction_parser.dart';

class NotificationService {
  // Platform channel for native communication
  static const platform = MethodChannel(
      'com.example.bank_transaction_tracker/notification_permission');

  final TransactionParser _parser = TransactionParser();
  final Function(Transaction) onTransactionDetected;
  final List<String> monitoredPackages;

  // Stream controller for notifications
  final _notificationController =
      StreamController<NotificationEvent>.broadcast();
  Stream<NotificationEvent> get notificationStream =>
      _notificationController.stream;

  // Stream subscription for notification events
  StreamSubscription<NotificationEvent>? _subscription;

  NotificationService({
    required this.onTransactionDetected,
    required this.monitoredPackages,
  });

  // Initialize and start the notification service
  Future<bool> initialize() async {
    try {
      // Request permission
      bool hasPermission = await requestNotificationPermission();
      if (!hasPermission) {
        return false;
      }
      // Initialize and register callback
      await NotificationsListener.initialize(callbackHandle: _onNotification);
      await NotificationsListener.registerEventHandle(_onNotification);
      await NotificationsListener.startService();

      // Listen to ReceivePort for notification events
      final port = NotificationsListener.receivePort;
      _subscription = port!.listen((event) {
        if (event is NotificationEvent) {
          _notificationController.add(event);
          _onNotification(event);
        }
      }) as StreamSubscription<NotificationEvent>?;

      return true;
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
      return false;
    }
  }

  // Open system settings for notification access
  Future<void> openNotificationSettings() async {
    try {
      await platform.invokeMethod('openNotificationListenerSettings');
    } catch (e) {
      debugPrint('Error opening notification settings: $e');
    }
  }

  // Check if notification access is granted
  Future<bool> requestNotificationPermission() async {
    try {
      bool enabled =
          await platform.invokeMethod('isNotificationListenerEnabled');

      if (!enabled) {
        // Open settings to grant permission
        await openNotificationSettings();
        // Re-check permission (this will likely still be false until the user returns to the app)
        return await platform.invokeMethod('isNotificationListenerEnabled');
      }

      return enabled;
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return false;
    }
  }

  // Process an incoming notification
  void _onNotification(NotificationEvent event) {
    try {
      if (event.packageName == null ||
          event.title == null ||
          event.text == null) {
        return;
      }

      _notificationController.add(event);

      // Check if this is from a monitored app
      if (monitoredPackages.contains(event.packageName)) {
        debugPrint('Notification from monitored app: ${event.packageName}');

        // Try to parse transaction
        _parser
            .parseNotificationTransaction(
          event.title ?? '',
          event.text ?? '',
          event.packageName ?? '',
          DateTime.now(),
        )
            .then((transaction) {
          if (transaction != null) {
            onTransactionDetected(transaction);
          }
        });
      }
    } catch (e) {
      debugPrint('Error processing notification: $e');
    }
  }

  // Check if service is running
  Future<bool> isServiceRunning() async {
    return await NotificationsListener.isRunning ?? false;
  }

  // Dispose resources
  void dispose() {
    _subscription?.cancel();
    _notificationController.close();
  }
}
