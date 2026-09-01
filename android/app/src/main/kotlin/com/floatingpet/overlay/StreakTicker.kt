package com.floatingpet.overlay

import android.os.Handler
import android.os.Looper

enum class StreakMode { COUNT_UP, COUNTDOWN }

enum class StreakState { ACTIVE, COMPLETED, BROKEN }

/** Everything the ticker needs — mirrors the Dart-side `syncStreak` payload exactly. */
data class StreakSnapshot(
    val mode: StreakMode,
    val state: StreakState,
    val startMillis: Long,
    val endMillis: Long?,
)

/**
 * Drives the floating overlay's streak badge.
 *
 * Same pattern as [DeadlineTicker]: a single `Handler.postDelayed` loop (1s —
 * sub-second precision on a label is wasted work), timestamp-driven so it's
 * correct no matter how many ticks were missed while the app/overlay was
 * backgrounded or the device was asleep. Never an incrementing/decrementing
 * counter — every tick recomputes from [StreakSnapshot.startMillis]/
 * [StreakSnapshot.endMillis] against the current wall clock.
 *
 * On a terminal snapshot (COMPLETED/BROKEN) this shows a brief "Streak
 * Complete"/"Streak Broken" message and then self-clears after
 * [TERMINAL_DISPLAY_MS] — independent of whether Flutter later calls
 * `clearStreak()`, which becomes a harmless no-op against an
 * already-self-cleared ticker.
 */
class StreakTicker(private val onUpdate: (String?) -> Unit) {

    private val handler = Handler(Looper.getMainLooper())
    private var running = false
    private var snapshot: StreakSnapshot? = null

    private val tickRunnable = object : Runnable {
        override fun run() {
            if (!running) return
            tick()
            handler.postDelayed(this, TICK_INTERVAL_MS)
        }
    }

    private val terminalClearRunnable = Runnable {
        snapshot = null
        onUpdate(null)
    }

    fun start() {
        if (running) return
        running = true
        handler.post(tickRunnable)
    }

    fun stop() {
        running = false
        handler.removeCallbacks(tickRunnable)
        handler.removeCallbacks(terminalClearRunnable)
    }

    /** Updates immediately rather than waiting for the next tick, so starting/completing/breaking reflects right away. */
    fun setStreak(newSnapshot: StreakSnapshot?) {
        handler.removeCallbacks(terminalClearRunnable)
        snapshot = newSnapshot
        if (newSnapshot != null && newSnapshot.state != StreakState.ACTIVE) {
            handler.postDelayed(terminalClearRunnable, TERMINAL_DISPLAY_MS)
        }
        if (running) tick()
    }

    private fun tick() {
        val current = snapshot
        if (current == null) {
            onUpdate(null)
            return
        }

        when (current.state) {
            StreakState.COMPLETED -> onUpdate("Streak Complete")
            StreakState.BROKEN -> onUpdate("Streak Broken")
            StreakState.ACTIVE -> onUpdate(activeText(current))
        }
    }

    private fun activeText(snapshot: StreakSnapshot): String {
        val now = System.currentTimeMillis()
        val end = snapshot.endMillis

        if (snapshot.mode == StreakMode.COUNT_UP || end == null) {
            val elapsedMs = (now - snapshot.startMillis).coerceAtLeast(0)
            return "🔥 ${formatClock(elapsedMs)}"
        }

        val remainingMs = (end - now).coerceAtLeast(0)
        val glyph = if (remainingMs <= WARNING_WINDOW_MS) "⏰" else "🔥"
        return "$glyph ${formatClock(remainingMs)}"
    }

    private fun formatClock(millis: Long): String {
        val totalSeconds = millis / 1000
        val days = totalSeconds / 86400
        val hours = (totalSeconds % 86400) / 3600
        val minutes = (totalSeconds % 3600) / 60
        val seconds = totalSeconds % 60
        val clock = String.format("%02d:%02d:%02d", hours, minutes, seconds)
        return if (days > 0) "${days}d $clock" else clock
    }

    companion object {
        private const val TICK_INTERVAL_MS = 1000L
        private const val WARNING_WINDOW_MS = 60 * 60 * 1000L // 1 hour
        private const val TERMINAL_DISPLAY_MS = 3000L
    }
}

/**
 * Parses the raw strings mirrored in [OverlayPrefs] / sent over the
 * MethodChannel into a [StreakSnapshot]. Returns null on anything
 * unrecognized (a corrupted pref, a future Dart-side value this native
 * version doesn't know about) — a bad streak record degrades to "no streak
 * badge", it never crashes the overlay (spec §39).
 */
fun StreakPrefsSnapshot.toStreakSnapshot(): StreakSnapshot? {
    val parsedMode = when (mode) {
        "count_up" -> StreakMode.COUNT_UP
        "countdown" -> StreakMode.COUNTDOWN
        else -> return null
    }
    val parsedState = when (status) {
        "active" -> StreakState.ACTIVE
        "completed" -> StreakState.COMPLETED
        "broken" -> StreakState.BROKEN
        else -> return null
    }
    return StreakSnapshot(mode = parsedMode, state = parsedState, startMillis = startMillis, endMillis = endMillis)
}
