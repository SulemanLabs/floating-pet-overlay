package com.sulemanlabs.floatingstreak

/**
 * In-process pub point between [OverlayService] (which owns the overlay
 * window's lifecycle and can outlive any Activity) and [MainActivity] (which
 * owns the `MethodChannel` and forwards events into Dart).
 *
 * A `LocalBroadcastManager` would do the same job but is deprecated; since
 * the service and activity always run in the same process here (no
 * `android:process` override), a plain nullable listener reference is
 * simpler and just as safe. [MainActivity] sets this in
 * `configureFlutterEngine` and clears it in `cleanUpFlutterEngine`, so a call
 * here never reaches a torn-down Flutter engine.
 */
object OverlayEventBridge {
    interface Listener {
        fun onOverlayStarted()
        fun onOverlayStopped()
        fun onPetTapped()
        fun onPetDoubleTapped()
        fun onOverlayError(message: String)
    }

    @Volatile
    var listener: Listener? = null
}
