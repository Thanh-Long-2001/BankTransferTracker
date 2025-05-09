import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Service to handle platform-specific auto-start functionality
class AutoStartService {
  static const _methodChannel = MethodChannel('com.example.bank_transaction_tracker/auto_start');
  
  /// Singleton instance
  static final AutoStartService _instance = AutoStartService._internal();
  
  /// Factory constructor to return the singleton instance
  factory AutoStartService() => _instance;
  
  /// Private constructor for singleton pattern
  AutoStartService._internal();
  
  /// Check if the app was launched by the boot receiver
  Future<bool> wasLaunchedFromBoot() async {
    if (kIsWeb) return false; // Not applicable for web
    
    try {
      final result = await _methodChannel.invokeMethod<bool>('wasLaunchedFromBoot');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking if app was launched from boot: $e');
      return false;
    }
  }
}