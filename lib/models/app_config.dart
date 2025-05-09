import 'dart:convert';

/// Model class for application configuration
class AppConfig {
  bool isGoogleSheetsConfigured = false;

  final bool isServiceRunning;
  final bool enableSmsMonitoring;
  final bool enableNotificationMonitoring;
  final List<String> selectedAppPackages;
  final String googleSheetId;
  final String googleSheetTabName;

  /// Constructor for AppConfig
  AppConfig({
    required this.isServiceRunning,
    required this.enableSmsMonitoring,
    required this.enableNotificationMonitoring,
    required this.selectedAppPackages,
    required this.googleSheetId,
    required this.googleSheetTabName,
  });

  /// Create an empty configuration with default values
  factory AppConfig.empty() {
    return AppConfig(
      isServiceRunning: false,
      enableSmsMonitoring: true,
      enableNotificationMonitoring: true,
      selectedAppPackages: [],
      googleSheetId: '',
      googleSheetTabName: 'Transactions',
    );
  }

  /// Create a copy of the current configuration with updated values
  AppConfig copyWith({
    bool? isServiceRunning,
    bool? enableSmsMonitoring,
    bool? enableNotificationMonitoring,
    List<String>? selectedAppPackages,
    String? googleSheetId,
    String? googleSheetTabName,
  }) {
    return AppConfig(
      isServiceRunning: isServiceRunning ?? this.isServiceRunning,
      enableSmsMonitoring: enableSmsMonitoring ?? this.enableSmsMonitoring,
      enableNotificationMonitoring:
          enableNotificationMonitoring ?? this.enableNotificationMonitoring,
      selectedAppPackages: selectedAppPackages ?? this.selectedAppPackages,
      googleSheetId: googleSheetId ?? this.googleSheetId,
      googleSheetTabName: googleSheetTabName ?? this.googleSheetTabName,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'isServiceRunning': isServiceRunning,
      'enableSmsMonitoring': enableSmsMonitoring,
      'enableNotificationMonitoring': enableNotificationMonitoring,
      'selectedAppPackages': selectedAppPackages,
      'googleSheetId': googleSheetId,
      'googleSheetTabName': googleSheetTabName,
    };
  }

  /// Serialize to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON map
  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      isServiceRunning: json['isServiceRunning'] as bool,
      enableSmsMonitoring: json['enableSmsMonitoring'] as bool,
      enableNotificationMonitoring:
          json['enableNotificationMonitoring'] as bool,
      selectedAppPackages: (json['selectedAppPackages'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      googleSheetId: json['googleSheetId'] as String,
      googleSheetTabName: json['googleSheetTabName'] as String,
    );
  }

  /// Create from JSON string
  factory AppConfig.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return AppConfig.fromJson(json);
  }
}
