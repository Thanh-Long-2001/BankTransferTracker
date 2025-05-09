import 'dart:convert';

/// Enum representing the direction of a transaction
enum TransactionDirection {
  incoming,
  outgoing,
}

/// Model class for bank transactions
class Transaction {
  final String id;
  final DateTime date;
  final String bank;
  final double amount;
  final String description;
  final String source; // SMS or Notification
  final TransactionDirection direction;
  
  /// Constructor for Transaction
  Transaction({
    required this.id,
    required this.date,
    required this.bank,
    required this.amount,
    required this.description,
    required this.source,
    required this.direction,
  });
  
  /// Create a Transaction from a JSON map
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      bank: json['bank'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      source: json['source'] as String,
      direction: TransactionDirection.values.byName(json['direction'] as String),
    );
  }
  
  /// Convert Transaction to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'bank': bank,
      'amount': amount,
      'description': description,
      'source': source,
      'direction': direction.name,
    };
  }
  
  /// Serialize Transaction to a JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }
  
  /// Create a Transaction from a SMS message
  static Transaction? fromSmsText(String sender, String body, DateTime timestamp) {
    // Skip non-bank messages
    if (!_isBankSender(sender)) {
      return null;
    }
    
    try {
      // Extract bank name from sender
      final bank = _extractBankName(sender);
      
      // Extract transaction info from SMS body
      final amount = _extractAmount(body);
      final direction = _detectTransactionDirection(body);
      final description = _extractDescription(body);
      
      // Only create transaction if we could extract an amount
      if (amount > 0) {
        return Transaction(
          id: 'sms_${timestamp.millisecondsSinceEpoch}',
          date: timestamp,
          bank: bank,
          amount: amount,
          description: description,
          source: 'SMS',
          direction: direction,
        );
      }
    } catch (e) {
      print('Error parsing SMS: $e');
    }
    
    return null;
  }
  
  /// Create a Transaction from a notification
  static Transaction? fromNotification({
    required String packageName,
    required String title,
    required String text,
    required DateTime timestamp,
  }) {
    // Skip non-bank apps
    if (!_isBankApp(packageName)) {
      return null;
    }
    
    try {
      // Extract bank name from package name
      final bank = _extractBankNameFromPackage(packageName);
      
      // Combine title and text for parsing
      final fullText = '$title $text';
      
      // Extract transaction info
      final amount = _extractAmount(fullText);
      final direction = _detectTransactionDirection(fullText);
      final description = _extractDescription(fullText);
      
      // Only create transaction if we could extract an amount
      if (amount > 0) {
        return Transaction(
          id: 'notif_${timestamp.millisecondsSinceEpoch}',
          date: timestamp,
          bank: bank,
          amount: amount,
          description: description,
          source: 'Notification',
          direction: direction,
        );
      }
    } catch (e) {
      print('Error parsing notification: $e');
    }
    
    return null;
  }
  
  /// Check if sender is from a bank
  static bool _isBankSender(String sender) {
    final bankKeywords = [
      'vcb', 'vietcombank', 'mbbank', 'acb', 'techcombank', 
      'viettinbank', 'bidv', 'sacombank', 'tpbank', 'bank',
      'momo', 'zalopay', 'vnpay', 'timo'
    ];
    
    final senderLower = sender.toLowerCase();
    return bankKeywords.any((keyword) => senderLower.contains(keyword));
  }
  
  /// Check if app is a banking app
  static bool _isBankApp(String packageName) {
    final bankPackages = [
      'com.vietcombank.vcbmobile',
      'com.mbmobile',
      'vn.com.techcombank.bb.app',
      'com.VnptEpay.development.scb',
      'mobile.acb.com.vn',
      'com.vnpay',
      'com.vnpay.bidv',
      'com.vietinbank.ipay',
      'com.tpb.mb.gprsandroid',
      'com.mservice.momotransfer',
      'vn.com.zalopay',
      'com.vnpay.epay', 
      'com.timo.wallet',
    ];
    
    return bankPackages.contains(packageName);
  }
  
  /// Extract bank name from sender
  static String _extractBankName(String sender) {
    final mapping = {
      'vcb': 'Vietcombank',
      'vietcombank': 'Vietcombank',
      'mbbank': 'MB Bank',
      'techcombank': 'Techcombank',
      'acb': 'ACB Bank',
      'bidv': 'BIDV',
      'viettinbank': 'VietinBank',
      'sacombank': 'Sacombank',
      'tpbank': 'TPBank',
      'momo': 'Momo',
      'zalopay': 'ZaloPay',
      'vnpay': 'VNPay',
      'timo': 'Timo',
    };
    
    final senderLower = sender.toLowerCase();
    
    for (final entry in mapping.entries) {
      if (senderLower.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return 'Bank'; // Default if no match
  }
  
  /// Extract bank name from package name
  static String _extractBankNameFromPackage(String packageName) {
    final mapping = {
      'vietcombank': 'Vietcombank',
      'mbmobile': 'MB Bank',
      'techcombank': 'Techcombank',
      'acb': 'ACB Bank',
      'bidv': 'BIDV',
      'vietinbank': 'VietinBank',
      'sacombank': 'Sacombank',
      'tpb': 'TPBank',
      'momo': 'Momo',
      'zalopay': 'ZaloPay',
      'vnpay': 'VNPay',
      'timo': 'Timo',
    };
    
    for (final entry in mapping.entries) {
      if (packageName.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }
    
    return 'Bank App'; // Default if no match
  }
  
  /// Extract amount from message text
  static double _extractAmount(String text) {
    // Look for patterns like "1,000,000 VND", "1.000.000 VND", "1,000,000đ"
    final amountRegex = RegExp(r'([\d,.]+)(\s*)((VND|vnd|đ|\$))', multiLine: true);
    final match = amountRegex.firstMatch(text);
    
    if (match != null) {
      final amountStr = match.group(1)!;
      // Remove thousands separators
      final normalized = amountStr
          .replaceAll(',', '')
          .replaceAll('.', '');
      
      try {
        return double.parse(normalized);
      } catch (e) {
        print('Error parsing amount: $e');
      }
    }
    
    return 0.0;
  }
  
  /// Detect if transaction is incoming or outgoing
  static TransactionDirection _detectTransactionDirection(String text) {
    final incomingKeywords = [
      'received', 'deposited', 'credited', 'incoming',
      'receive', 'deposit', 'credit', 'in', 'nhan', 'nạp',
      '+', 'plus', 'added', 'transferred to your', 'nhận',
      'credited to', 'vào tk', 'nạp tiền', 'nhận tiền',
    ];
    
    final outgoingKeywords = [
      'sent', 'debited', 'withdrawn', 'outgoing',
      'debit', 'out', 'paid', 'payment', 'withdraw',
      '-', 'minus', 'deducted', 'fee', 'trừ', 'thanh toán', 
      'rút', 'chuyển đi',
    ];
    
    final lowerText = text.toLowerCase();
    
    // Check for incoming keywords
    for (final keyword in incomingKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        return TransactionDirection.incoming;
      }
    }
    
    // Check for outgoing keywords
    for (final keyword in outgoingKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        return TransactionDirection.outgoing;
      }
    }
    
    // Default to outgoing if no match
    return TransactionDirection.outgoing;
  }
  
  /// Extract description from text
  static String _extractDescription(String text) {
    // Try to extract payer/payee name and purpose
    final nameRegex = RegExp(r'(from|to|by|for|ref)\s+([A-Za-z0-9\s]+)', caseSensitive: false);
    final match = nameRegex.firstMatch(text);
    
    if (match != null && match.group(2) != null) {
      return match.group(2)!.trim();
    }
    
    // Fall back to first 50 chars if no specific description found
    if (text.length > 50) {
      return text.substring(0, 50) + '...';
    }
    
    return text;
  }
}