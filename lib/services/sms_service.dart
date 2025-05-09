import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:telephony/telephony.dart';

import '../models/transaction.dart';
import 'transaction_parser.dart';

class SmsService {
  final Telephony _telephony = Telephony.instance;
  final TransactionParser _parser = TransactionParser();

  // Callback to handle parsed transactions
  final Function(Transaction) onTransactionDetected;

  // Stream controller for SMS events
  final _smsController = StreamController<SmsMessage>.broadcast();
  Stream<SmsMessage> get smsStream => _smsController.stream;

  SmsService({required this.onTransactionDetected});

  // Initialize and start listening to SMS
  Future<bool> initialize() async {
    bool permissionsGranted =
        await _telephony.requestPhoneAndSmsPermissions ?? false;

    if (permissionsGranted) {
      _setupSmsListener();
      return true;
    }

    return false;
  }

  // Set up the SMS listener
  void _setupSmsListener() {
    _telephony.listenIncomingSms(
      onNewMessage: _onNewSms,
      onBackgroundMessage: backgroundMessageHandler,
      listenInBackground: true,
    );
  }

  // Handler for new SMS
  void _onNewSms(SmsMessage message) async {
    try {
      debugPrint('SMS received: ${message.body}');
      _smsController.add(message);

      // Check if this is a bank transaction SMS
      if (_parser.isBankTransactionSms(
          message.body ?? '', message.address ?? '')) {
        final transaction = await _parser.parseSmsTransaction(
          message.body ?? '',
          message.address ?? '',
          DateTime.fromMillisecondsSinceEpoch(
              message.date ?? DateTime.now().millisecondsSinceEpoch),
        );

        if (transaction != null) {
          onTransactionDetected(transaction);
        }
      }
    } catch (e) {
      debugPrint('Error processing SMS: $e');
    }
  }

  // Close resources
  void dispose() {
    _smsController.close();
  }

  // Check SMS inbox for historical transactions
  Future<List<Transaction>> checkHistoricalSms({int limit = 50}) async {
    List<Transaction> transactions = [];

    try {
      List<SmsMessage> messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.DATE).greaterThan(DateTime.now()
            .subtract(const Duration(days: 30))
            .millisecondsSinceEpoch
            .toString()),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
        // limitCount: limit,
      );

      for (var message in messages) {
        if (_parser.isBankTransactionSms(
            message.body ?? '', message.address ?? '')) {
          final transaction = await _parser.parseSmsTransaction(
            message.body ?? '',
            message.address ?? '',
            DateTime.fromMillisecondsSinceEpoch(
                message.date ?? DateTime.now().millisecondsSinceEpoch),
          );

          if (transaction != null) {
            transactions.add(transaction);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking historical SMS: $e');
    }

    return transactions;
  }
}

// Top-level function for background SMS handling
@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) async {
  // This will be called in the background
  // Any background processing should be minimal
  debugPrint('Background SMS received: ${message.body}');
}
