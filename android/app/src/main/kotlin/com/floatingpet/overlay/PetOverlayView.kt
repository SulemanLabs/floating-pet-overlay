package com.floatingpet.overlay

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Canvas
import android.graphics.drawable.Animatable
import android.graphics.drawable.Drawable
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import kotlin.math.abs

/**
 * The actual on-screen pet.
 *
 * Two rendering paths: emoji is drawn directly as text every frame (cheap,
 * nothing to cache). Image/GIF/Lottie content is hosted as a [Drawable] —
 * this view implements [Drawable.Callback] so an [Animatable] drawable
 * (`AnimatedImageDrawable`, `LottieDrawable`) can self-schedule its own
 * frame invalidations exactly the way `ImageView` hosts one internally,
 * rather than this view polling/redrawing on a manual timer.
 *
 * Drag vs. tap disambiguation is manual (touch-slop based) rather than
 * relying solely on [GestureDetector], because the drag needs raw
 * frame-by-frame deltas to move the window, while tap/double-tap detection
 * benefits from the platform's timing-tuned gesture recognizer. Both run
 * side by side over the same event stream.
 */
class PetOverlayView(context: Context, private val renderer: PetRenderer) : View(context) {

    private var petType: String = "emoji"
    private var petEmoji: String? = PetRenderer.DEFAULT_EMOJI
    private var contentDrawable: Drawable? = null
    private var contentRequestId = 0
    private var disposed = false

    /** Non-null while a task deadline is within its warning/overdue window — overrides normal pet content entirely (see [DeadlineTicker]). */
    private var urgencyGlyph: String? = null

    /** Non-null whenever any task has an active deadline, regardless of urgency tier. */
    private var countdownText: String? = null

    /** Non-null whenever a streak is active or briefly showing a terminal message — see [StreakTicker]. */
    private var streakText: String? = null

    var opacityValue: Float = 1f
        set(value) {
            field = value
            contentDrawable?.alpha = (value.coerceIn(0f, 1f) * 255).toInt()
            invalidate()
        }

    var onTap: (() -> Unit)? = null
    var onDoubleTap: (() -> Unit)? = null
    var onDragStart: (() -> Unit)? = null
    var onDrag: ((dxPx: Float, dyPx: Float) -> Unit)? = null
    var onDragEnd: (() -> Unit)? = null
    var onAssetError: ((String) -> Unit)? = null

    private var lastRawX = 0f
    private var lastRawY = 0f
    private var isDragging = false
    private val touchSlopPx = ViewConfiguration.get(context).scaledTouchSlop

    private val gestureDetector = GestureDetector(
        context,
        object : GestureDetector.SimpleOnGestureListener() {
            override fun onSingleTapConfirmed(e: MotionEvent): Boolean {
                onTap?.invoke()
                return true
            }

            override fun onDoubleTap(e: MotionEvent): Boolean {
                onDoubleTap?.invoke()
                return true
            }
        },
    )

    /** Kicks off an async decode (see [PetRenderer.loadContentAsync]) and swaps in the result once it lands. */
    fun setPetContent(type: String, emoji: String?, assetPath: String?, targetSizePx: Int) {
        petType = type
        petEmoji = emoji
        val requestId = ++contentRequestId

        renderer.loadContentAsync(type, assetPath, targetSizePx) { result ->
            if (disposed || requestId != contentRequestId) return@loadContentAsync
            applyContent(result)
        }
    }

    /** Called by [OverlayWindowManager] on every [DeadlineTicker] tick. */
    fun updateDeadlineDisplay(urgencyGlyph: String?, countdownText: String?) {
        this.urgencyGlyph = urgencyGlyph
        this.countdownText = countdownText
        invalidate()
    }

    /** Called by [OverlayWindowManager] on every [StreakTicker] tick. */
    fun updateStreakDisplay(streakText: String?) {
        this.streakText = streakText
        invalidate()
    }

    private fun applyContent(result: PetContentResult) {
        (contentDrawable as? Animatable)?.stop()
        contentDrawable?.callback = null

        contentDrawable = result.drawable?.also { drawable ->
            drawable.setBounds(0, 0, width, height)
            drawable.alpha = (opacityValue.coerceIn(0f, 1f) * 255).toInt()
            drawable.callback = this
            if (isAttachedToWindow) (drawable as? Animatable)?.start()
        }

        result.errorMessage?.let { onAssetError?.invoke(it) }
        invalidate()
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        contentDrawable?.setBounds(0, 0, w, h)
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val urgency = urgencyGlyph
        val drawable = contentDrawable
        when {
            urgency != null -> renderer.drawEmojiFallback(canvas, width, height, urgency, opacityValue)
            drawable != null -> drawable.draw(canvas)
            else -> renderer.drawEmojiFallback(canvas, width, height, petEmoji, opacityValue)
        }
        countdownText?.let { renderer.drawCountdownBadge(canvas, width, height, it, opacityValue) }
        streakText?.let { renderer.drawStreakBadge(canvas, width, height, it, opacityValue) }
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        disposed = false
        (contentDrawable as? Animatable)?.start()
    }

    override fun onDetachedFromWindow() {
        (contentDrawable as? Animatable)?.stop()
        contentDrawable?.callback = null
        disposed = true
        super.onDetachedFromWindow()
    }

    // --- Drawable.Callback: lets a hosted Animatable drawable schedule its own frames ---

    override fun invalidateDrawable(who: Drawable) {
        if (who === contentDrawable) invalidate() else super.invalidateDrawable(who)
    }

    override fun scheduleDrawable(who: Drawable, what: Runnable, whenMs: Long) {
        if (who === contentDrawable) handler?.postAtTime(what, whenMs) else super.scheduleDrawable(who, what, whenMs)
    }

    override fun unscheduleDrawable(who: Drawable, what: Runnable) {
        if (who === contentDrawable) handler?.removeCallbacks(what) else super.unscheduleDrawable(who, what)
    }

    override fun verifyDrawable(who: Drawable): Boolean = who === contentDrawable || super.verifyDrawable(who)

    @SuppressLint("ClickableViewAccessibility")
    override fun onTouchEvent(event: MotionEvent): Boolean {
        gestureDetector.onTouchEvent(event)

        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                lastRawX = event.rawX
                lastRawY = event.rawY
                isDragging = false
            }
            MotionEvent.ACTION_MOVE -> {
                val dx = event.rawX - lastRawX
                val dy = event.rawY - lastRawY
                if (!isDragging && (abs(dx) > touchSlopPx || abs(dy) > touchSlopPx)) {
                    isDragging = true
                    onDragStart?.invoke()
                }
                if (isDragging) {
                    onDrag?.invoke(dx, dy)
                    lastRawX = event.rawX
                    lastRawY = event.rawY
                }
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                if (isDragging) {
                    isDragging = false
                    onDragEnd?.invoke()
                }
            }
        }
        return true
    }
}
