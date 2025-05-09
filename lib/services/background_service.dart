import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../models/transaction.dart';

typedef TransactionCallback = void Function(Transaction transaction);

/// Service to handle background tasks for monitoring transactions
class BackgroundService {
  static const String backgroundTaskName = 'monitorBankTransactions';
  static const Duration taskInterval = Duration(minutes: 15);
  
  bool _isRunning = false;
  TransactionCallback? _onNewTransactionCallback;
  
  /// Getter for service running state
  bool get isRunning => _isRunning;
  
  /// Initialize the service
  Future<void> initialize({required TransactionCallback onNewTransactionCallback}) async {
    _onNewTransactionCallback = onNewTransactionCallback;
    debugPrint('BackgroundService initialized');
  }
  
  /// Start the monitoring service
  Future<bool> startService() async {
    try {
      if (kIsWeb) {
        // Web doesn't support background services, so we'll just simulate it
        _isRunning = true;
        debugPrint('Started simulated background service for web');
        return true;
      }
      
      // Register periodic task for native platforms
      await Workmanager().registerPeriodicTask(
        backgroundTaskName,
        backgroundTaskName,
        frequency: taskInterval,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      
      _isRunning = true;
      debugPrint('Background service started');
      return true;
    } catch (e) {
      debugPrint('Error starting background service: $e');
      return false;
    }
  }
  
  /// Stop the monitoring service
  Future<bool> stopService() async {
    try {
      if (kIsWeb) {
        // Web doesn't support background services, so we'll just simulate it
        _isRunning = false;
        debugPrint('Stopped simulated background service for web');
        return true;
      }
      
      // Cancel tasks for native platforms
      await Workmanager().cancelAll();
      
      _isRunning = false;
      debugPrint('Background service stopped');
      return true;
    } catch (e) {
      debugPrint('Error stopping background service: $e');
      return false;
    }
  }
  
  /// Process bank transactions in background
  static Future<bool> processTransactionsInBackground() async {
    debugPrint('Processing bank transactions in background...');
    // In a real implementation, this would check for new SMS and notifications
    // and process them into transactions
    return true;
  }
  
  /// Add a transaction manually (for testing)
  void addTransaction(Transaction transaction) {
    if (_onNewTransactionCallback != null) {
      _onNewTransactionCallback!(transaction);
    }
  }
}