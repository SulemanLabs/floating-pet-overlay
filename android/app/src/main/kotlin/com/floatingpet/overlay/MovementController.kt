package com.floatingpet.overlay

import android.os.Handler
import android.os.Looper
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin
import kotlin.random.Random

/**
 * Drives automatic wandering + edge-bounce movement for the overlay pet.
 *
 * Uses a single `Handler.postDelayed` loop at ~30fps rather than a raw
 * `Thread` or a busy loop — cheap on battery, trivially paused for dragging,
 * and trivially torn down in [stop] with no leaked callbacks (Section 25:
 * avoid busy loops, clean up callbacks when the service stops).
 */
class MovementController(private val onPositionUpdate: (x: Int, y: Int) -> Unit) {

    private val handler = Handler(Looper.getMainLooper())
    private var running = false
    private var paused = false

    private var x = 0f
    private var y = 0f
    private var velocityX = 0f
    private var velocityY = 0f
    private var boundsWidth = 0
    private var boundsHeight = 0
    private var petSizePx = 0
    private var speed = 0.5f
    private var idleUntilMs = 0L
    private var lastFrameTimeMs = 0L

    private val frameRunnable = object : Runnable {
        override fun run() {
            if (!running) return
            step()
            handler.postDelayed(this, FRAME_INTERVAL_MS)
        }
    }

    fun start(initialX: Int, initialY: Int, boundsWidth: Int, boundsHeight: Int, petSizePx: Int, speed: Float) {
        x = initialX.toFloat()
        y = initialY.toFloat()
        this.boundsWidth = boundsWidth
        this.boundsHeight = boundsHeight
        this.petSizePx = petSizePx
        this.speed = speed
        randomizeDirection()
        lastFrameTimeMs = System.currentTimeMillis()
        if (!running) {
            running = true
            handler.post(frameRunnable)
        }
    }

    fun updateBounds(boundsWidth: Int, boundsHeight: Int) {
        this.boundsWidth = boundsWidth
        this.boundsHeight = boundsHeight
        clampToBounds()
    }

    fun updatePetSize(petSizePx: Int) {
        this.petSizePx = petSizePx
        clampToBounds()
    }

    fun updateSpeed(newSpeed: Float) {
        speed = newSpeed
    }

    /** Called after a manual drag so the next auto-movement frame resumes from there. */
    fun setPosition(newX: Int, newY: Int) {
        x = newX.toFloat()
        y = newY.toFloat()
    }

    fun pause() {
        paused = true
    }

    fun resume() {
        paused = false
        lastFrameTimeMs = System.currentTimeMillis()
    }

    fun stop() {
        running = false
        handler.removeCallbacks(frameRunnable)
    }

    private fun randomizeDirection() {
        val magnitude = speedToPxPerSecond(speed)
        val angle = Random.nextDouble(0.0, 2 * Math.PI)
        velocityX = (magnitude * cos(angle)).toFloat()
        velocityY = (magnitude * sin(angle)).toFloat()
    }

    private fun speedToPxPerSecond(speedFraction: Float): Float {
        val clamped = speedFraction.coerceIn(0f, 1f)
        return MIN_SPEED_PX_PER_S + (MAX_SPEED_PX_PER_S - MIN_SPEED_PX_PER_S) * clamped
    }

    private fun step() {
        val now = System.currentTimeMillis()
        val dtSeconds = (now - lastFrameTimeMs).coerceIn(0, 100) / 1000f
        lastFrameTimeMs = now

        if (paused || now < idleUntilMs) return
        if (boundsWidth <= petSizePx || boundsHeight <= petSizePx) return // no room to roam yet

        x += velocityX * dtSeconds
        y += velocityY * dtSeconds

        val maxX = (boundsWidth - petSizePx).toFloat()
        val maxY = (boundsHeight - petSizePx).toFloat()
        var bounced = false

        if (x <= 0f) {
            x = 0f
            velocityX = abs(velocityX)
            bounced = true
        } else if (x >= maxX) {
            x = maxX
            velocityX = -abs(velocityX)
            bounced = true
        }

        if (y <= 0f) {
            y = 0f
            velocityY = abs(velocityY)
            bounced = true
        } else if (y >= maxY) {
            y = maxY
            velocityY = -abs(velocityY)
            bounced = true
        }

        if (bounced && Random.nextFloat() < IDLE_PROBABILITY_ON_BOUNCE) {
            idleUntilMs = now + Random.nextLong(MIN_IDLE_MS, MAX_IDLE_MS)
        }

        onPositionUpdate(x.toInt(), y.toInt())
    }

    private fun clampToBounds() {
        val maxX = (boundsWidth - petSizePx).coerceAtLeast(0).toFloat()
        val maxY = (boundsHeight - petSizePx).coerceAtLeast(0).toFloat()
        x = x.coerceIn(0f, maxX)
        y = y.coerceIn(0f, maxY)
        onPositionUpdate(x.toInt(), y.toInt())
    }

    companion object {
        private const val FRAME_INTERVAL_MS = 32L // ~30fps: smooth without excessive wakeups
        private const val MIN_SPEED_PX_PER_S = 40f
        private const val MAX_SPEED_PX_PER_S = 420f
        private const val IDLE_PROBABILITY_ON_BOUNCE = 0.25f
        private const val MIN_IDLE_MS = 400L
        private const val MAX_IDLE_MS = 1600L
    }
}
