import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_config.dart';
import '../models/transaction.dart';
import '../services/background_service.dart';
import '../services/database_service.dart';
import '../services/google_sheets_service.dart';
import '../services/notification_service.dart';
import '../services/sms_service.dart';

class AppStateProvider with ChangeNotifier {
  // Services
  final BackgroundService _backgroundService = BackgroundService();
  final DatabaseService _databaseService = DatabaseService();
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  
  // Data
  AppConfig _appConfig = AppConfig.empty();
  List<Transaction> _recentTransactions = [];
  List<MonitoredApp> _availableApps = [];
  
  // Status
  bool _isLoading = true;
  bool _isInitialized = false;
  String? _errorMessage;
  
  // Getters
  AppConfig get appConfig => _appConfig;
  List<Transaction> get recentTransactions => _recentTransactions;
  List<MonitoredApp> get availableApps => _availableApps;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isServiceRunning => _backgroundService.isRunning;
  bool get isGoogleSignedIn => _sheetsService.isSignedIn;
  
  // Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _setLoading(true);
    
    try {
      // Load app configuration
      await _loadAppConfig();
      
      // Initialize database service
      await _databaseService.initialize();
      
      // Initialize background service
      await _backgroundService.initialize(
        onNewTransactionCallback: _onNewTransaction,
      );
      
      // Initialize Google Sheets service
      await _sheetsService.initialize();
      
      // Load recent transactions
      await _loadRecentTransactions();
      
      // If service was running, restart it
      if (_appConfig.isServiceRunning) {
        await startMonitoringService();
      }
      
      _isInitialized = true;
      _setLoading(false);
    } catch (e) {
      _setError('Failed to initialize app: $e');
    }
  }
  
  // Load app configuration from shared preferences
  Future<void> _loadAppConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('app_config');
      
      if (configJson != null) {
        _appConfig = AppConfig.fromJsonString(configJson);
      } else {
        _appConfig = AppConfig.empty();
        await _saveAppConfig();
      }
    } catch (e) {
      debugPrint('Error loading app config: $e');
      _appConfig = AppConfig.empty();
    }
  }
  
  // Save app configuration to shared preferences
  Future<void> _saveAppConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_config', _appConfig.toJsonString());
    } catch (e) {
      debugPrint('Error saving app config: $e');
    }
  }
  
  // Load recent transactions from database
  Future<void> _loadRecentTransactions() async {
    try {
      _recentTransactions = await _databaseService.getRecentTransactions();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recent transactions: $e');
    }
  }
  
  // Start the monitoring service
  Future<bool> startMonitoringService() async {
    _setLoading(true);
    
    try {
      final result = await _backgroundService.startService();
      
      if (result) {
        _appConfig = _appConfig.copyWith(isServiceRunning: true);
        await _saveAppConfig();
      }
      
      _setLoading(false);
      return result;
    } catch (e) {
      _setError('Failed to start monitoring service: $e');
      return false;
    }
  }
  
  // Stop the monitoring service
  Future<bool> stopMonitoringService() async {
    _setLoading(true);
    
    try {
      final result = await _backgroundService.stopService();
      
      if (result) {
        _appConfig = _appConfig.copyWith(isServiceRunning: false);
        await _saveAppConfig();
      }
      
      _setLoading(false);
      return result;
    } catch (e) {
      _setError('Failed to stop monitoring service: $e');
      return false;
    }
  }
  
  // Update Google Sheets configuration
  Future<void> updateGoogleSheetsConfig({
    required String sheetId,
    required String sheetTabName,
  }) async {
    _setLoading(true);
    
    try {
      _appConfig = _appConfig.copyWith(
        googleSheetId: sheetId,
        googleSheetTabName: sheetTabName,
      );
      
      await _saveAppConfig();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to update Google Sheets config: $e');
    }
  }
  
  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    
    try {
      final result = await _sheetsService.signIn();
      _setLoading(false);
      return result;
    } catch (e) {
      _setError('Failed to sign in with Google: $e');
      return false;
    }
  }
  
  // Sign out from Google
  Future<void> signOutFromGoogle() async {
    _setLoading(true);
    
    try {
      await _sheetsService.signOut();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to sign out from Google: $e');
    }
  }
  
  // Get user's Google Sheets
  Future<List<Map<String, String>>> getUserSpreadsheets() async {
    _setLoading(true);
    
    try {
      final sheets = await _sheetsService.getUserSpreadsheets();
      _setLoading(false);
      return sheets;
    } catch (e) {
      _setError('Failed to get user spreadsheets: $e');
      return [];
    }
  }
  
  // Get sheets in a spreadsheet
  Future<List<String>> getSpreadsheetSheets(String spreadsheetId) async {
    _setLoading(true);
    
    try {
      final sheets = await _sheetsService.getSpreadsheetSheets(spreadsheetId);
      _setLoading(false);
      return sheets;
    } catch (e) {
      _setError('Failed to get spreadsheet sheets: $e');
      return [];
    }
  }
  
  // Create a new spreadsheet
  Future<Map<String, String>?> createNewSpreadsheet(String title) async {
    _setLoading(true);
    
    try {
      final sheet = await _sheetsService.createSpreadsheet(title);
      _setLoading(false);
      return sheet;
    } catch (e) {
      _setError('Failed to create new spreadsheet: $e');
      return null;
    }
  }
  
  // Update monitored apps
  Future<void> updateMonitoredApps(List<String> packageNames) async {
    _setLoading(true);
    
    try {
      _appConfig = _appConfig.copyWith(selectedAppPackages: packageNames);
      await _saveAppConfig();
      
      // If service is running, restart it to apply new settings
      if (_appConfig.isServiceRunning) {
        await stopMonitoringService();
        await startMonitoringService();
      }
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to update monitored apps: $e');
    }
  }
  
  // Update SMS monitoring setting
  Future<void> updateSmsMonitoring(bool enabled) async {
    _setLoading(true);
    
    try {
      _appConfig = _appConfig.copyWith(enableSmsMonitoring: enabled);
      await _saveAppConfig();
      
      // If service is running, restart it to apply new settings
      if (_appConfig.isServiceRunning) {
        await stopMonitoringService();
        await startMonitoringService();
      }
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to update SMS monitoring: $e');
    }
  }
  
  // Update notification monitoring setting
  Future<void> updateNotificationMonitoring(bool enabled) async {
    _setLoading(true);
    
    try {
      _appConfig = _appConfig.copyWith(enableNotificationMonitoring: enabled);
      await _saveAppConfig();
      
      // If service is running, restart it to apply new settings
      if (_appConfig.isServiceRunning) {
        await stopMonitoringService();
        await startMonitoringService();
      }
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to update notification monitoring: $e');
    }
  }
  
  // Handle new transaction
  void _onNewTransaction(Transaction transaction) {
    _recentTransactions.insert(0, transaction);
    if (_recentTransactions.length > 50) {
      _recentTransactions.removeLast();
    }
    notifyListeners();
  }
  
  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _errorMessage = null;
    }
    notifyListeners();
  }
  
  // Set error message
  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Load installed apps that might send financial notifications
  Future<void> loadInstalledApps() async {
    _setLoading(true);
    
    try {
      // This would normally use a package like device_apps or installed_apps
      // We're using a predefined list for simplicity
      const potentialBankingApps = [
        {'packageName': 'com.vietcombank.vcbmobile', 'appName': 'Vietcombank'},
        {'packageName': 'com.mbmobile', 'appName': 'MB Bank'},
        {'packageName': 'vn.com.techcombank.bb.app', 'appName': 'Techcombank'},
        {'packageName': 'com.timo.wallet', 'appName': 'Timo'},
        {'packageName': 'com.mservice.momotransfer', 'appName': 'Momo'},
        {'packageName': 'com.vnpay.bidv', 'appName': 'BIDV Mobile'},
        {'packageName': 'com.vietinbank.ipay', 'appName': 'VietinBank iPay'},
        {'packageName': 'mobile.acb.com.vn', 'appName': 'ACB Mobile'},
        {'packageName': 'com.vnpay.vpbank', 'appName': 'VPBank Mobile'},
        {'packageName': 'com.VnptEpay.development.scb', 'appName': 'Sacombank mBanking'},
      ];
      
      _availableApps = potentialBankingApps.map((app) {
        return MonitoredApp(
          packageName: app['packageName']!,
          appName: app['appName']!,
          isSelected: _appConfig.selectedAppPackages.contains(app['packageName']!),
        );
      }).toList();
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load installed apps: $e');
    }
  }
  
  // Get transaction statistics
  Future<Map<String, dynamic>> getTransactionStats() async {
    try {
      return await _databaseService.getTransactionStats();
    } catch (e) {
      debugPrint('Error getting transaction stats: $e');
      return {
        'totalCount': 0,
        'incomingAmount': 0.0,
        'outgoingAmount': 0.0,
        'bankCounts': <String, int>{},
      };
    }
  }
}
