package com.example.bank_transaction_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * BroadcastReceiver that listens for the BOOT_COMPLETED action and starts the app's services
 * automatically when the device boots up, without requiring user intervention.
 */
class BootReceiver : BroadcastReceiver() {
    private val TAG = "BootReceiver"

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "Device boot completed, starting bank transaction tracker services")
            
            // Start notification listener service (this is system managed but we can make sure it's enabled)
            // In real implementation, we'd check if permission is granted and use settings intent if needed
            
            // Start any background services the app needs
            try {
                // This will start the Flutter engine and load the app
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (launchIntent != null) {
                    // Add flags to start as a new task
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    
                    // We can add extras to indicate boot-time startup 
                    launchIntent.putExtra("FROM_BOOT_RECEIVER", true)
                    
                    // Start the app
                    context.startActivity(launchIntent)
                    Log.d(TAG, "Successfully launched app after boot")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error starting services on boot: ${e.message}")
            }
        }
    }
}