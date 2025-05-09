import 'package:intl/intl.dart';

enum TransactionSource {
  sms,
  notification,
}

enum TransactionDirection {
  incoming,
  outgoing,
  unknown,
}

class Transaction {
  final String id;
  final DateTime timestamp;
  final String bank;
  final double amount;
  final String description;
  final TransactionSource source;
  final String sourceAppPackage;
  final TransactionDirection direction;
  final bool synced;

  Transaction({
    required this.id,
    required this.timestamp,
    required this.bank,
    required this.amount,
    required this.description,
    required this.source,
    required this.sourceAppPackage,
    required this.direction,
    this.synced = false,
  });

  // Format amount with currency
  String get formattedAmount {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    return currencyFormat.format(amount);
  }

  // Format date
  String get formattedDate {
    return DateFormat('yyyy-MM-dd HH:mm').format(timestamp);
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'bank': bank,
      'amount': amount,
      'description': description,
      'source': source.index,
      'sourceAppPackage': sourceAppPackage,
      'direction': direction.index,
      'synced': synced ? 1 : 0,
    };
  }

  // Create from Map (database)
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      bank: map['bank'],
      amount: map['amount'],
      description: map['description'],
      source: TransactionSource.values[map['source']],
      sourceAppPackage: map['sourceAppPackage'],
      direction: TransactionDirection.values[map['direction']],
      synced: map['synced'] == 1,
    );
  }

  // Create a copy with modifications
  Transaction copyWith({
    String? id,
    DateTime? timestamp,
    String? bank,
    double? amount,
    String? description,
    TransactionSource? source,
    String? sourceAppPackage,
    TransactionDirection? direction,
    bool? synced,
  }) {
    return Transaction(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      bank: bank ?? this.bank,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      source: source ?? this.source,
      sourceAppPackage: sourceAppPackage ?? this.sourceAppPackage,
      direction: direction ?? this.direction,
      synced: synced ?? this.synced,
    );
  }

  // Convert to Google Sheets row format
  List<String> toGoogleSheetsRow() {
    return [
      formattedDate,
      bank,
      formattedAmount,
      description,
      source == TransactionSource.sms ? "SMS" : "Notification: $sourceAppPackage",
      direction == TransactionDirection.incoming ? "IN" : 
        direction == TransactionDirection.outgoing ? "OUT" : "UNKNOWN"
    ];
  }
}
