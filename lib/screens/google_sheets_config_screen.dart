import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../utils/constants.dart';

class GoogleSheetsConfigScreen extends StatefulWidget {
  const GoogleSheetsConfigScreen({Key? key}) : super(key: key);

  @override
  State<GoogleSheetsConfigScreen> createState() => _GoogleSheetsConfigScreenState();
}

class _GoogleSheetsConfigScreenState extends State<GoogleSheetsConfigScreen> {
  final TextEditingController _sheetIdController = TextEditingController();
  final TextEditingController _sheetTabController = TextEditingController();
  final TextEditingController _newSpreadsheetNameController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSignedIn = false;
  
  String? _selectedSpreadsheetId;
  String? _selectedSheetTab;
  
  List<Map<String, String>> _spreadsheets = [];
  List<String> _sheetTabs = [];
  
  @override
  void initState() {
    super.initState();
    
    _initializeScreen();
  }
  
  @override
  void dispose() {
    _sheetIdController.dispose();
    _sheetTabController.dispose();
    _newSpreadsheetNameController.dispose();
    super.dispose();
  }
  
  // Initialize the screen
  Future<void> _initializeScreen() async {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    // Check if user is signed in
    _isSignedIn = provider.isGoogleSignedIn;
    
    // Load current configuration
    final config = provider.appConfig;
    if (config.googleSheetId != null && config.googleSheetId!.isNotEmpty) {
      _sheetIdController.text = config.googleSheetId!;
      _selectedSpreadsheetId = config.googleSheetId;
    }
    
    if (config.googleSheetTabName != null && config.googleSheetTabName!.isNotEmpty) {
      _sheetTabController.text = config.googleSheetTabName!;
      _selectedSheetTab = config.googleSheetTabName;
    }
    
    // If signed in, load spreadsheets
    if (_isSignedIn) {
      await _loadSpreadsheets();
      
      // If a spreadsheet is selected, load its sheets
      if (_selectedSpreadsheetId != null) {
        await _loadSheets(_selectedSpreadsheetId!);
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  // Load user's spreadsheets
  Future<void> _loadSpreadsheets() async {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    _spreadsheets = await provider.getUserSpreadsheets();
    
    setState(() {
      _isLoading = false;
    });
  }
  
  // Load sheets for selected spreadsheet
  Future<void> _loadSheets(String spreadsheetId) async {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    _sheetTabs = await provider.getSpreadsheetSheets(spreadsheetId);
    
    setState(() {
      _isLoading = false;
    });
  }
  
  // Sign in with Google
  Future<void> _signInWithGoogle() async {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    final success = await provider.signInWithGoogle();
    
    if (success) {
      _isSignedIn = true;
      await _loadSpreadsheets();
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  // Save Google Sheets configuration
  Future<void> _saveConfiguration() async {
    if (_selectedSpreadsheetId == null || _selectedSpreadsheetId!.isEmpty) {
      _showErrorSnackBar('Please select or enter a spreadsheet ID');
      return;
    }
    
    if (_selectedSheetTab == null || _selectedSheetTab!.isEmpty) {
      _showErrorSnackBar('Please select or enter a sheet name');
      return;
    }
    
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    await provider.updateGoogleSheetsConfig(
      sheetId: _selectedSpreadsheetId!,
      sheetTabName: _selectedSheetTab!,
    );
    
    setState(() {
      _isLoading = false;
    });
    
    if (mounted) {
      Navigator.pop(context);
    }
  }
  
  // Create a new spreadsheet
  Future<void> _createNewSpreadsheet() async {
    if (_newSpreadsheetNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a name for the new spreadsheet');
      return;
    }
    
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    final newSheet = await provider.createNewSpreadsheet(
      _newSpreadsheetNameController.text.trim(),
    );
    
    if (newSheet != null) {
      _spreadsheets.add(newSheet);
      _selectedSpreadsheetId = newSheet['id'];
      _sheetIdController.text = newSheet['id']!;
      
      // Load sheets for the new spreadsheet
      await _loadSheets(_selectedSpreadsheetId!);
      
      // Set the default sheet
      if (_sheetTabs.isNotEmpty) {
        _selectedSheetTab = _sheetTabs.first;
        _sheetTabController.text = _selectedSheetTab!;
      }
      
      // Close the dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  // Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Show create new spreadsheet dialog
  void _showCreateSpreadsheetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Spreadsheet'),
        content: TextField(
          controller: _newSpreadsheetNameController,
          decoration: const InputDecoration(
            labelText: 'Spreadsheet Name',
            hintText: 'e.g., My Banking Transactions',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _createNewSpreadsheet();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sheets Configuration'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSignInSection(),
                  if (_isSignedIn) ...[
                    const SizedBox(height: 24),
                    _buildSpreadsheetSection(),
                    const SizedBox(height: 24),
                    _buildSheetTabSection(),
                    const SizedBox(height: 32),
                    _buildManualEntrySection(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveConfiguration,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Save Configuration',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
  
  // Build Google Sign-In section
  Widget _buildSignInSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Google Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _isSignedIn
                ? const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      SizedBox(width: 8),
                      Text('Signed in to Google'),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('Sign in with Google'),
                      onPressed: _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
  
  // Build spreadsheet selection section
  Widget _buildSpreadsheetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select a Google Spreadsheet:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_spreadsheets.isEmpty)
          const Text(
            'No spreadsheets found in your Google Drive',
            style: TextStyle(fontStyle: FontStyle.italic),
          )
        else
          DropdownButtonFormField<String>(
            value: _selectedSpreadsheetId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select a spreadsheet',
            ),
            items: _spreadsheets.map((sheet) {
              return DropdownMenuItem<String>(
                value: sheet['id'],
                child: Text(
                  sheet['name']!,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSpreadsheetId = value;
                _sheetIdController.text = value ?? '';
                _sheetTabs = [];
                _selectedSheetTab = null;
                _sheetTabController.text = '';
              });
              
              if (value != null) {
                _loadSheets(value);
              }
            },
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh List'),
                onPressed: _loadSpreadsheets,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Create New'),
                onPressed: _showCreateSpreadsheetDialog,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Build sheet tab selection section
  Widget _buildSheetTabSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select a Sheet Tab:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedSpreadsheetId == null)
          const Text(
            'Please select a spreadsheet first',
            style: TextStyle(fontStyle: FontStyle.italic),
          )
        else if (_sheetTabs.isEmpty)
          const Text(
            'No sheets found in the selected spreadsheet',
            style: TextStyle(fontStyle: FontStyle.italic),
          )
        else
          DropdownButtonFormField<String>(
            value: _selectedSheetTab,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select a sheet tab',
            ),
            items: _sheetTabs.map((tab) {
              return DropdownMenuItem<String>(
                value: tab,
                child: Text(tab),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSheetTab = value;
                _sheetTabController.text = value ?? '';
              });
            },
          ),
      ],
    );
  }
  
  // Build manual entry section
  Widget _buildManualEntrySection() {
    return ExpansionTile(
      title: const Text('Manual Configuration'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      children: [
        TextField(
          controller: _sheetIdController,
          decoration: const InputDecoration(
            labelText: 'Spreadsheet ID',
            hintText: 'Enter the spreadsheet ID from the URL',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _selectedSpreadsheetId = value;
            });
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _sheetTabController,
          decoration: const InputDecoration(
            labelText: 'Sheet Tab Name',
            hintText: 'e.g., Sheet1 or Transactions',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _selectedSheetTab = value;
            });
          },
        ),
      ],
    );
  }
}
