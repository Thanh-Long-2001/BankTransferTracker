import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';

class TransactionParser {
  // Regular expressions for common Vietnamese banks
  static final Map<String, RegExp> _bankSenderPatterns = {
    'VIETCOMBANK': RegExp(r'^VIETCOMBANK|^VCB', caseSensitive: false),
    'MB BANK': RegExp(r'^MB|^MBBANK', caseSensitive: false),
    'TECHCOMBANK': RegExp(r'^TECHCOMBANK|^TCB', caseSensitive: false),
    'TIMO': RegExp(r'^TIMO', caseSensitive: false),
    'MOMO': RegExp(r'^MOMO|^Vi MoMo', caseSensitive: false),
    'BIDV': RegExp(r'^BIDV', caseSensitive: false),
    'VIETINBANK': RegExp(r'^VIETINBANK|^VTB', caseSensitive: false),
    'ACB': RegExp(r'^ACB', caseSensitive: false),
    'VPBANK': RegExp(r'^VPBANK|^VPB', caseSensitive: false),
    'SACOMBANK': RegExp(r'^SACOMBANK|^SCB', caseSensitive: false),
  };
  
  // Common Vietnamese bank package names
  static final Map<String, String> _bankAppPackages = {
    'com.vietcombank.vcbmobile': 'VIETCOMBANK',
    'com.mbmobile': 'MB BANK',
    'vn.com.techcombank.bb.app': 'TECHCOMBANK',
    'com.timo.wallet': 'TIMO',
    'com.mservice.momotransfer': 'MOMO',
    'com.vnpay.bidv': 'BIDV',
    'com.vietinbank.ipay': 'VIETINBANK',
    'mobile.acb.com.vn': 'ACB',
    'com.vnpay.vpbank': 'VPBANK',
    'com.VnptEpay.development.scb': 'SACOMBANK',
  };
  
  // Money amount patterns for different formats
  static final RegExp _moneyPattern = RegExp(
    r'(?:VND|₫|đ)?(?:\s*)([0-9,.]+)(?:\s*)(?:VND|₫|đ)?',
    caseSensitive: false,
  );
  
  // Check if this is a bank transaction SMS
  bool isBankTransactionSms(String body, String sender) {
    if (body.isEmpty || sender.isEmpty) {
      return false;
    }
    
    // Check if sender matches any bank pattern
    bool isBankSender = _bankSenderPatterns.values.any((pattern) => 
      pattern.hasMatch(sender));
    
    if (isBankSender) {
      // Must contain amount pattern and transaction keywords
      return _moneyPattern.hasMatch(body) && 
        (body.contains('transfer') || 
         body.contains('transaction') || 
         body.contains('giao dich') || 
         body.contains('chuyen tien') || 
         body.contains('nhan tien') ||
         body.contains('deposit') ||
         body.contains('withdraw') ||
         body.contains('gui tien') ||
         body.contains('rut tien'));
    }
    
    // Check content for bank keywords if sender is not recognized
    return body.contains('VCB') ||
           body.contains('VIETCOMBANK') ||
           body.contains('MBBANK') ||
           body.contains('TECHCOMBANK') ||
           body.contains('TIMO') ||
           body.contains('MOMO') ||
           body.contains('BIDV') ||
           body.contains('VIETINBANK') ||
           body.contains('ACB') ||
           body.contains('VPBANK') ||
           body.contains('SACOMBANK');
  }
  
