import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/transaction.dart';

class DatabaseService {
  late Database _database;
  static const String tableName = 'transactions';
  
  // Initialize database
  Future<void> initialize() async {
    try {
      // Get the database path
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'bank_transactions.db');
      
      // Open the database
      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          // Create transactions table
          await db.execute('''
            CREATE TABLE $tableName (
              id TEXT PRIMARY KEY,
              timestamp INTEGER NOT NULL,
              bank TEXT NOT NULL,
              amount REAL NOT NULL,
              description TEXT NOT NULL,
              source INTEGER NOT NULL,
              sourceAppPackage TEXT NOT NULL,
              direction INTEGER NOT NULL,
              synced INTEGER NOT NULL DEFAULT 0
            )
          ''');
        },
      );
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }
  
  // Save a transaction to the database
  Future<bool> saveTransaction(Transaction transaction) async {
    try {
      // Check if transaction already exists
      final existing = await _database.query(
        tableName,
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
      
      if (existing.isNotEmpty) {
        // Update existing transaction
        await _database.update(
          tableName,
          transaction.toMap(),
          where: 'id = ?',
          whereArgs: [transaction.id],
        );
      } else {
        // Insert new transaction
        await _database.insert(
          tableName,
          transaction.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      return true;
    } catch (e) {
      debugPrint('Error saving transaction: $e');
      return false;
    }
  }
  
  // Mark a transaction as synced
  Future<bool> markTransactionSynced(String id) async {
    try {
      await _database.update(
        tableName,
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return true;
    } catch (e) {
      debugPrint('Error marking transaction as synced: $e');
      return false;
    }
  }
  
  // Get all transactions
  Future<List<Transaction>> getAllTransactions() async {
    try {
      final List<Map<String, dynamic>> maps = await _database.query(
        tableName,
        orderBy: 'timestamp DESC',
      );
      
      return List.generate(maps.length, (i) {
        return Transaction.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Error getting all transactions: $e');
      return [];
    }
  }
  
  // Get recent transactions
  Future<List<Transaction>> getRecentTransactions({int limit = 50}) async {
    try {
      final List<Map<String, dynamic>> maps = await _database.query(
        tableName,
        orderBy: 'timestamp DESC',
        limit: limit,
      );
      
      return List.generate(maps.length, (i) {
        return Transaction.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Error getting recent transactions: $e');
      return [];
    }
  }
  
  // Get unsynced transactions
  Future<List<Transaction>> getUnsyncedTransactions() async {
    try {
      final List<Map<String, dynamic>> maps = await _database.query(
        tableName,
        where: 'synced = ?',
        whereArgs: [0],
        orderBy: 'timestamp ASC',
      );
      
      return List.generate(maps.length, (i) {
        return Transaction.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Error getting unsynced transactions: $e');
      return [];
    }
  }
  
  // Delete a transaction
  Future<bool> deleteTransaction(String id) async {
    try {
      await _database.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return true;
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      return false;
    }
  }
  
  // Delete all transactions
  Future<bool> deleteAllTransactions() async {
    try {
      await _database.delete(tableName);
      return true;
    } catch (e) {
      debugPrint('Error deleting all transactions: $e');
      return false;
    }
  }
  
  // Get transaction statistics
  Future<Map<String, dynamic>> getTransactionStats() async {
    try {
      // Total transactions
      final totalResult = await _database.rawQuery('SELECT COUNT(*) as count FROM $tableName');
      final totalCount = Sqflite.firstIntValue(totalResult) ?? 0;
      
      // Incoming transactions amount
      final incomingResult = await _database.rawQuery(
        'SELECT SUM(amount) as sum FROM $tableName WHERE direction = ?',
        [TransactionDirection.incoming.index],
      );
      final incomingAmount = incomingResult.first['sum'] as double? ?? 0.0;
      
      // Outgoing transactions amount
      final outgoingResult = await _database.rawQuery(
        'SELECT SUM(amount) as sum FROM $tableName WHERE direction = ?',
        [TransactionDirection.outgoing.index],
      );
      final outgoingAmount = outgoingResult.first['sum'] as double? ?? 0.0;
      
      // Transactions by bank
      final bankResults = await _database.rawQuery(
        'SELECT bank, COUNT(*) as count FROM $tableName GROUP BY bank ORDER BY count DESC',
      );
      
      final bankCounts = <String, int>{};
      for (var row in bankResults) {
        bankCounts[row['bank'] as String] = row['count'] as int;
      }
      
      return {
        'totalCount': totalCount,
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
