// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_state_provider.dart';
import '../utils/constants.dart';
import '../utils/permission_helper.dart';
import 'app_selection_screen.dart';
import 'google_sheets_config_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionHeader('Monitoring Settings'),
                  _buildMonitoringSettingsCard(provider),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Google Sheets Integration'),
                  _buildGoogleSheetsCard(provider),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Permissions'),
                  _buildPermissionsCard(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Data Management'),
                  _buildDataManagementCard(provider),
                  const SizedBox(height: 24),
                  _buildSectionHeader('About'),
                  _buildAboutCard(),
                ],
              ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: ColorConstants.primaryColor,
        ),
      ),
    );
  }

  Widget _buildMonitoringSettingsCard(AppStateProvider provider) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('SMS Monitoring'),
            subtitle: const Text('Listen to bank transaction SMS messages'),
            value: provider.appConfig.enableSmsMonitoring,
            onChanged: (value) async {
              _setLoading(true);
              await provider.updateSmsMonitoring(value);
              _setLoading(false);
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Notification Monitoring'),
            subtitle: const Text('Listen to bank app notifications'),
            value: provider.appConfig.enableNotificationMonitoring,
            onChanged: (value) async {
              _setLoading(true);
              await provider.updateNotificationMonitoring(value);
              _setLoading(false);
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Select Banking Apps'),
            subtitle: Text(
              provider.appConfig.selectedAppPackages.isEmpty
                  ? 'No apps selected'
                  : '${provider.appConfig.selectedAppPackages.length} apps selected',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AppSelectionScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSheetsCard(AppStateProvider provider) {
    final isConfigured = provider.appConfig.isGoogleSheetsConfigured;

    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('Google Sheets Configuration'),
            subtitle: Text(
              isConfigured
                  ? 'Sheet ID: ${_truncateText(provider.appConfig.googleSheetId ?? "", 20)}\n'
                      'Tab: ${provider.appConfig.googleSheetTabName ?? ""}'
                  : 'Not configured',
            ),
            leading: Icon(
              Icons.cloud,
              color: isConfigured ? Colors.green : Colors.grey,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const GoogleSheetsConfigScreen()),
              );
            },
          ),
          if (isConfigured) ...[
            const Divider(),
            ListTile(
              title: const Text('Google Account'),
              subtitle: Text(
                provider.isGoogleSignedIn ? 'Signed in' : 'Not signed in',
              ),
              leading: Icon(
                Icons.account_circle,
                color: provider.isGoogleSignedIn ? Colors.green : Colors.grey,
              ),
              trailing: provider.isGoogleSignedIn
                  ? TextButton(
                      onPressed: () async {
                        _setLoading(true);
                        await provider.signOutFromGoogle();
                        _setLoading(false);
                      },
                      child: const Text('Sign Out'),
                    )
                  : TextButton(
                      onPressed: () async {
                        _setLoading(true);
                        await provider.signInWithGoogle();
                        _setLoading(false);
                      },
                      child: const Text('Sign In'),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionsCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('SMS Permissions'),
            subtitle: const Text('Required to read bank SMS messages'),
            trailing: TextButton(
              onPressed: () async {
                final granted =
                    await PermissionHelper.checkAndRequestSmsPermissions();
                if (!granted && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'SMS permissions are required for monitoring bank messages.'),
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              },
              child: const Text('Check'),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Notification Permissions'),
            subtitle: const Text('Required to read banking app notifications'),
            trailing: TextButton(
              onPressed: () async {
                final granted = await PermissionHelper
                    .checkAndRequestNotificationPermissions();
                if (!granted && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Notification access is required for monitoring bank apps.'),
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              },
              child: const Text('Check'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementCard(AppStateProvider provider) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('Export Transactions'),
            subtitle: const Text('Export your transactions as CSV'),
            leading: const Icon(Icons.file_download),
            onTap: () async {
              _setLoading(true);

              try {
                final transactions = await provider.getAllTransactions();
                if (transactions.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No transactions to export'),
                      ),
                    );
                  }
                  _setLoading(false);
                  return;
                }

                // Create CSV content
                final csvContent = StringBuffer();
                csvContent.writeln(
                    '"Date & Time","Sender/Bank","Amount","Description","Source","Direction"');

                for (final transaction in transactions) {
                  final row = transaction
                      .toGoogleSheetsRow()
                      .map((cell) => '"${cell.replaceAll('"', '""')}"')
                      .join(',');
                  csvContent.writeln(row);
                }

                // Share the CSV content
                await Share.share(
                  csvContent.toString(),
                  subject: 'Bank Transaction Export',
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error exporting transactions: $e'),
                    ),
                  );
                }
              }

              _setLoading(false);
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Clear Local Data'),
            subtitle: const Text('Delete all stored transactions'),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Data?'),
                  content: const Text(
                    'This will delete all locally stored transactions. '
                    'This action cannot be undone. Data already synced to '
                    'Google Sheets will not be affected.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        _setLoading(true);

                        try {
                          await provider.clearAllTransactions();
                          await provider.reloadRecentTransactions();

                          if (mounted) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All transaction data cleared'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error clearing data: $e'),
                              ),
                            );
                          }
                        }

                        _setLoading(false);
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete All'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return const Card(
      child: Column(
        children: [
          ListTile(
            title: Text('Bank Transaction Tracker'),
            subtitle: Text('Version 1.0.0'),
            leading: Icon(Icons.info_outline),
          ),
          Divider(),
          ListTile(
            title: Text('How to Use'),
            subtitle: Text(
              '1. Configure Google Sheets\n'
              '2. Select banking apps to monitor\n'
              '3. Start monitoring service\n'
              '4. Transactions will be logged automatically',
            ),
          ),
        ],
      ),
    );
  }

  void _setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }
}
