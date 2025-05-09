import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../utils/constants.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionListItem({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildLeadingIcon(),
        title: _buildTitle(),
        subtitle: _buildSubtitle(),
        trailing: _buildAmount(),
        onTap: () => _showTransactionDetails(context),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    Color bgColor;
    IconData iconData;

    // Set icon based on transaction direction
    if (transaction.direction == TransactionDirection.incoming) {
      bgColor = Colors.green.withOpacity(0.2);
      iconData = Icons.arrow_downward;
    } else if (transaction.direction == TransactionDirection.outgoing) {
      bgColor = Colors.red.withOpacity(0.2);
      iconData = Icons.arrow_upward;
    } else {
      bgColor = Colors.grey.withOpacity(0.2);
      iconData = Icons.swap_horiz;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: transaction.direction == TransactionDirection.incoming
            ? Colors.green
            : transaction.direction == TransactionDirection.outgoing
                ? Colors.red
                : Colors.grey,
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            transaction.bank,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatTime(transaction.timestamp as DateTime),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          transaction.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              transaction.source == TransactionSource.sms
                  ? Icons.sms
                  : Icons.notifications,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              transaction.source == TransactionSource.sms
                  ? 'SMS'
                  : 'Notification',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 8),
            if (!transaction.synced)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sync_problem,
                      size: 12,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Not synced',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmount() {
    return Text(
      transaction.formattedAmount,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: transaction.direction == TransactionDirection.incoming
            ? Colors.green[700]
            : transaction.direction == TransactionDirection.outgoing
                ? Colors.red[700]
                : Colors.grey[700],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  void _showTransactionDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _TransactionDetailsSheet(transaction: transaction),
    );
  }
}

class _TransactionDetailsSheet extends StatelessWidget {
  final Transaction transaction;

  const _TransactionDetailsSheet({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaction Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDetailItem(
            context,
            'Amount',
            transaction.formattedAmount,
            valueColor: transaction.direction == TransactionDirection.incoming
                ? Colors.green[700]
                : transaction.direction == TransactionDirection.outgoing
                    ? Colors.red[700]
                    : null,
          ),
          _buildDetailItem(
            context,
            'Bank/Sender',
            transaction.bank,
          ),
          _buildDetailItem(
            context,
            'Date & Time',
            DateFormat('yyyy-MM-dd HH:mm:ss')
                .format(transaction.timestamp as DateTime),
          ),
          _buildDetailItem(
            context,
            'Direction',
            transaction.direction == TransactionDirection.incoming
                ? 'Incoming (Credit)'
                : transaction.direction == TransactionDirection.outgoing
                    ? 'Outgoing (Debit)'
                    : 'Unknown',
          ),
          _buildDetailItem(
            context,
            'Source',
            transaction.source == TransactionSource.sms
                ? 'SMS'
                : 'Notification (${transaction.sourceAppPackage})',
          ),
          _buildDetailItem(
            context,
            'Sync Status',
            transaction.synced ? 'Synced to Google Sheets' : 'Not synced yet',
            valueColor: transaction.synced ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          _buildDetailItem(
            context,
            'Full Message',
            transaction.description,
            isFullWidth: true,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool isFullWidth = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isFullWidth ? FontWeight.normal : FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
