import 'package:bank_transaction_tracker/models/monitored_app.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_config.dart';
import '../providers/app_state_provider.dart';
import '../utils/constants.dart';

class AppSelectionScreen extends StatefulWidget {
  const AppSelectionScreen({Key? key}) : super(key: key);

  @override
  State<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends State<AppSelectionScreen> {
  List<MonitoredApp> _apps = [];
  List<String> _selectedPackages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadApps();
  }

  // Load apps that can be monitored
  Future<void> _loadApps() async {
    final provider = Provider.of<AppStateProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    // Load installed apps
    await provider.loadInstalledApps();

    // Load the current selection
    _selectedPackages = List.from(provider.appConfig.selectedAppPackages);

    setState(() {
      _apps = provider.availableApps;
      _isLoading = false;
    });
  }

  // Save selected apps
  Future<void> _saveSelection() async {
    final provider = Provider.of<AppStateProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    await provider.updateMonitoredApps(_selectedPackages);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Banking Apps'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Select the banking and payment apps you want to monitor for transaction notifications:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  child: _apps.isEmpty
                      ? const Center(
                          child: Text(
                            'No banking apps found.\nMake sure you have banking apps installed.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _apps.length,
                          itemBuilder: (context, index) {
                            final app = _apps[index];
                            final isSelected =
                                _selectedPackages.contains(app.packageName);

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: ColorConstants.primaryColor
                                    .withOpacity(0.1),
                                child: Icon(
                                  Icons.account_balance,
                                  color: ColorConstants.primaryColor,
                                ),
                              ),
                              title: Text(app.appName),
                              subtitle: Text(app.packageName),
                              trailing: Checkbox(
                                value: isSelected,
                                activeColor: ColorConstants.accentColor,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedPackages.add(app.packageName);
                                    } else {
                                      _selectedPackages.remove(app.packageName);
                                    }
                                  });
                                },
                              ),
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedPackages.remove(app.packageName);
                                  } else {
                                    _selectedPackages.add(app.packageName);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _saveSelection,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Save Selection',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
