package com.sulemanlabs.floatingstreak

import android.content.Context
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ImageDecoder
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import com.airbnb.lottie.LottieCompositionFactory
import com.airbnb.lottie.LottieDrawable
import java.io.File
import java.util.concurrent.Executors

/** Result of loading a pet's visual content: either a ready-to-draw [Drawable], or an [errorMessage] explaining why not (never both null unless the pet type is "emoji", which has no drawable — it's drawn as text directly). */
data class PetContentResult(val drawable: Drawable?, val errorMessage: String?)

/**
 * Loads and renders a pet's visual content.
 *
 * Emoji is drawn directly as text on every frame — cheap, no allocation
 * worth caching. Image/GIF/Lottie content is decoded off the main thread
 * (a multi-megabyte GIF or Lottie JSON is not something to parse during a
 * frame) via [loadContentAsync], then handed to the caller as a [Drawable]
 * to host — see [PetOverlayView] for how it's kept animating and cleaned up.
 *
 * Only [DEFAULT_EMOJI] is drawn as a graceful fallback for anything that
 * fails to decode (missing file, corrupted asset, unsupported pet type) —
 * per Section 23, a bad asset degrades the pet, it never crashes the service.
 */
class PetRenderer(context: Context) {

    private val appContext = context.applicationContext
    private val mainHandler = Handler(Looper.getMainLooper())
    private val decodeExecutor = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "PetRendererDecode").apply { isDaemon = true }
    }

    private val emojiTextBounds = Rect()

    /** Base pet diameter at sizePercent = 1.0, before density scaling. */
    private val baseDiameterDp = 72f

    fun diameterPx(sizePercent: Float): Int {
        val dp = baseDiameterDp * sizePercent.coerceIn(0.1f, 4f)
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp,
            appContext.resources.displayMetrics,
        ).toInt().coerceAtLeast(1)
    }

    /** Draws the emoji fallback directly — used both for `petType == "emoji"` and whenever content failed to load. */
    fun drawEmojiFallback(canvas: Canvas, widthPx: Int, heightPx: Int, emoji: String?, opacity: Float) {
        if (widthPx <= 0 || heightPx <= 0) return
        val glyph = emoji?.takeIf { it.isNotBlank() } ?: DEFAULT_EMOJI

        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textAlign = Paint.Align.CENTER
            textSize = heightPx * 0.7f
            alpha = (opacity.coerceIn(0f, 1f) * 255).toInt()
        }
        paint.getTextBounds(glyph, 0, glyph.length, emojiTextBounds)
        val cx = widthPx / 2f
        val cy = heightPx / 2f - emojiTextBounds.exactCenterY()
        canvas.drawText(glyph, cx, cy, paint)
    }

    /**
     * Overlays a small countdown pill across the bottom of the pet — used
     * whenever a task has an active deadline, regardless of urgency tier
     * (see [DeadlineTicker]). Drawn on top of whatever the pet's normal
     * content is, so it works for emoji, image, GIF, and Lottie pets alike.
     */
    fun drawCountdownBadge(canvas: Canvas, widthPx: Int, heightPx: Int, text: String, opacity: Float) {
        if (widthPx <= 0 || heightPx <= 0) return

        val badgeHeight = heightPx * 0.28f
        val badgeTop = heightPx - badgeHeight
        val alphaMultiplier = opacity.coerceIn(0f, 1f)

        val backgroundPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.BLACK
            alpha = (alphaMultiplier * 150).toInt()
        }
        val badgeRect = RectF(0f, badgeTop, widthPx.toFloat(), heightPx.toFloat())
        canvas.drawRoundRect(badgeRect, badgeHeight / 2f, badgeHeight / 2f, backgroundPaint)

        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            textAlign = Paint.Align.CENTER
            textSize = badgeHeight * 0.55f
            alpha = (alphaMultiplier * 255).toInt()
        }
        val cy = badgeTop + badgeHeight / 2f - (textPaint.descent() + textPaint.ascent()) / 2f
        canvas.drawText(text, widthPx / 2f, cy, textPaint)
    }

    /**
     * Overlays a small streak badge across the TOP of the pet — the mirror
     * image of [drawCountdownBadge]'s bottom pill, so a task deadline and an
     * active streak can be shown at the same time without ever overlapping
     * (see [PetOverlayView.onDraw]).
     */
    fun drawStreakBadge(canvas: Canvas, widthPx: Int, heightPx: Int, text: String, opacity: Float) {
        if (widthPx <= 0 || heightPx <= 0) return

        val badgeHeight = heightPx * 0.28f
        val alphaMultiplier = opacity.coerceIn(0f, 1f)

        val backgroundPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.BLACK
            alpha = (alphaMultiplier * 150).toInt()
        }
        val badgeRect = RectF(0f, 0f, widthPx.toFloat(), badgeHeight)
        canvas.drawRoundRect(badgeRect, badgeHeight / 2f, badgeHeight / 2f, backgroundPaint)

        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            textAlign = Paint.Align.CENTER
            textSize = badgeHeight * 0.5f
            alpha = (alphaMultiplier * 255).toInt()
        }
        val cy = badgeHeight / 2f - (textPaint.descent() + textPaint.ascent()) / 2f
        canvas.drawText(text, widthPx / 2f, cy, textPaint)
    }

    /**
     * Decodes [petType]'s content on a background thread and delivers the
     * result on the main thread via [callback]. Safe to call repeatedly —
     * each call runs independently; the caller ([PetOverlayView]) is
     * responsible for discarding stale results if the pet changes again
     * before a slower decode finishes.
     */
    fun loadContentAsync(
        petType: String,
        petAssetPath: String?,
        targetSizePx: Int,
        callback: (PetContentResult) -> Unit,
    ) {
        if (petType == "emoji") {
            // No drawable to host — PetOverlayView falls back to drawEmojiFallback.
            mainHandler.post { callback(PetContentResult(null, null)) }
            return
        }

        decodeExecutor.execute {
            val result = try {
                when (petType) {
                    "image" -> loadStaticImage(petAssetPath, targetSizePx)
                    "gif" -> loadAnimatedImage(petAssetPath, targetSizePx)
                    "lottie" -> loadLottie(petAssetPath)
                    else -> PetContentResult(null, "Unsupported pet type \"$petType\"")
                }
            } catch (e: Exception) {
                PetContentResult(null, "Could not load pet content: ${e.message}")
            }
            mainHandler.post { callback(result) }
        }
    }

    private fun loadStaticImage(path: String?, targetSizePx: Int): PetContentResult {
        if (path.isNullOrBlank()) return PetContentResult(null, "Missing pet image path")
        val file = File(path)
        if (!file.exists()) return PetContentResult(null, "Pet image file was deleted")

        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
            return PetContentResult(null, "Could not decode pet image")
        }

        val options = BitmapFactory.Options().apply {
            inSampleSize = computeSampleSize(bounds.outWidth, bounds.outHeight, targetSizePx)
        }
        val bitmap = BitmapFactory.decodeFile(path, options) ?: return PetContentResult(null, "Could not decode pet image")
        return PetContentResult(BitmapDrawable(appContext.resources, bitmap), null)
    }

    private fun loadAnimatedImage(path: String?, targetSizePx: Int): PetContentResult {
        if (path.isNullOrBlank()) return PetContentResult(null, "Missing pet GIF path")
        val file = File(path)
        if (!file.exists()) return PetContentResult(null, "Pet GIF file was deleted")

        // ImageDecoder (API 28+) natively returns an AnimatedImageDrawable for an
        // animated GIF/WebP. Below API 28, BitmapFactory still decodes a GIF's
        // first frame as a static image — a graceful, code-free degrade rather
        // than a special case.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            return loadStaticImage(path, targetSizePx)
        }

        return try {
            val source = ImageDecoder.createSource(file)
            val drawable = ImageDecoder.decodeDrawable(source) { decoder, info, _ ->
                val sampleSize = computeSampleSize(info.size.width, info.size.height, targetSizePx)
                if (sampleSize > 1) decoder.setTargetSampleSize(sampleSize)
                decoder.memorySizePolicy = ImageDecoder.MEMORY_POLICY_LOW_RAM
            }
            PetContentResult(drawable, null)
        } catch (e: Exception) {
            PetContentResult(null, "Could not decode pet GIF: ${e.message}")
        }
    }

    private fun loadLottie(path: String?): PetContentResult {
        if (path.isNullOrBlank()) return PetContentResult(null, "Missing pet animation path")
        val file = File(path)
        if (!file.exists()) return PetContentResult(null, "Pet animation file was deleted")

        val result = file.inputStream().use { stream ->
            LottieCompositionFactory.fromJsonInputStreamSync(stream, file.absolutePath)
        }
        val composition = result.value
            ?: return PetContentResult(null, "Could not load Lottie animation: ${result.exception?.message}")

        val drawable = LottieDrawable().apply {
            this.composition = composition
            repeatCount = LottieDrawable.INFINITE
        }
        return PetContentResult(drawable, null)
    }

    private fun computeSampleSize(sourceWidth: Int, sourceHeight: Int, targetPx: Int): Int {
        var sampleSize = 1
        if (sourceWidth > targetPx || sourceHeight > targetPx) {
            var halfWidth = sourceWidth / 2
            var halfHeight = sourceHeight / 2
            while (halfWidth / sampleSize >= targetPx && halfHeight / sampleSize >= targetPx) {
                sampleSize *= 2
            }
        }
        return sampleSize
    }

    /** Call when the owning [OverlayWindowManager] is torn down — see its `hide()`. */
    fun shutdown() {
        decodeExecutor.shutdownNow()
    }

    companion object {
        const val DEFAULT_EMOJI = "❓"
    }
}
