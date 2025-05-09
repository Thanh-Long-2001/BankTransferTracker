import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../models/app_config.dart';
import '../models/transaction.dart';
import 'database_service.dart';
import 'google_sheets_service.dart';
import 'notification_service.dart';
import 'sms_service.dart';

class BackgroundService {
  static const String backgroundTaskName = 'com.example.bank_transaction_tracker.background_task';
  static const String persistentNotificationChannelId = 'bank_transaction_tracker_channel';
  static const String persistentNotificationChannelName = 'Transaction Monitoring';
  
  late DatabaseService _databaseService;
  SmsService? _smsService;
  NotificationService? _notificationService;
  GoogleSheetsService? _sheetsService;
  
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  Timer? _syncTimer;
  bool _isRunning = false;
  
  // Callback for new transactions
  Function(Transaction)? onNewTransaction;
  
  // Singleton pattern
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();
  
  // Initialize background service
  Future<void> initialize({Function(Transaction)? onNewTransactionCallback}) async {
    _databaseService = DatabaseService();
    await _databaseService.initialize();
    
    onNewTransaction = onNewTransactionCallback;
    
    // Initialize notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _notificationsPlugin.initialize(initializationSettings);
    
    // Create notification channel for persistent notification
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      persistentNotificationChannelId,
      persistentNotificationChannelName,
      importance: Importance.low,
    );
    
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  
  // Start background service
  Future<bool> startService() async {
    if (_isRunning) return true;
    
    try {
      // Get app configuration
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('app_config');
      if (configJson == null) {
        debugPrint('No app configuration found');
        return false;
      }
      
      final config = AppConfig.fromJsonString(configJson);
      
      // Check if Google Sheets is configured
      if (!config.isGoogleSheetsConfigured) {
        debugPrint('Google Sheets not configured');
        return false;
      }
      
      // Initialize services
      if (config.enableSmsMonitoring) {
        _smsService = SmsService(onTransactionDetected: _handleNewTransaction);
        await _smsService!.initialize();
      }
      
      if (config.enableNotificationMonitoring) {
        _notificationService = NotificationService(
          onTransactionDetected: _handleNewTransaction,
          monitoredPackages: config.selectedAppPackages,
        );
        await _notificationService!.initialize();
      }
      
      _sheetsService = GoogleSheetsService();
      await _sheetsService!.initialize();
      
      // If not signed in, try to sign in
      if (!_sheetsService!.isSignedIn) {
        final signInResult = await _sheetsService!.signIn();
        if (!signInResult) {
          debugPrint('Failed to sign in to Google');
          return false;
        }
      }
      
      // Show persistent notification
      await _showPersistentNotification();
      
      // Schedule periodic background task
      await Workmanager().registerPeriodicTask(
        backgroundTaskName,
        backgroundTaskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      
      // Start periodic sync
      _startPeriodicSync();
      
      _isRunning = true;
      
      // Update config
      await prefs.setString('app_config', 
        config.copyWith(isServiceRunning: true).toJsonString());
      
      return true;
    } catch (e) {
      debugPrint('Error starting service: $e');
      return false;
    }
  }
  
  // Stop background service
  Future<bool> stopService() async {
    try {
      _smsService?.dispose();
      _notificationService?.dispose();
      
      // Cancel periodic sync
      _syncTimer?.cancel();
      
      // Cancel background task
      await Workmanager().cancelByUniqueName(backgroundTaskName);
      
      // Cancel persistent notification
      await _notificationsPlugin.cancel(1);
      
      _isRunning = false;
      
      // Update config
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('app_config');
      if (configJson != null) {
        final config = AppConfig.fromJsonString(configJson);
        await prefs.setString('app_config', 
          config.copyWith(isServiceRunning: false).toJsonString());
      }
      
      return true;
    } catch (e) {
      debugPrint('Error stopping service: $e');
      return false;
    }
  }
  
  // Handle new transaction
  Future<void> _handleNewTransaction(Transaction transaction) async {
    try {
      // Save to database
      await _databaseService.saveTransaction(transaction);
      
      // Notify listeners
      onNewTransaction?.call(transaction);
      
      // Show notification
      await _showTransactionNotification(transaction);
      
      // Try to sync immediately
      await _syncTransactions();
    } catch (e) {
      debugPrint('Error handling transaction: $e');
    }
  }
  
  // Show transaction notification
  Future<void> _showTransactionNotification(Transaction transaction) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'transaction_notifications',
        'Transaction Notifications',
        importance: Importance.high,
        priority: Priority.high,
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      // Determine title based on transaction direction
      String title;
      if (transaction.direction == TransactionDirection.incoming) {
        title = 'Money Received: ${transaction.formattedAmount}';
      } else if (transaction.direction == TransactionDirection.outgoing) {
        title = 'Money Sent: ${transaction.formattedAmount}';
      } else {
        title = 'Transaction: ${transaction.formattedAmount}';
      }
      
      await _notificationsPlugin.show(
        transaction.id.hashCode,
        title,
        '${transaction.bank}: ${transaction.description}',
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Error showing transaction notification: $e');
    }
  }
  
