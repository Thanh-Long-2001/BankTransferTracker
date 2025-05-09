import 'dart:convert';

class AppConfig {
  // List of selected app packages to monitor notifications from
  final List<String> selectedAppPackages;
  
  // Google Sheets configuration
  final String? googleSheetId;
  final String? googleSheetTabName;
  
  // Service status
  final bool isServiceRunning;
  
  // SMS monitoring
  final bool enableSmsMonitoring;
  
  // Notification monitoring
  final bool enableNotificationMonitoring;
  
  AppConfig({
    this.selectedAppPackages = const [],
    this.googleSheetId,
    this.googleSheetTabName,
    this.isServiceRunning = false,
    this.enableSmsMonitoring = true,
    this.enableNotificationMonitoring = true,
  });
  
  // Create a copy with modifications
  AppConfig copyWith({
    List<String>? selectedAppPackages,
    String? googleSheetId,
    String? googleSheetTabName,
    bool? isServiceRunning,
    bool? enableSmsMonitoring,
    bool? enableNotificationMonitoring,
  }) {
    return AppConfig(
      selectedAppPackages: selectedAppPackages ?? this.selectedAppPackages,
      googleSheetId: googleSheetId ?? this.googleSheetId,
      googleSheetTabName: googleSheetTabName ?? this.googleSheetTabName,
      isServiceRunning: isServiceRunning ?? this.isServiceRunning,
      enableSmsMonitoring: enableSmsMonitoring ?? this.enableSmsMonitoring,
      enableNotificationMonitoring: enableNotificationMonitoring ?? this.enableNotificationMonitoring,
    );
  }
  
  // Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'selectedAppPackages': selectedAppPackages,
      'googleSheetId': googleSheetId,
      'googleSheetTabName': googleSheetTabName,
      'isServiceRunning': isServiceRunning,
      'enableSmsMonitoring': enableSmsMonitoring,
      'enableNotificationMonitoring': enableNotificationMonitoring,
    };
  }
  
  // Deserialize from JSON
  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      selectedAppPackages: List<String>.from(json['selectedAppPackages'] ?? []),
      googleSheetId: json['googleSheetId'],
      googleSheetTabName: json['googleSheetTabName'],
      isServiceRunning: json['isServiceRunning'] ?? false,
      enableSmsMonitoring: json['enableSmsMonitoring'] ?? true,
      enableNotificationMonitoring: json['enableNotificationMonitoring'] ?? true,
    );
  }
  
  // Convert to string for storage
  String toJsonString() {
    return jsonEncode(toJson());
  }
  
  // Create from string from storage
  factory AppConfig.fromJsonString(String jsonString) {
    return AppConfig.fromJson(jsonDecode(jsonString));
  }
  
  // Default empty config
  factory AppConfig.empty() {
    return AppConfig();
  }
  
  // Check if Google Sheets is configured
  bool get isGoogleSheetsConfigured {
    return googleSheetId != null && 
           googleSheetId!.isNotEmpty &&
           googleSheetTabName != null && 
           googleSheetTabName!.isNotEmpty;
  }
  
  // Check if any monitoring is enabled
  bool get hasMonitoringEnabled {
    return enableSmsMonitoring || enableNotificationMonitoring;
  }
}

class MonitoredApp {
  final String packageName;
  final String appName;
  final String? appIcon;
  final bool isSelected;
  
  MonitoredApp({
    required this.packageName,
    required this.appName,
    this.appIcon,
    this.isSelected = false,
  });
  
  MonitoredApp copyWith({
    String? packageName,
    String? appName,
    String? appIcon,
    bool? isSelected,
  }) {
    return MonitoredApp(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      appIcon: appIcon ?? this.appIcon,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
