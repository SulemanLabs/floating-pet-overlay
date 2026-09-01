package com.floatingpet.overlay

import android.content.Context
import android.graphics.PixelFormat
import android.util.Log
import android.view.Gravity
import android.view.WindowManager

/**
 * Owns the actual floating window: adding/removing it from [WindowManager],
 * keeping [MovementController] and manual drag in sync with the window's
 * `LayoutParams`, and persisting position. [OverlayService] owns *this*
 * class's lifecycle; this class never reaches back into the Service or the
 * Activity, so it can't leak either one.
 */
class OverlayWindowManager(private val context: Context, private val prefs: OverlayPrefs) {

    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val renderer = PetRenderer(context)
    private val movementController = MovementController(::onMovementPositionUpdate)
    private val deadlineTicker = DeadlineTicker(::onDeadlineUpdate)
    private val streakTicker = StreakTicker(::onStreakUpdate)

    private var petView: PetOverlayView? = null
    private var layoutParams: WindowManager.LayoutParams? = null

    private var sizePercent = 1.0f
    private var opacity = 1.0f
    private var speed = 0.5f
    private var movementEnabled = true
    private var currentDiameterPx = 0

    private var lastPersistedAtMs = 0L
    private var attached = false

    var onTap: (() -> Unit)? = null
    var onDoubleTap: (() -> Unit)? = null
    var onError: ((String) -> Unit)? = null

    /** Non-fatal: a single pet's content failed to decode; the overlay keeps running on the emoji fallback. */
    var onAssetError: ((String) -> Unit)? = null

    val isShowing: Boolean get() = attached

    fun show(
        petType: String,
        petEmoji: String?,
        petAssetPath: String?,
        sizePercent: Float,
        opacity: Float,
        speed: Float,
        movementEnabled: Boolean,
        nextDeadlineMillis: Long? = null,
        streakSnapshot: StreakSnapshot? = null,
    ) {
        if (attached) return

        this.sizePercent = sizePercent
        this.opacity = opacity
        this.speed = speed
        this.movementEnabled = movementEnabled

        val diameter = renderer.diameterPx(sizePercent)
        currentDiameterPx = diameter
        val view = PetOverlayView(context, renderer)
        view.opacityValue = opacity
        view.onTap = { onTap?.invoke() }
        view.onDoubleTap = { onDoubleTap?.invoke() }
        view.onDragStart = { movementController.pause() }
        view.onDrag = { dx, dy -> onManualDrag(dx, dy) }
        view.onDragEnd = { onDragEnd() }
        view.onAssetError = { message -> onAssetError?.invoke(message) }

        val params = WindowManager.LayoutParams(
            diameter,
            diameter,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            val (startX, startY) = initialPosition(diameter)
            x = startX
            y = startY
        }

        try {
            windowManager.addView(view, params)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to add overlay view", e)
            onError?.invoke("Could not display the overlay — permission may have been revoked.")
            return
        }

        petView = view
        layoutParams = params
        attached = true
        view.setPetContent(petType, petEmoji, petAssetPath, diameter)

        val bounds = screenBounds()
        movementController.start(params.x, params.y, bounds.first, bounds.second, diameter, speed)
        if (!movementEnabled) movementController.pause()

        deadlineTicker.setDeadline(nextDeadlineMillis)
        deadlineTicker.start()

        streakTicker.setStreak(streakSnapshot)
        streakTicker.start()
    }

    fun hide() {
        movementController.stop()
        deadlineTicker.stop()
        streakTicker.stop()
        val view = petView
        if (view != null && attached) {
            try {
                windowManager.removeView(view)
            } catch (e: Exception) {
                Log.w(TAG, "removeView failed (already detached?)", e)
            }
        }
        petView = null
        layoutParams = null
        attached = false
        renderer.shutdown()
    }

    fun updatePet(petType: String, petEmoji: String?, petAssetPath: String?) {
        petView?.setPetContent(petType, petEmoji, petAssetPath, currentDiameterPx)
    }

    /** Live update while the overlay is running — see `OverlayService.updateNextDeadline`. */
    fun updateNextDeadline(millis: Long?) {
        deadlineTicker.setDeadline(millis)
    }

    private fun onDeadlineUpdate(urgency: DeadlineUrgency, countdownText: String?) {
        val glyph = when (urgency) {
            DeadlineUrgency.WARNING -> "⏰"
            DeadlineUrgency.OVERDUE -> "🚨"
            DeadlineUrgency.NONE -> null
        }
        petView?.updateDeadlineDisplay(glyph, countdownText)
    }

