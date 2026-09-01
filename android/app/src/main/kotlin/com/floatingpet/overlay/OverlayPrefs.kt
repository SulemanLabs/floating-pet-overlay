package com.floatingpet.overlay

import android.content.Context
import android.content.SharedPreferences

/** Mirrors the Dart-side `syncStreak` payload — `mode`/`status` stay raw strings (not the [StreakMode]/[StreakState] enums) so this file doesn't need to know about [StreakTicker]'s types. */
data class StreakPrefsSnapshot(
    val mode: String,
    val status: String,
    val startMillis: Long,
    val endMillis: Long?,
)

data class OverlayPrefsSnapshot(
    val petType: String,
    val petEmoji: String?,
    val petAssetPath: String?,
    val sizePercent: Float,
    val opacity: Float,
    val speed: Float,
    val movementEnabled: Boolean,
    val autoStartEnabled: Boolean,
)

/**
 * Native mirror of the Dart-side settings, plus the last on-screen position.
 *
 * Two things need this that never touch the Flutter engine: [BootCompletedReceiver]
 * (restarts the overlay with no Dart VM running) and [OverlayWindowManager]
 * (persists drag position in real time — round-tripping every drag frame
 * through a MethodChannel would be wasteful). The Dart side stays the source
 * of truth for anything the user edits from a settings screen; this store
 * exists purely so native code has something to read when Dart isn't around.
 */
class OverlayPrefs(context: Context) {

    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun writeSettings(snapshot: OverlayPrefsSnapshot) {
        prefs.edit()
            .putString(KEY_PET_TYPE, snapshot.petType)
            .putString(KEY_PET_EMOJI, snapshot.petEmoji)
            .putString(KEY_PET_ASSET_PATH, snapshot.petAssetPath)
            .putFloat(KEY_SIZE, snapshot.sizePercent)
            .putFloat(KEY_OPACITY, snapshot.opacity)
            .putFloat(KEY_SPEED, snapshot.speed)
            .putBoolean(KEY_MOVEMENT_ENABLED, snapshot.movementEnabled)
            .putBoolean(KEY_AUTO_START_ENABLED, snapshot.autoStartEnabled)
            .apply()
    }

    fun readSettings(): OverlayPrefsSnapshot {
        return OverlayPrefsSnapshot(
            petType = prefs.getString(KEY_PET_TYPE, DEFAULT_PET_TYPE) ?: DEFAULT_PET_TYPE,
            petEmoji = prefs.getString(KEY_PET_EMOJI, DEFAULT_PET_EMOJI),
            petAssetPath = prefs.getString(KEY_PET_ASSET_PATH, null),
            sizePercent = prefs.getFloat(KEY_SIZE, 1.0f),
            opacity = prefs.getFloat(KEY_OPACITY, 1.0f),
            speed = prefs.getFloat(KEY_SPEED, 0.5f),
            movementEnabled = prefs.getBoolean(KEY_MOVEMENT_ENABLED, true),
            autoStartEnabled = prefs.getBoolean(KEY_AUTO_START_ENABLED, false),
        )
    }

    fun writePosition(x: Int, y: Int) {
        prefs.edit().putInt(KEY_POSITION_X, x).putInt(KEY_POSITION_Y, y).apply()
    }

    /** Null when the pet has never been shown before (fresh install). */
    fun readPosition(): Pair<Int, Int>? {
        if (!prefs.contains(KEY_POSITION_X) || !prefs.contains(KEY_POSITION_Y)) return null
        return prefs.getInt(KEY_POSITION_X, 0) to prefs.getInt(KEY_POSITION_Y, 0)
    }

    /**
     * The soonest incomplete task's deadline (epoch millis), or null if
     * there isn't one. Mirrored here — separately from [writeSettings] since
     * it's task data, not a pet/behavior setting — so [OverlayService] can
     * restore the countdown on restart/reboot without the Dart VM.
     */
    fun writeNextDeadline(millis: Long?) {
        val editor = prefs.edit()
        if (millis == null) editor.remove(KEY_NEXT_DEADLINE) else editor.putLong(KEY_NEXT_DEADLINE, millis)
        editor.apply()
    }

    fun readNextDeadline(): Long? {
        return if (prefs.contains(KEY_NEXT_DEADLINE)) prefs.getLong(KEY_NEXT_DEADLINE, 0L) else null
    }

    /**
     * The active streak's mode/status/timestamps, or null to clear it.
     * Mirrored here for the same reason as [writeNextDeadline]: a service
     * restart or boot-restore has no Dart VM to ask.
     */
    fun writeStreak(snapshot: StreakPrefsSnapshot?) {
        val editor = prefs.edit()
        if (snapshot == null) {
            editor.remove(KEY_STREAK_MODE).remove(KEY_STREAK_STATUS).remove(KEY_STREAK_START).remove(KEY_STREAK_END)
        } else {
            editor.putString(KEY_STREAK_MODE, snapshot.mode)
                .putString(KEY_STREAK_STATUS, snapshot.status)
                .putLong(KEY_STREAK_START, snapshot.startMillis)
            if (snapshot.endMillis == null) editor.remove(KEY_STREAK_END) else editor.putLong(KEY_STREAK_END, snapshot.endMillis)
        }
        editor.apply()
    }

    fun readStreak(): StreakPrefsSnapshot? {
        val mode = prefs.getString(KEY_STREAK_MODE, null) ?: return null
        val status = prefs.getString(KEY_STREAK_STATUS, null) ?: return null
        if (!prefs.contains(KEY_STREAK_START)) return null
        val end = if (prefs.contains(KEY_STREAK_END)) prefs.getLong(KEY_STREAK_END, 0L) else null
        return StreakPrefsSnapshot(mode, status, prefs.getLong(KEY_STREAK_START, 0L), end)
    }

    companion object {
        private const val PREFS_NAME = "overlay_prefs"
        private const val KEY_PET_TYPE = "pet_type"
        private const val KEY_PET_EMOJI = "pet_emoji"
        private const val KEY_PET_ASSET_PATH = "pet_asset_path"
        private const val KEY_SIZE = "size_percent"
        private const val KEY_OPACITY = "opacity"
        private const val KEY_SPEED = "speed"
        private const val KEY_MOVEMENT_ENABLED = "movement_enabled"
        private const val KEY_AUTO_START_ENABLED = "auto_start_enabled"
        private const val KEY_POSITION_X = "position_x"
        private const val KEY_POSITION_Y = "position_y"
        private const val KEY_NEXT_DEADLINE = "next_deadline_millis"
        private const val KEY_STREAK_MODE = "streak_mode"
        private const val KEY_STREAK_STATUS = "streak_status"
        private const val KEY_STREAK_START = "streak_start_millis"
        private const val KEY_STREAK_END = "streak_end_millis"

        const val DEFAULT_PET_TYPE = "emoji"
        const val DEFAULT_PET_EMOJI = "🐱"
    }
}
