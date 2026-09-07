package com.sulemanlabs.floatingstreak

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the bidirectional `MethodChannel` described in
 * `platform_channel_constants.dart`. Deliberately thin: every method here
 * either validates arguments and forwards to [OverlayService] / [OverlayPrefs],
 * or answers a permission query directly — no floating-window logic lives in
 * this class (see [OverlayWindowManager] for that), matching the "don't put
 * business logic in MainActivity" guidance in the architecture spec.
 */
class MainActivity : FlutterActivity(), OverlayEventBridge.Listener {

    private var channel: MethodChannel? = null
    private var lastKnownOverlayPermission = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler(::handleMethodCall)
        channel = methodChannel

        OverlayEventBridge.listener = this
        lastKnownOverlayPermission = isOverlayPermissionGranted()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        OverlayEventBridge.listener = null
        channel?.setMethodCallHandler(null)
        channel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onResume() {
        super.onResume()
        // Settings.ACTION_MANAGE_OVERLAY_PERMISSION never tells the app when
        // the user comes back — polling on resume is the standard pattern.
        val granted = isOverlayPermissionGranted()
        if (granted != lastKnownOverlayPermission) {
            lastKnownOverlayPermission = granted
            channel?.invokeMethod(EVENT_PERMISSION_CHANGED, mapOf(ARG_GRANTED to granted))
        }
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                METHOD_START_OVERLAY -> handleStartOverlay(call, result)
                METHOD_STOP_OVERLAY -> handleStopOverlay(result)
                METHOD_UPDATE_PET -> handleUpdatePet(call, result)
                METHOD_UPDATE_SIZE -> handleUpdateSize(call, result)
                METHOD_UPDATE_OPACITY -> handleUpdateOpacity(call, result)
                METHOD_UPDATE_SPEED -> handleUpdateSpeed(call, result)
                METHOD_SET_MOVEMENT_ENABLED -> handleSetMovementEnabled(call, result)
                METHOD_SYNC_SETTINGS -> handleSyncSettings(call, result)
                METHOD_SYNC_NEXT_DEADLINE -> handleSyncNextDeadline(call, result)
                METHOD_UPDATE_STREAK -> handleUpdateStreak(call, result)
                METHOD_CLEAR_STREAK -> handleClearStreak(result)
                METHOD_REQUEST_OVERLAY_PERMISSION -> handleRequestOverlayPermission(result)
                METHOD_IS_OVERLAY_PERMISSION_GRANTED -> result.success(isOverlayPermissionGranted())
                METHOD_GET_OVERLAY_STATUS -> result.success(if (OverlayService.isRunning) "running" else "stopped")
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            // A malformed call must never crash the app — surface it to Dart instead.
            result.error("overlay_error", e.message ?: "Unexpected error handling ${call.method}", null)
        }
    }

    private fun handleStartOverlay(call: MethodCall, result: MethodChannel.Result) {
        if (!isOverlayPermissionGranted()) {
            result.success(false)
            return
        }
        val args = call.arguments as? Map<*, *>
        val intent = Intent(this, OverlayService::class.java).apply {
            putExtra(OverlayService.EXTRA_PET_TYPE, sanitizedPetType(args?.get(ARG_PET_TYPE)))
            putExtra(OverlayService.EXTRA_PET_EMOJI, args?.get(ARG_PET_EMOJI) as? String)
            putExtra(OverlayService.EXTRA_PET_ASSET_PATH, args?.get(ARG_PET_ASSET_PATH) as? String)
            putExtra(OverlayService.EXTRA_SIZE, sanitizedFloat(args?.get(ARG_SIZE_PERCENT), 1.0f, 0.1f, 4f))
            putExtra(OverlayService.EXTRA_OPACITY, sanitizedFloat(args?.get(ARG_OPACITY), 1.0f, 0.05f, 1f))
            putExtra(OverlayService.EXTRA_SPEED, sanitizedFloat(args?.get(ARG_SPEED), 0.5f, 0f, 1f))
            putExtra(OverlayService.EXTRA_MOVEMENT_ENABLED, args?.get(ARG_MOVEMENT_ENABLED) as? Boolean ?: true)
        }
        ContextCompat.startForegroundService(this, intent)
        result.success(true)
    }

    private fun handleStopOverlay(result: MethodChannel.Result) {
        if (OverlayService.isRunning) {
            startService(Intent(this, OverlayService::class.java).apply { action = OverlayService.ACTION_STOP })
        }
        result.success(true)
    }

    private fun handleUpdatePet(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        OverlayService.instance?.updatePet(
            sanitizedPetType(args?.get(ARG_PET_TYPE)),
            args?.get(ARG_PET_EMOJI) as? String,
            args?.get(ARG_PET_ASSET_PATH) as? String,
        )
        result.success(true)
    }

    private fun handleUpdateSize(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val size = (args?.get(ARG_SIZE_PERCENT) as? Number)?.toFloat()
        if (size == null) {
            result.success(false)
            return
        }
        OverlayService.instance?.updateSize(size.coerceIn(0.1f, 4f))
        result.success(true)
    }

    private fun handleUpdateOpacity(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val opacity = (args?.get(ARG_OPACITY) as? Number)?.toFloat()
        if (opacity == null) {
            result.success(false)
            return
        }
        OverlayService.instance?.updateOpacity(opacity.coerceIn(0.05f, 1f))
        result.success(true)
    }

    private fun handleUpdateSpeed(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val speed = (args?.get(ARG_SPEED) as? Number)?.toFloat()
        if (speed == null) {
            result.success(false)
            return
        }
        OverlayService.instance?.updateSpeed(speed.coerceIn(0f, 1f))
        result.success(true)
    }

    private fun handleSetMovementEnabled(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val enabled = args?.get(ARG_MOVEMENT_ENABLED) as? Boolean
        if (enabled == null) {
            result.success(false)
            return
        }
        OverlayService.instance?.setMovementEnabled(enabled)
        result.success(true)
    }

    private fun handleSyncSettings(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        if (args == null) {
            result.success(false)
            return
        }
        val snapshot = OverlayPrefsSnapshot(
            petType = sanitizedPetType(args[ARG_PET_TYPE]),
            petEmoji = args[ARG_PET_EMOJI] as? String,
            petAssetPath = args[ARG_PET_ASSET_PATH] as? String,
            sizePercent = sanitizedFloat(args[ARG_SIZE_PERCENT], 1.0f, 0.1f, 4f),
            opacity = sanitizedFloat(args[ARG_OPACITY], 1.0f, 0.05f, 1f),
            speed = sanitizedFloat(args[ARG_SPEED], 0.5f, 0f, 1f),
            movementEnabled = args[ARG_MOVEMENT_ENABLED] as? Boolean ?: true,
            autoStartEnabled = args[ARG_AUTO_START_ENABLED] as? Boolean ?: false,
        )
        OverlayPrefs(this).writeSettings(snapshot)
        result.success(true)
    }

    private fun handleSyncNextDeadline(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val millis = (args?.get(ARG_DEADLINE_MILLIS) as? Number)?.toLong()
        // Always persisted, same as handleSyncSettings — the boot receiver and any
        // future service restart both read this from OverlayPrefs, not from Dart.
        OverlayPrefs(this).writeNextDeadline(millis)
        OverlayService.instance?.updateNextDeadline(millis)
        result.success(true)
    }

    private fun handleUpdateStreak(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val mode = args?.get(ARG_STREAK_MODE) as? String
        val status = args?.get(ARG_STREAK_STATUS) as? String
        val startMillis = (args?.get(ARG_STREAK_START_MILLIS) as? Number)?.toLong()
        val endMillis = (args?.get(ARG_STREAK_END_MILLIS) as? Number)?.toLong()

        if (mode == null || status == null || startMillis == null) {
            result.success(false)
            return
        }

        // Always mirrored into native storage regardless of whether the overlay
        // is running, same as handleSyncSettings/handleSyncNextDeadline — the
        // boot receiver and any future service restart read this from OverlayPrefs.
        val prefsSnapshot = StreakPrefsSnapshot(mode, status, startMillis, endMillis)
        OverlayPrefs(this).writeStreak(prefsSnapshot)
        OverlayService.instance?.updateStreak(prefsSnapshot.toStreakSnapshot())
        result.success(true)
    }

    private fun handleClearStreak(result: MethodChannel.Result) {
        OverlayPrefs(this).writeStreak(null)
        OverlayService.instance?.updateStreak(null)
        result.success(true)
    }

    private fun handleRequestOverlayPermission(result: MethodChannel.Result) {
        val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
        startActivity(intent)
        result.success(true)
    }

    private fun isOverlayPermissionGranted(): Boolean = Settings.canDrawOverlays(this)

    private fun sanitizedPetType(raw: Any?): String = (raw as? String)?.takeIf { it in VALID_PET_TYPES } ?: "emoji"

    private fun sanitizedFloat(raw: Any?, default: Float, min: Float, max: Float): Float =
        ((raw as? Number)?.toFloat() ?: default).coerceIn(min, max)

    // --- OverlayEventBridge.Listener: native -> Dart -------------------------------

    override fun onOverlayStarted() = postToChannel { it.invokeMethod(EVENT_OVERLAY_STARTED, null) }

    override fun onOverlayStopped() = postToChannel { it.invokeMethod(EVENT_OVERLAY_STOPPED, null) }

    override fun onPetTapped() = postToChannel { it.invokeMethod(EVENT_PET_TAPPED, null) }

    override fun onPetDoubleTapped() = postToChannel { it.invokeMethod(EVENT_PET_DOUBLE_TAPPED, null) }

    override fun onOverlayError(message: String) =
        postToChannel { it.invokeMethod(EVENT_OVERLAY_ERROR, mapOf(ARG_MESSAGE to message)) }

    private fun postToChannel(action: (MethodChannel) -> Unit) {
        val activeChannel = channel ?: return
        runOnUiThread { action(activeChannel) }
    }

    companion object {
        private const val CHANNEL = "com.floatingpet.overlay/control"
        private val VALID_PET_TYPES = setOf("emoji", "image", "gif", "lottie")

        private const val METHOD_START_OVERLAY = "startOverlay"
        private const val METHOD_STOP_OVERLAY = "stopOverlay"
        private const val METHOD_UPDATE_PET = "updatePet"
        private const val METHOD_UPDATE_SIZE = "updateSize"
        private const val METHOD_UPDATE_OPACITY = "updateOpacity"
        private const val METHOD_UPDATE_SPEED = "updateSpeed"
        private const val METHOD_SET_MOVEMENT_ENABLED = "setMovementEnabled"
        private const val METHOD_SYNC_SETTINGS = "syncSettings"
        private const val METHOD_SYNC_NEXT_DEADLINE = "syncNextDeadline"
        private const val METHOD_UPDATE_STREAK = "updateStreak"
        private const val METHOD_CLEAR_STREAK = "clearStreak"
        private const val METHOD_REQUEST_OVERLAY_PERMISSION = "requestOverlayPermission"
        private const val METHOD_IS_OVERLAY_PERMISSION_GRANTED = "isOverlayPermissionGranted"
        private const val METHOD_GET_OVERLAY_STATUS = "getOverlayStatus"

        private const val EVENT_OVERLAY_STARTED = "overlayStarted"
        private const val EVENT_OVERLAY_STOPPED = "overlayStopped"
        private const val EVENT_PET_TAPPED = "petTapped"
        private const val EVENT_PET_DOUBLE_TAPPED = "petDoubleTapped"
        private const val EVENT_PERMISSION_CHANGED = "permissionChanged"
        private const val EVENT_OVERLAY_ERROR = "overlayError"

        private const val ARG_PET_TYPE = "petType"
        private const val ARG_PET_EMOJI = "petEmoji"
        private const val ARG_PET_ASSET_PATH = "petAssetPath"
        private const val ARG_SIZE_PERCENT = "sizePercent"
        private const val ARG_OPACITY = "opacity"
        private const val ARG_SPEED = "speed"
        private const val ARG_MOVEMENT_ENABLED = "movementEnabled"
        private const val ARG_AUTO_START_ENABLED = "autoStartEnabled"
        private const val ARG_GRANTED = "granted"
        private const val ARG_MESSAGE = "message"
        private const val ARG_DEADLINE_MILLIS = "deadlineMillis"
        private const val ARG_STREAK_MODE = "streakMode"
        private const val ARG_STREAK_STATUS = "streakStatus"
        private const val ARG_STREAK_START_MILLIS = "streakStartMillis"
        private const val ARG_STREAK_END_MILLIS = "streakEndMillis"
    }
}