    /** Live update while the overlay is running — see `OverlayService.updateStreak`. */
    fun updateStreak(snapshot: StreakSnapshot?) {
        streakTicker.setStreak(snapshot)
    }

    private fun onStreakUpdate(streakText: String?) {
        petView?.updateStreakDisplay(streakText)
    }

    fun updateSize(newSizePercent: Float) {
        sizePercent = newSizePercent
        val view = petView ?: return
        val params = layoutParams ?: return
        val diameter = renderer.diameterPx(newSizePercent)
        currentDiameterPx = diameter
        params.width = diameter
        params.height = diameter
        applyLayoutUpdate(view, params)
        movementController.updatePetSize(diameter)
    }

    fun updateOpacity(newOpacity: Float) {
        opacity = newOpacity
        petView?.opacityValue = newOpacity
    }

    fun updateSpeed(newSpeed: Float) {
        speed = newSpeed
        movementController.updateSpeed(newSpeed)
    }

    fun setMovementEnabled(enabled: Boolean) {
        movementEnabled = enabled
        if (enabled) movementController.resume() else movementController.pause()
    }

    /** Recomputes screen bounds after a rotation / display-size change. */
    fun onScreenSizeChanged() {
        val params = layoutParams ?: return
        val bounds = screenBounds()
        movementController.updateBounds(bounds.first, bounds.second)
        val diameter = params.width
        params.x = params.x.coerceIn(0, (bounds.first - diameter).coerceAtLeast(0))
        params.y = params.y.coerceIn(0, (bounds.second - diameter).coerceAtLeast(0))
        petView?.let { applyLayoutUpdate(it, params) }
    }

    private fun onManualDrag(dxPx: Float, dyPx: Float) {
        val params = layoutParams ?: return
        val view = petView ?: return
        val bounds = screenBounds()
        val maxX = (bounds.first - params.width).coerceAtLeast(0)
        val maxY = (bounds.second - params.height).coerceAtLeast(0)
        params.x = (params.x + dxPx.toInt()).coerceIn(0, maxX)
        params.y = (params.y + dyPx.toInt()).coerceIn(0, maxY)
        applyLayoutUpdate(view, params)
    }

    private fun onDragEnd() {
        val params = layoutParams ?: return
        movementController.setPosition(params.x, params.y)
        persistPosition(params.x, params.y, force = true)
        if (movementEnabled) movementController.resume()
    }

    private fun onMovementPositionUpdate(x: Int, y: Int) {
        val params = layoutParams ?: return
        val view = petView ?: return
        params.x = x
        params.y = y
        applyLayoutUpdate(view, params)
        persistPosition(x, y, force = false)
    }

    private fun applyLayoutUpdate(view: PetOverlayView, params: WindowManager.LayoutParams) {
        if (!attached) return
        try {
            windowManager.updateViewLayout(view, params)
        } catch (e: Exception) {
            Log.e(TAG, "updateViewLayout failed", e)
            attached = false
            onError?.invoke("Overlay window was lost — it may have been closed by the system.")
        }
    }

    private fun persistPosition(x: Int, y: Int, force: Boolean) {
        val now = System.currentTimeMillis()
        if (!force && now - lastPersistedAtMs < POSITION_PERSIST_INTERVAL_MS) return
        lastPersistedAtMs = now
        prefs.writePosition(x, y)
    }

    private fun initialPosition(diameterPx: Int): Pair<Int, Int> {
        val bounds = screenBounds()
        val saved = prefs.readPosition()
        if (saved != null) {
            val maxX = (bounds.first - diameterPx).coerceAtLeast(0)
            val maxY = (bounds.second - diameterPx).coerceAtLeast(0)
            return saved.first.coerceIn(0, maxX) to saved.second.coerceIn(0, maxY)
        }
        return (bounds.first - diameterPx) / 2 to (bounds.second - diameterPx) / 3
    }

    private fun screenBounds(): Pair<Int, Int> {
        val metrics = context.resources.displayMetrics
        return metrics.widthPixels to metrics.heightPixels
    }

    companion object {
        private const val TAG = "OverlayWindowManager"
        private const val POSITION_PERSIST_INTERVAL_MS = 2000L
    }
}
