import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../providers/app_state_provider.dart';
import '../utils/constants.dart';
import '../utils/permission_helper.dart';
import '../widgets/transaction_list_item.dart';
import 'app_selection_screen.dart';
import 'google_sheets_config_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _permissionsChecked = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize app state
    Future.microtask(() async {
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      await provider.initialize();
      
      // Check permissions
      if (!_permissionsChecked) {
        _checkAndRequestPermissions();
      }
    });
  }
  
  // Check and request required permissions
  Future<void> _checkAndRequestPermissions() async {
    if (mounted) {
      final permissionsGranted = await PermissionHelper.checkAndRequestPermissions();
      
      if (!permissionsGranted && mounted) {
        _showPermissionDialog();
      }
      
      setState(() {
        _permissionsChecked = true;
      });
    }
  }
  
  // Show permission dialog
  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'This app needs SMS and notification access permissions to monitor '
          'your bank transactions. Please grant these permissions in the settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              PermissionHelper.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${provider.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      provider.initialize();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          return Column(
            children: [
              _buildStatusCard(provider),
              _buildTransactionStats(provider),
              Expanded(
                child: _buildTransactionsList(provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
  
  // Build the status card at the top
  Widget _buildStatusCard(AppStateProvider provider) {
    final bool isConfigured = provider.appConfig.isGoogleSheetsConfigured;
    final bool isRunning = provider.isServiceRunning;
    
    return Card(
      margin: const EdgeInsets.all(12),
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
                if (isRunning)
                  const Chip(
                    backgroundColor: Colors.green,
                    label: Text(
                      'Active',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                else
                  const Chip(
                    backgroundColor: Colors.red,
                    label: Text(
                      'Inactive',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              'Google Sheets',
              isConfigured ? 'Configured' : 'Not Configured',
              isConfigured ? Icons.check_circle : Icons.error_outline,
              isConfigured ? Colors.green : Colors.orange,
              () => _navigateToGoogleSheetsConfig(),
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
              'Monitored Apps',
              provider.appConfig.selectedAppPackages.isNotEmpty
                  ? '${provider.appConfig.selectedAppPackages.length} apps'
                  : 'Not configured',
              provider.appConfig.selectedAppPackages.isNotEmpty
                  ? Icons.check_circle
                  : Icons.error_outline,
              provider.appConfig.selectedAppPackages.isNotEmpty
                  ? Colors.green
                  : Colors.orange,
              () => _navigateToAppSelection(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isConfigured
                    ? () => _toggleMonitoringService(provider)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRunning ? Colors.red : Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  isRunning ? 'Stop Monitoring' : 'Start Monitoring',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build status row for configuration items
  Widget _buildStatusRow(
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Text(value),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
  
  // Build transaction statistics card
  Widget _buildTransactionStats(AppStateProvider provider) {
    return FutureBuilder<Map<String, dynamic>>(
      future: provider.getTransactionStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 0);
        }
        
        final stats = snapshot.data!;
        final totalCount = stats['totalCount'] as int;
        final incomingAmount = stats['incomingAmount'] as double;
        final outgoingAmount = stats['outgoingAmount'] as double;
        
        final formatter = NumberFormat.currency(symbol: '\$');
        
        if (totalCount == 0) {
          return const SizedBox(height: 0);
        }
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  'Total Transactions',
                  totalCount.toString(),
                  Colors.blue,
                ),
                _buildStatColumn(
                  'Income',
                  formatter.format(incomingAmount),
                  Colors.green,
                ),
                _buildStatColumn(
                  'Expenses',
                  formatter.format(outgoingAmount),
                  Colors.red,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Build statistics column
  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  // Build transactions list
  Widget _buildTransactionsList(AppStateProvider provider) {
    final transactions = provider.recentTransactions;
    
    if (transactions.isEmpty) {
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
    
    // Group transactions by date
    final Map<String, List<Transaction>> groupedTransactions = {};
    
    for (final transaction in transactions) {
      final dateStr = DateFormat('yyyy-MM-dd').format(transaction.timestamp);
      if (!groupedTransactions.containsKey(dateStr)) {
        groupedTransactions[dateStr] = [];
      }
      groupedTransactions[dateStr]!.add(transaction);
    }
    
    // Sort dates in descending order
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dateTransactions = groupedTransactions[date]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                _formatDateHeader(date),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            ...dateTransactions.map((transaction) {
              return TransactionListItem(transaction: transaction);
            }).toList(),
          ],
        );
      },
    );
  }
  
  // Format date header
  String _formatDateHeader(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    
    if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Yesterday';
    }
    
    return DateFormat('EEEE, MMMM d, y').format(date);
  }
  
  // Build floating action button
  Widget _buildFloatingActionButton() {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        final isConfigured = provider.appConfig.isGoogleSheetsConfigured;
        final isRunning = provider.isServiceRunning;
        
        if (!isConfigured) {
          return FloatingActionButton.extended(
            onPressed: () => _navigateToGoogleSheetsConfig(),
            label: const Text('Setup Google Sheets'),
            icon: const Icon(Icons.add),
            backgroundColor: ColorConstants.accentColor,
          );
        }
        
        if (!isRunning) {
          return FloatingActionButton.extended(
            onPressed: () => _toggleMonitoringService(provider),
            label: const Text('Start Monitoring'),
            icon: const Icon(Icons.play_arrow),
            backgroundColor: Colors.green,
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }
  
  // Navigate to Google Sheets configuration screen
  void _navigateToGoogleSheetsConfig() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GoogleSheetsConfigScreen()),
    );
  }
  
  // Navigate to app selection screen
  void _navigateToAppSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AppSelectionScreen()),
    );
  }
  
  // Toggle monitoring service
  Future<void> _toggleMonitoringService(AppStateProvider provider) async {
    if (provider.isServiceRunning) {
      await provider.stopMonitoringService();
    } else {
      final permissionsGranted = await PermissionHelper.checkAndRequestPermissions();
      
      if (!permissionsGranted) {
        if (mounted) {
          _showPermissionDialog();
        }
        return;
      }
      
      await provider.startMonitoringService();
    }
  }
}
