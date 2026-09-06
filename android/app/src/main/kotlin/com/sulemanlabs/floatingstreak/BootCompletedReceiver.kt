package com.sulemanlabs.floatingstreak

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Settings

/**
 * Restarts the overlay after a reboot when the user enabled "Start
 * automatically" in Settings — with no Flutter engine running yet, this
 * reads pet/settings straight out of [OverlayPrefs] instead.
 *
 * Starting a foreground service from a `BOOT_COMPLETED` receiver is one of
 * the documented exemptions to Android's background-start restrictions, but
 * it still must go through [Context.startForegroundService] rather than
 * [Context.startService].
 */
class BootCompletedReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        val prefs = OverlayPrefs(context)
        val snapshot = prefs.readSettings()
        if (!snapshot.autoStartEnabled) return
        if (!Settings.canDrawOverlays(context)) return

        val serviceIntent = Intent(context, OverlayService::class.java).apply {
            putExtra(OverlayService.EXTRA_PET_TYPE, snapshot.petType)
            putExtra(OverlayService.EXTRA_PET_EMOJI, snapshot.petEmoji)
            putExtra(OverlayService.EXTRA_PET_ASSET_PATH, snapshot.petAssetPath)
            putExtra(OverlayService.EXTRA_SIZE, snapshot.sizePercent)
            putExtra(OverlayService.EXTRA_OPACITY, snapshot.opacity)
            putExtra(OverlayService.EXTRA_SPEED, snapshot.speed)
            putExtra(OverlayService.EXTRA_MOVEMENT_ENABLED, snapshot.movementEnabled)
        }
        context.startForegroundService(serviceIntent)
    }
}
