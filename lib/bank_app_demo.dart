import 'package:flutter/material.dart';

void main() {
  runApp(const BankAppDemo());
}

class BankAppDemo extends StatelessWidget {
  const BankAppDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bank Transaction Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isServiceRunning = false;
  List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    // Add some sample transactions
    _loadSampleTransactions();
  }

  void _loadSampleTransactions() {
    _transactions = [
      Transaction(
        id: '1',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        bank: 'VCB Bank',
        amount: 1500000,
        description: 'Received from Nguyen Van A',
        source: 'SMS',
        direction: TransactionDirection.incoming,
      ),
      Transaction(
        id: '2',
        date: DateTime.now().subtract(const Duration(days: 1)),
        bank: 'MB Bank',
        amount: 500000,
        description: 'Payment to Coffee Shop',
        source: 'Notification',
        direction: TransactionDirection.outgoing,
      ),
      Transaction(
        id: '3',
        date: DateTime.now().subtract(const Duration(days: 2)),
        bank: 'Momo',
        amount: 200000,
        description: 'Transfer to Tran Thi B',
        source: 'Notification',
        direction: TransactionDirection.outgoing,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Transaction Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Open settings screen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildTransactionsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _isServiceRunning = !_isServiceRunning;
          });
        },
        icon: Icon(_isServiceRunning ? Icons.stop : Icons.play_arrow),
        label: Text(_isServiceRunning ? 'Stop Monitoring' : 'Start Monitoring'),
        backgroundColor: _isServiceRunning ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monitoring Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  backgroundColor: _isServiceRunning ? Colors.green : Colors.red,
                  label: Text(
                    _isServiceRunning ? 'Active' : 'Inactive',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'This app monitors bank SMS and notifications to automatically log transaction data into Google Sheets.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isServiceRunning
                        ? 'App is actively monitoring for banking transactions'
                        : 'Click Start Monitoring to begin tracking transactions',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start monitoring to capture your banking transactions',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _transactions.length,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return TransactionListItem(transaction: transaction);
      },
    );
  }
}

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionListItem({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildLeadingIcon(),
        title: Text(
          transaction.bank,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(transaction.description),
            const SizedBox(height: 4),
            Text(
              '${transaction.source} • ${_formatDate(transaction.date)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Text(
          _formatAmount(transaction.amount, transaction.direction),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: transaction.direction == TransactionDirection.incoming
                ? Colors.green
                : Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: transaction.direction == TransactionDirection.incoming
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        transaction.direction == TransactionDirection.incoming
            ? Icons.arrow_downward
            : Icons.arrow_upward,
        color: transaction.direction == TransactionDirection.incoming
            ? Colors.green
            : Colors.red,
        size: 20,
      ),
    );
  }

  String _formatAmount(double amount, TransactionDirection direction) {
    final prefix = direction == TransactionDirection.incoming ? '+' : '-';
    return '$prefix${amount.toStringAsFixed(0)} VND';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

enum TransactionDirection {
  incoming,
  outgoing,
}

class Transaction {
  final String id;
  final DateTime date;
  final String bank;
  final double amount;
  final String description;
  final String source;
  final TransactionDirection direction;

  Transaction({
    required this.id,
    required this.date,
    required this.bank,
    required this.amount,
    required this.description,
    required this.source,
    required this.direction,
  });
}