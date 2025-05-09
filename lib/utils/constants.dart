import 'package:flutter/material.dart';

class ColorConstants {
  // Primary color palette
  static const Color primaryColor = Color(0xFF1A73E8);
  static const Color primaryColorLight = Color(0xFF5EA1EE);
  static const Color primaryColorDark = Color(0xFF0D47A1);
  
  // Secondary/accent color palette
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color accentColorLight = Color(0xFF80E27E);
  static const Color accentColorDark = Color(0xFF087F23);
  
  // Dark theme colors
  static const Color darkPrimaryColor = Color(0xFF1F1F1F);
  static const Color darkAccentColor = Color(0xFF2E7D32);
  
  // Status colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color warningColor = Color(0xFFFFA000);
  static const Color infoColor = Color(0xFF1976D2);
  
  // Background and surface colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  
  // Text colors
  static const Color primaryTextColor = Color(0xFF212121);
  static const Color secondaryTextColor = Color(0xFF757575);
  static const Color disabledTextColor = Color(0xFFBDBDBD);
  
  // Transaction-specific colors
  static const Color incomingTransactionColor = Color(0xFF4CAF50);
  static const Color outgoingTransactionColor = Color(0xFFD32F2F);
  static const Color unknownTransactionColor = Color(0xFF757575);
  
  // Dark theme equivalents
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkCardColor = Color(0xFF242424);
  static const Color darkPrimaryTextColor = Color(0xFFEEEEEE);
  static const Color darkSecondaryTextColor = Color(0xFFAAAAAA);
}

class AppConstants {
  // Delays and timeouts
  static const Duration splashScreenDuration = Duration(seconds: 2);
  static const Duration backgroundSyncInterval = Duration(minutes: 15);
  static const Duration networkTimeout = Duration(seconds: 30);
  
  // Data constraints
  static const int maxRecentTransactions = 50;
  static const int maxHistoricalSms = 100;
  
  // Notification settings
  static const String notificationChannelId = 'transaction_notifications';
  static const String notificationChannelName = 'Transaction Notifications';
  static const String persistentNotificationChannelId = 'background_service';
  static const String persistentNotificationChannelName = 'Background Service';
  
  // Shared Preferences keys
  static const String prefKeyAppConfig = 'app_config';
  static const String prefKeyFirstRun = 'first_run';
  
  // Bank configuration
  static final List<Map<String, String>> defaultBankApps = [
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
}
