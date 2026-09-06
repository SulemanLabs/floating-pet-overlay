package com.sulemanlabs.floatingstreak

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat

/**
 * Builds the persistent notification a foreground service is required to
 * show (Section 19). minSdk is 26, so every supported device has
 * notification channels — no legacy pre-channel branch needed.
 */
object OverlayNotificationFactory {
    const val CHANNEL_ID = "floating_pet_overlay_channel"
    const val NOTIFICATION_ID = 1001

    private const val REQUEST_CODE_OPEN = 100
    private const val REQUEST_CODE_STOP = 101

    fun ensureChannel(context: Context) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(CHANNEL_ID, "Floating Pet", NotificationManager.IMPORTANCE_LOW).apply {
            description = "Shows while your floating pet is active on screen"
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    fun build(context: Context): Notification {
        ensureChannel(context)

        val contentPendingIntent = OverlayService.launchAppIntent(context)?.let {
            PendingIntent.getActivity(context, REQUEST_CODE_OPEN, it, pendingIntentFlags())
        }

        val stopIntent = Intent(context, OverlayService::class.java).apply { action = OverlayService.ACTION_STOP }
        val stopPendingIntent = PendingIntent.getService(context, REQUEST_CODE_STOP, stopIntent, pendingIntentFlags())

        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Floating Pet is active")
            .setContentText("Your pet is currently floating on screen")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(contentPendingIntent)
            .addAction(0, "Stop", stopPendingIntent)
            .build()
    }

    // Immutable: neither PendingIntent needs to be filled in with extra data
    // by the receiving component, so there's no reason to allow mutation.
    private fun pendingIntentFlags(): Int = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
}
