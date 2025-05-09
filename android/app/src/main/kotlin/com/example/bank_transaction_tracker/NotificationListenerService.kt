package com.example.bank_transaction_tracker

import android.app.Notification
import android.content.Intent
import android.os.IBinder
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class BankNotificationListenerService : NotificationListenerService() {
    private val TAG = "BankNotificationListener"
    
    override fun onBind(intent: Intent?): IBinder? {
        return super.onBind(intent)
    }
    
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            processNotification(sbn)
        } catch (e: Exception) {
            Log.e(TAG, "Error processing notification: ${e.message}")
        }
    }
    
    private fun processNotification(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        val notification = sbn.notification
        
        // Extract notification text
        val extras = notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        
        // Broadcast to Flutter
        val intent = Intent("com.example.bank_transaction_tracker.NOTIFICATION")
        intent.putExtra("package_name", packageName)
        intent.putExtra("title", title)
        intent.putExtra("text", text)
        intent.putExtra("timestamp", sbn.postTime)
        
        sendBroadcast(intent)
        
        Log.d(TAG, "Notification from $packageName: $title - $text")
    }
}
