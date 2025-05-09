/// Model class for monitoring banking applications 
class MonitoredApp {
  final String packageName;
  final String appName;
  final bool isSelected;
  
  /// Constructor for MonitoredApp
  MonitoredApp({
    required this.packageName,
    required this.appName,
    required this.isSelected,
  });
  
  /// Create a copy with updated values
  MonitoredApp copyWith({
    String? packageName,
    String? appName,
    bool? isSelected,
  }) {
    return MonitoredApp(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}