package com.sulemanlabs.floatingstreak

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.os.IBinder

/**
 * Owns the floating window's actual lifecycle. Deliberately does not depend
 * on `MainActivity` staying alive — `MainActivity` only sends it commands
 * and forwards its events (via [OverlayEventBridge]); the overlay itself
 * keeps running if the user backgrounds or kills the Flutter UI, which is
 * the whole point of a foreground service here (Section 24).
 *
 * `START_STICKY`: if the system kills this service under memory pressure,
 * Android restarts it with a null Intent. In that case there are no extras
 * to read pet/settings from, so [onStartCommand] falls back to
 * [OverlayPrefs] — the same native mirror [MainActivity.syncSettings] keeps
 * fresh on every settings change — instead of hardcoded defaults.
 */
class OverlayService : Service() {

    private lateinit var prefs: OverlayPrefs
    private lateinit var windowManager: OverlayWindowManager

    override fun onCreate() {
        super.onCreate()
        prefs = OverlayPrefs(this)
        windowManager = OverlayWindowManager(this, prefs).apply {
            onTap = {
                OverlayEventBridge.listener?.onPetTapped()
                launchApp()
            }
            onDoubleTap = { OverlayEventBridge.listener?.onPetDoubleTapped() }
            onError = { message ->
                OverlayEventBridge.listener?.onOverlayError(message)
                stopSelfSafely()
            }
            // Non-fatal: one pet's asset failed to decode; the overlay stays up on the emoji fallback.
            onAssetError = { message -> OverlayEventBridge.listener?.onOverlayError(message) }
        }
        instance = this
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelfSafely()
            return START_NOT_STICKY
        }

        val extras = intent?.extras
        val snapshot = if (extras != null) {
            OverlayPrefsSnapshot(
                petType = extras.getString(EXTRA_PET_TYPE) ?: OverlayPrefs.DEFAULT_PET_TYPE,
                petEmoji = extras.getString(EXTRA_PET_EMOJI) ?: OverlayPrefs.DEFAULT_PET_EMOJI,
                petAssetPath = extras.getString(EXTRA_PET_ASSET_PATH),
                sizePercent = extras.getFloat(EXTRA_SIZE, 1.0f),
                opacity = extras.getFloat(EXTRA_OPACITY, 1.0f),
                speed = extras.getFloat(EXTRA_SPEED, 0.5f),
                movementEnabled = extras.getBoolean(EXTRA_MOVEMENT_ENABLED, true),
                autoStartEnabled = prefs.readSettings().autoStartEnabled,
            )
        } else {
            prefs.readSettings()
        }
        prefs.writeSettings(snapshot)

        startForeground(OverlayNotificationFactory.NOTIFICATION_ID, OverlayNotificationFactory.build(this))

        if (!windowManager.isShowing) {
            windowManager.show(
                petType = snapshot.petType,
                petEmoji = snapshot.petEmoji,
                petAssetPath = snapshot.petAssetPath,
                sizePercent = snapshot.sizePercent,
                opacity = snapshot.opacity,
                speed = snapshot.speed,
                movementEnabled = snapshot.movementEnabled,
                nextDeadlineMillis = prefs.readNextDeadline(),
                streakSnapshot = prefs.readStreak()?.toStreakSnapshot(),
            )
            OverlayEventBridge.listener?.onOverlayStarted()
        }

        return START_STICKY
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        windowManager.onScreenSizeChanged()
    }

    override fun onDestroy() {
        windowManager.hide()
        instance = null
        OverlayEventBridge.listener?.onOverlayStopped()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // Called directly by MainActivity while this instance is alive, so a
    // slider drag doesn't round-trip through a service restart — see the
    // `instance` companion property.
    fun updatePet(petType: String, petEmoji: String?, petAssetPath: String?) =
        windowManager.updatePet(petType, petEmoji, petAssetPath)

    fun updateSize(sizePercent: Float) = windowManager.updateSize(sizePercent)

    fun updateOpacity(opacity: Float) = windowManager.updateOpacity(opacity)

    fun updateSpeed(speed: Float) = windowManager.updateSpeed(speed)

    fun setMovementEnabled(enabled: Boolean) = windowManager.setMovementEnabled(enabled)

    fun updateNextDeadline(millis: Long?) = windowManager.updateNextDeadline(millis)

    fun updateStreak(snapshot: StreakSnapshot?) = windowManager.updateStreak(snapshot)

    /** Tap-to-open: brings the Flutter UI to the foreground, same as tapping the persistent notification. */
    private fun launchApp() {
        val intent = launchAppIntent(this) ?: return
        startActivity(intent)
    }

    private fun stopSelfSafely() {
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    companion object {
        const val ACTION_STOP = "com.sulemanlabs.floatingstreak.action.STOP"

        /**
         * Brings [MainActivity] to the foreground from outside any Activity
         * context — shared by [launchApp] (tap-to-open) and
         * [OverlayNotificationFactory] (the notification's content intent),
         * so both agree on exactly how the app gets reopened.
         */
        fun launchAppIntent(context: Context): Intent? {
            return context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
        }

        const val EXTRA_PET_TYPE = "extra_pet_type"
        const val EXTRA_PET_EMOJI = "extra_pet_emoji"
        const val EXTRA_PET_ASSET_PATH = "extra_pet_asset_path"
        const val EXTRA_SIZE = "extra_size"
        const val EXTRA_OPACITY = "extra_opacity"
        const val EXTRA_SPEED = "extra_speed"
        const val EXTRA_MOVEMENT_ENABLED = "extra_movement_enabled"

        // Same-process reference so MainActivity can push live setting updates
        // without an AIDL/bound-service round trip. Never held by anything
        // that outlives the service itself, so it can't leak the service.
        @Volatile
        var instance: OverlayService? = null
            private set

        val isRunning: Boolean get() = instance != null
    }
}
