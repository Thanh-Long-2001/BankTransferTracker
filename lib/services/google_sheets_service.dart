import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;

import '../models/transaction.dart';

class GoogleSheetsService {
  // OAuth scopes required for Google Sheets API
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/spreadsheets',
    'https://www.googleapis.com/auth/drive.file',
  ];
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
  );
  
  GoogleSignInAccount? _currentUser;
  sheets.SheetsApi? _sheetsApi;
  
  // Get the currently authenticated user
  GoogleSignInAccount? get currentUser => _currentUser;
  
  // Check if user is signed in
  bool get isSignedIn => _currentUser != null;
  
  // Initialize the service
  Future<bool> initialize() async {
    try {
      // Try silent sign-in first
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        await _initSheetsApi();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error initializing Google Sheets service: $e');
      return false;
    }
  }
  
  // Sign in with Google
  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        await _initSheetsApi();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return false;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _sheetsApi = null;
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
  
  // Initialize Sheets API with authentication
  Future<void> _initSheetsApi() async {
    if (_currentUser == null) {
      throw Exception('User not signed in');
    }
    
    final authHeaders = await _currentUser!.authHeaders;
    final httpClient = _GoogleAuthClient(authHeaders);
    _sheetsApi = sheets.SheetsApi(httpClient);
  }
  
  // Get list of user's spreadsheets
  Future<List<Map<String, String>>> getUserSpreadsheets() async {
    if (_sheetsApi == null) {
      await _initSheetsApi();
    }
    
    try {
      final response = await _sheetsApi!.spreadsheets.list();
      final spreadsheets = response.files ?? [];
      
      return spreadsheets.map((spreadsheet) {
        return {
          'id': spreadsheet.id ?? '',
          'name': spreadsheet.name ?? 'Unnamed Spreadsheet',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting user spreadsheets: $e');
      return [];
    }
  }
  
  // Get sheet names in a spreadsheet
  Future<List<String>> getSpreadsheetSheets(String spreadsheetId) async {
    if (_sheetsApi == null) {
      await _initSheetsApi();
    }
    
    try {
      final response = await _sheetsApi!.spreadsheets.get(spreadsheetId);
      final sheets = response.sheets ?? [];
      
      return sheets
          .map((sheet) => sheet.properties?.title ?? '')
          .where((title) => title.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error getting spreadsheet sheets: $e');
      return [];
    }
  }
  
  // Create a new sheet in a spreadsheet if it doesn't exist
  Future<bool> ensureSheetExists(String spreadsheetId, String sheetName) async {
    if (_sheetsApi == null) {
      await _initSheetsApi();
    }
    
    try {
      // Check if sheet already exists
      final sheetsList = await getSpreadsheetSheets(spreadsheetId);
      if (sheetsList.contains(sheetName)) {
        return true;
      }
      
      // Create new sheet
      final request = sheets.BatchUpdateSpreadsheetRequest(
        requests: [
          sheets.Request(
            addSheet: sheets.AddSheetRequest(
              properties: sheets.SheetProperties(
                title: sheetName,
              ),
            ),
          ),
        ],
      );
      
      await _sheetsApi!.spreadsheets.batchUpdate(request, spreadsheetId);
      
      // Add header row
      await _sheetsApi!.spreadsheets.values.update(
        sheets.ValueRange(
          values: [
            [
              'Date & Time',
              'Sender / Bank',
              'Amount',
              'Message Content',
              'Source',
              'Direction',
            ],
          ],
        ),
        spreadsheetId,
        '$sheetName!A1:F1',
        valueInputOption: 'RAW',
      );
      
      return true;
    } catch (e) {
      debugPrint('Error ensuring sheet exists: $e');
      return false;
    }
  }
  
  // Append transaction to Google Sheet
  Future<bool> appendTransaction(
    String spreadsheetId,
    String sheetName,
    Transaction transaction,
  ) async {
    if (_sheetsApi == null) {
      await _initSheetsApi();
    }
    
    try {
      // Make sure sheet exists
      final sheetExists = await ensureSheetExists(spreadsheetId, sheetName);
      if (!sheetExists) {
        return false;
      }
      
      // Append row
      final rowData = transaction.toGoogleSheetsRow();
      await _sheetsApi!.spreadsheets.values.append(
        sheets.ValueRange(
          values: [rowData],
        ),
        spreadsheetId,
        '$sheetName!A:F',
        valueInputOption: 'USER_ENTERED',
        insertDataOption: 'INSERT_ROWS',
      );
      
      return true;
    } catch (e) {
      debugPrint('Error appending transaction: $e');
      return false;
    }
  }
  
  // Append multiple transactions in batch
  Future<bool> appendTransactionsBatch(
    String spreadsheetId,
    String sheetName,
    List<Transaction> transactions,
  ) async {
    if (transactions.isEmpty) {
      return true;
    }
    
    if (_sheetsApi == null) {
      await _initSheetsApi();
    }
    
    try {
      // Make sure sheet exists
      final sheetExists = await ensureSheetExists(spreadsheetId, sheetName);
      if (!sheetExists) {
        return false;
      }
      
      // Prepare batch data
      final rowsData = transactions.map((t) => t.toGoogleSheetsRow()).toList();
      
      // Append rows
      await _sheetsApi!.spreadsheets.values.append(
        sheets.ValueRange(
          values: rowsData,
        ),
        spreadsheetId,
        '$sheetName!A:F',
        valueInputOption: 'USER_ENTERED',
        insertDataOption: 'INSERT_ROWS',
      );
      
      return true;
    } catch (e) {
      debugPrint('Error appending transactions batch: $e');
      return false;
    }
  }
  
  // Check for duplicate transactions
  Future<bool> isDuplicate(
    String spreadsheetId,
    String sheetName,
    Transaction transaction,
  ) async {
    if (_sheetsApi == null) {
      await _initSheetsApi();
    }
    
    try {
      // Get last 50 rows
      final response = await _sheetsApi!.spreadsheets.values.get(
        spreadsheetId,
        '$sheetName!A:F',
        valueRenderOption: 'FORMATTED_VALUE',
      );
      
      final rows = response.values ?? [];
      if (rows.length <= 1) {
        // Only header or empty, not a duplicate
        return false;
      }
      
      // Skip header row
      final dataRows = rows.skip(1);
      
      // Check if any row matches our transaction (date, amount, description)
      final rowData = transaction.toGoogleSheetsRow();
      for (var row in dataRows) {
        if (row.length >= 4 &&
            row[0].toString().contains(rowData[0]) && // Date (partial match)
            row[2] == rowData[2] && // Amount (exact match)
            row[3] == rowData[3]) { // Description (exact match)
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking for duplicate: $e');
      // If we can't check, assume not duplicate
      return false;
    }
  }
  
  // Create a new spreadsheet
  Future<Map<String, String>?> createSpreadsheet(String title) async {
    if (_sheetsApi == null) {
      await _initSheetsApi();
    }
    
    try {
      final newSheet = sheets.Spreadsheet(
        properties: sheets.SpreadsheetProperties(
          title: title,
        ),
        sheets: [
          sheets.Sheet(
            properties: sheets.SheetProperties(
              title: 'Transactions',
            ),
          ),
        ],
      );
      
      final response = await _sheetsApi!.spreadsheets.create(newSheet);
      
      // Add header row
      await _sheetsApi!.spreadsheets.values.update(
        sheets.ValueRange(
          values: [
            [
              'Date & Time',
              'Sender / Bank',
              'Amount',
              'Message Content',
              'Source',
              'Direction',
            ],
          ],
        ),
        response.spreadsheetId!,
        'Transactions!A1:F1',
        valueInputOption: 'RAW',
      );
      
      return {
        'id': response.spreadsheetId!,
        'name': title,
      };
    } catch (e) {
      debugPrint('Error creating spreadsheet: $e');
      return null;
    }
  }
}

// Helper class for Google authentication
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  
  _GoogleAuthClient(this._headers);
  
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
