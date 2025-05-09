import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction.dart';

/// Service to handle local storage using SharedPreferences instead of a database
class LocalStorageService {
  static const String _transactionsKey = 'stored_transactions';
  static const int _maxStoredTransactions = 200; // Limit to prevent excessive storage use
  
  /// Singleton instance
  static final LocalStorageService _instance = LocalStorageService._internal();
  
  /// Factory constructor to return the singleton instance
  factory LocalStorageService() => _instance;
  
  /// Private constructor for singleton pattern
  LocalStorageService._internal();
  
  /// Initialize the service
  Future<void> initialize() async {
    // Nothing special to initialize for SharedPreferences
    debugPrint('LocalStorageService initialized');
  }
  
  /// Save a transaction to local storage
  Future<bool> saveTransaction(Transaction transaction) async {
    try {
      // Get current transactions
      final transactions = await getTransactions();
      
      // Add new transaction at the beginning
      transactions.insert(0, transaction);
      
      // Limit the number of stored transactions
      if (transactions.length > _maxStoredTransactions) {
        transactions.removeLast();
      }
      
      // Save back to SharedPreferences
      return await _saveTransactions(transactions);
    } catch (e) {
      debugPrint('Error saving transaction: $e');
      return false;
    }
  }
  
  /// Get all stored transactions
  Future<List<Transaction>> getTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getStringList(_transactionsKey) ?? [];
      
      return transactionsJson.map((jsonString) {
        final map = jsonDecode(jsonString) as Map<String, dynamic>;
        return Transaction.fromJson(map);
      }).toList();
    } catch (e) {
      debugPrint('Error getting transactions: $e');
      return [];
    }
  }
  
  /// Get recent transactions with a limit
  Future<List<Transaction>> getRecentTransactions({int limit = 50}) async {
    final transactions = await getTransactions();
    return transactions.take(limit).toList();
  }
  
  /// Save list of transactions to SharedPreferences
  Future<bool> _saveTransactions(List<Transaction> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final transactionsJson = transactions.map((transaction) {
        return jsonEncode(transaction.toJson());
      }).toList();
      
      return await prefs.setStringList(_transactionsKey, transactionsJson);
    } catch (e) {
      debugPrint('Error saving transactions: $e');
      return false;
    }
  }
  
  /// Delete all transactions
  Future<bool> deleteAllTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_transactionsKey);
    } catch (e) {
      debugPrint('Error deleting transactions: $e');
      return false;
    }
  }
  
  /// Get transaction statistics (count, total amounts, etc.)
  Future<Map<String, dynamic>> getTransactionStats() async {
    try {
      final transactions = await getTransactions();
      
      double incomingAmount = 0;
      double outgoingAmount = 0;
      Map<String, int> bankCounts = {};
      
      for (final transaction in transactions) {
        // Update amounts
        if (transaction.direction == TransactionDirection.incoming) {
          incomingAmount += transaction.amount;
        } else {
          outgoingAmount += transaction.amount;
        }
        
        // Update bank counts
        final bank = transaction.bank;
        bankCounts[bank] = (bankCounts[bank] ?? 0) + 1;
      }
      
      return {
        'totalCount': transactions.length,
        'incomingAmount': incomingAmount,
        'outgoingAmount': outgoingAmount,
        'bankCounts': bankCounts,
      };
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