  // Show persistent notification
  Future<void> _showPersistentNotification() async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        persistentNotificationChannelId,
        persistentNotificationChannelName,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      await _notificationsPlugin.show(
        1, // Fixed ID for the persistent notification
        'Transaction Tracker Active',
        'Listening for banking transactions...',
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Error showing persistent notification: $e');
    }
  }
  
  // Sync transactions to Google Sheets
  Future<void> _syncTransactions() async {
    try {
      if (_sheetsService == null || !_sheetsService!.isSignedIn) {
        debugPrint('Sheets service not ready');
        return;
      }
      
      // Get app configuration
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('app_config');
      if (configJson == null) {
        debugPrint('No app configuration found');
        return;
      }
      
      final config = AppConfig.fromJsonString(configJson);
      if (!config.isGoogleSheetsConfigured) {
        debugPrint('Google Sheets not configured');
        return;
      }
      
      // Get unsynchronized transactions
      final transactions = await _databaseService.getUnsyncedTransactions();
      if (transactions.isEmpty) {
        debugPrint('No unsynchronized transactions');
        return;
      }
      
      // Sync transactions in batch
      final success = await _sheetsService!.appendTransactionsBatch(
        config.googleSheetId!,
        config.googleSheetTabName!,
        transactions,
      );
      
      if (success) {
        // Mark transactions as synced
        for (var transaction in transactions) {
          await _databaseService.markTransactionSynced(transaction.id);
        }
        
        debugPrint('Successfully synced ${transactions.length} transactions');
      } else {
        debugPrint('Failed to sync transactions');
      }
    } catch (e) {
      debugPrint('Error syncing transactions: $e');
    }
  }
  
  // Start periodic sync
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (timer) async {
      await _syncTransactions();
    });
  }
  
  // Check if service is running
  bool get isRunning => _isRunning;
  
  // Background task implementation
  static Future<void> processTransactionsInBackground() async {
    final instance = BackgroundService();
    
    try {
      final databaseService = DatabaseService();
      await databaseService.initialize();
      
      // Get app configuration
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('app_config');
      if (configJson == null) {
        debugPrint('No app configuration found');
        return;
      }
      
      final config = AppConfig.fromJsonString(configJson);
      if (!config.isGoogleSheetsConfigured) {
        debugPrint('Google Sheets not configured');
        return;
      }
      
      // Initialize sheets service
      final sheetsService = GoogleSheetsService();
      await sheetsService.initialize();
      
      // If not signed in, try to sign in silently
      if (!sheetsService.isSignedIn) {
        final signInResult = await sheetsService.initialize();
        if (!signInResult) {
          debugPrint('Failed to sign in to Google');
          return;
        }
      }
      
      // Get unsynchronized transactions
      final transactions = await databaseService.getUnsyncedTransactions();
      if (transactions.isEmpty) {
        debugPrint('No unsynchronized transactions in background task');
        return;
      }
      
      // Sync transactions in batch
      final success = await sheetsService.appendTransactionsBatch(
        config.googleSheetId!,
        config.googleSheetTabName!,
        transactions,
      );
      
      if (success) {
        // Mark transactions as synced
        for (var transaction in transactions) {
          await databaseService.markTransactionSynced(transaction.id);
        }
        
        debugPrint('Background task: Successfully synced ${transactions.length} transactions');
      } else {
        debugPrint('Background task: Failed to sync transactions');
      }
    } catch (e) {
      debugPrint('Error in background task: $e');
    }
  }
}