  // Parse SMS message to extract transaction details
  Future<Transaction?> parseSmsTransaction(
    String body, 
    String sender, 
    DateTime timestamp,
  ) async {
    try {
      if (body.isEmpty) {
        return null;
      }
      
      // Determine the bank
      String bank = 'UNKNOWN BANK';
      for (var entry in _bankSenderPatterns.entries) {
        if (entry.value.hasMatch(sender)) {
          bank = entry.key;
          break;
        }
      }
      
      // If bank not found in sender, try to find in message body
      if (bank == 'UNKNOWN BANK') {
        for (var entry in _bankSenderPatterns.entries) {
          if (body.toUpperCase().contains(entry.key) || 
              entry.value.hasMatch(body)) {
            bank = entry.key;
            break;
          }
        }
      }
      
      // Extract amount
      final amountMatch = _moneyPattern.firstMatch(body);
      if (amountMatch == null) {
        return null;
      }
      
      String amountStr = amountMatch.group(1) ?? '0';
      amountStr = amountStr.replaceAll(',', '').replaceAll('.', '');
      double amount;
      try {
        amount = double.parse(amountStr);
      } catch (e) {
        amount = 0;
      }
      
      // Determine transaction direction
      TransactionDirection direction = TransactionDirection.unknown;
      if (body.toLowerCase().contains('nhan tien') || 
          body.toLowerCase().contains('received') ||
          body.toLowerCase().contains('credited') ||
          body.toLowerCase().contains('deposit') ||
          body.toLowerCase().contains('gui tien') ||
          body.toLowerCase().contains('+ ')) {
        direction = TransactionDirection.incoming;
      } else if (body.toLowerCase().contains('chuyen tien') || 
                body.toLowerCase().contains('sent') ||
                body.toLowerCase().contains('debited') ||
                body.toLowerCase().contains('withdraw') ||
                body.toLowerCase().contains('rut tien') ||
                body.toLowerCase().contains('- ')) {
        direction = TransactionDirection.outgoing;
      }
      
      // Generate a unique ID
      final id = 'sms_${timestamp.millisecondsSinceEpoch}_${Random().nextInt(10000)}';
      
      return Transaction(
        id: id,
        timestamp: timestamp,
        bank: bank,
        amount: amount,
        description: body,
        source: TransactionSource.sms,
        sourceAppPackage: 'SMS: $sender',
        direction: direction,
      );
    } catch (e) {
      debugPrint('Error parsing SMS transaction: $e');
      return null;
    }
  }
  
  // Parse notification to extract transaction details
  Future<Transaction?> parseNotificationTransaction(
    String title,
    String text,
    String packageName,
    DateTime timestamp,
  ) async {
    try {
      if (title.isEmpty || text.isEmpty) {
        return null;
      }
      
      // Combine title and text for better pattern matching
      final fullText = '$title $text';
      
      // Determine the bank based on package name
      String bank = _bankAppPackages[packageName] ?? 'UNKNOWN BANK';
      
      // If bank not found, try to detect from notification content
      if (bank == 'UNKNOWN BANK') {
        for (var entry in _bankSenderPatterns.entries) {
          if (fullText.toUpperCase().contains(entry.key) || 
              entry.value.hasMatch(fullText)) {
            bank = entry.key;
            break;
          }
        }
      }
      
      // Check if this is a transaction notification
      bool isTransaction = fullText.toLowerCase().contains('transaction') ||
                          fullText.toLowerCase().contains('transfer') ||
                          fullText.toLowerCase().contains('giao dich') ||
                          fullText.toLowerCase().contains('chuyen tien') ||
                          fullText.toLowerCase().contains('nhan tien') ||
                          _moneyPattern.hasMatch(fullText);
      
      if (!isTransaction) {
        return null;
      }
      
      // Extract amount
      final amountMatch = _moneyPattern.firstMatch(fullText);
      if (amountMatch == null) {
        return null;
      }
      
      String amountStr = amountMatch.group(1) ?? '0';
      amountStr = amountStr.replaceAll(',', '').replaceAll('.', '');
      double amount;
      try {
        amount = double.parse(amountStr);
      } catch (e) {
        amount = 0;
      }
      
      // Determine transaction direction
      TransactionDirection direction = TransactionDirection.unknown;
      if (fullText.toLowerCase().contains('nhan tien') || 
          fullText.toLowerCase().contains('received') ||
          fullText.toLowerCase().contains('credited') ||
          fullText.toLowerCase().contains('deposit') ||
          fullText.toLowerCase().contains('gui tien') ||
          fullText.toLowerCase().contains('+ ')) {
        direction = TransactionDirection.incoming;
      } else if (fullText.toLowerCase().contains('chuyen tien') || 
                fullText.toLowerCase().contains('sent') ||
                fullText.toLowerCase().contains('debited') ||
                fullText.toLowerCase().contains('withdraw') ||
                fullText.toLowerCase().contains('rut tien') ||
                fullText.toLowerCase().contains('- ')) {
        direction = TransactionDirection.outgoing;
      }
      
      // Generate a unique ID
      final id = 'notif_${timestamp.millisecondsSinceEpoch}_${Random().nextInt(10000)}';
      
      return Transaction(
        id: id,
        timestamp: timestamp,
        bank: bank,
        amount: amount,
        description: fullText,
        source: TransactionSource.notification,
        sourceAppPackage: packageName,
        direction: direction,
      );
    } catch (e) {
      debugPrint('Error parsing notification transaction: $e');
      return null;
    }
  }
}
