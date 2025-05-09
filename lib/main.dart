import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'providers/app_state_provider.dart';
import 'screens/home_screen.dart';
import 'services/auto_start_service.dart';
import 'services/background_service.dart';
import 'utils/constants.dart';

// Background task callback, needs to be top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case BackgroundService.backgroundTaskName:
        await BackgroundService.processTransactionsInBackground();
        break;
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize workmanager for background tasks
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );
  
  // Initialize notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');
  
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );
  
  // Check if app was auto-started and show notification
  if (!kIsWeb) {
    try {
      final autoStartService = AutoStartService();
      final wasAutoStarted = await autoStartService.wasLaunchedFromBoot();
      
      if (wasAutoStarted) {
        debugPrint('App was auto-started from device boot');
        
        // Show notification that app has started monitoring
        const AndroidNotificationDetails androidPlatformChannelSpecifics =
            AndroidNotificationDetails(
          'auto_start_channel',
          'Auto Start Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );
        
        const NotificationDetails platformChannelSpecifics =
            NotificationDetails(android: androidPlatformChannelSpecifics);
        
        await flutterLocalNotificationsPlugin.show(
          0,
          'Bank Transaction Tracker Started',
          'App is automatically monitoring for banking transactions',
          platformChannelSpecifics,
        );
      }
    } catch (e) {
      debugPrint('Error handling auto-start: $e');
    }
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppStateProvider(),
      child: MaterialApp(
        title: 'Bank Transaction Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scaffoldBackgroundColor: Colors.grey[100],
          appBarTheme: const AppBarTheme(
            backgroundColor: ColorConstants.primaryColor,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          cardTheme: CardTheme(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
        darkTheme: ThemeData.dark().copyWith(
          primaryColor: ColorConstants.darkPrimaryColor,
          colorScheme: const ColorScheme.dark().copyWith(
            primary: ColorConstants.primaryColorDark,
            secondary: ColorConstants.accentColorDark,
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
          cardTheme: CardTheme(
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
