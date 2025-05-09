package com.example.bank_transaction_tracker

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.bank_transaction_tracker/notification_permission"
    private val AUTO_START_CHANNEL = "com.example.bank_transaction_tracker/auto_start"
    private val REQUEST_NOTIFICATION_LISTENER = 1001
    private val TAG = "MainActivity"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Check if app was started from boot receiver
        val fromBootReceiver = intent.getBooleanExtra("FROM_BOOT_RECEIVER", false)
        if (fromBootReceiver) {
            Log.d(TAG, "App started from boot receiver - auto starting monitoring")
            // We'll pass this to Flutter when it's ready
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Notification permission channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "openNotificationListenerSettings" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Unable to open notification listener settings", null)
                    }
                }
                "isNotificationListenerEnabled" -> {
                    val enabled = isNotificationServiceEnabled()
                    result.success(enabled)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Auto start channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUTO_START_CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "wasLaunchedFromBoot" -> {
                    // Let Flutter know if app was launched from boot
                    val fromBootReceiver = intent.getBooleanExtra("FROM_BOOT_RECEIVER", false)
                    result.success(fromBootReceiver)
                    
                    if (fromBootReceiver) {
                        Log.d(TAG, "Informing Flutter that app was launched from boot")
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun isNotificationServiceEnabled(): Boolean {
        val packageName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        return flat?.contains(packageName) ?: false
    }
}
