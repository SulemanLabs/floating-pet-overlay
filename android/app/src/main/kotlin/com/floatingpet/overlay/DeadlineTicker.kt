package com.floatingpet.overlay

import android.os.Handler
import android.os.Looper

enum class DeadlineUrgency { NONE, WARNING, OVERDUE }

/**
 * Drives the floating overlay's task-deadline countdown and urgency state.
 *
 * Same pattern as [MovementController]: a single `Handler.postDelayed` loop
 * (1s here, since sub-second precision on a countdown label is wasted work),
 * cleanly start/stoppable, no thread of its own. [OverlayWindowManager]
 * starts this alongside the pet and stops it in `hide()`.
 */
class DeadlineTicker(private val onUpdate: (DeadlineUrgency, String?) -> Unit) {

    private val handler = Handler(Looper.getMainLooper())
    private var running = false
    private var deadlineMillis: Long? = null

    private val tickRunnable = object : Runnable {
        override fun run() {
            if (!running) return
            tick()
            handler.postDelayed(this, TICK_INTERVAL_MS)
        }
    }

    fun start() {
        if (running) return
        running = true
        handler.post(tickRunnable)
    }

    fun stop() {
        running = false
        handler.removeCallbacks(tickRunnable)
    }

    /** Updates immediately rather than waiting for the next tick, so a task being added/completed reflects right away. */
    fun setDeadline(millis: Long?) {
        deadlineMillis = millis
        if (running) tick()
    }

    private fun tick() {
        val deadline = deadlineMillis
        if (deadline == null) {
            onUpdate(DeadlineUrgency.NONE, null)
            return
        }
        val remainingMs = deadline - System.currentTimeMillis()
        val urgency = when {
            remainingMs <= 0 -> DeadlineUrgency.OVERDUE
            remainingMs <= WARNING_WINDOW_MS -> DeadlineUrgency.WARNING
            else -> DeadlineUrgency.NONE
        }
        onUpdate(urgency, formatCountdown(remainingMs))
    }

    private fun formatCountdown(remainingMs: Long): String {
        if (remainingMs <= 0) return "Overdue"
        val totalSeconds = remainingMs / 1000
        val days = totalSeconds / 86400
        val hours = (totalSeconds % 86400) / 3600
        val minutes = (totalSeconds % 3600) / 60
        val seconds = totalSeconds % 60
        return when {
            days > 0 -> "${days}d ${hours}h"
            hours > 0 -> "${hours}h ${minutes}m"
            else -> String.format("%02d:%02d", minutes, seconds)
        }
    }

    companion object {
        private const val TICK_INTERVAL_MS = 1000L
        private const val WARNING_WINDOW_MS = 60 * 60 * 1000L // 1 hour
    }
}
