# Floating Streak

A Flutter + Kotlin Android app that displays a draggable, auto-moving
animated pet floating above other apps via a foreground service and
`TYPE_APPLICATION_OVERLAY`.

## What's implemented (Phase 1 — core loop, Phase 2 — custom pets, Phase 3 — task reminders)

- Flutter UI: Home, Pet Library, Settings, Overlay Permission screens
  (Material 3, Riverpod, go_router).
- Clean-architecture layering per feature (`domain` / `data` / `presentation`)
  for `pets`, `settings`, `overlay`.
- A single bidirectional `MethodChannel`
  (`com.floatingpet.overlay/control`) — see
  `lib/core/constants/platform_channel_constants.dart` and `MainActivity.kt`,
  which must be kept in sync manually.
- Android foreground service (`OverlayService`) that owns the overlay
  window's lifecycle independently of the Flutter `Activity`.
- `WindowManager` + `TYPE_APPLICATION_OVERLAY` overlay window
  (`OverlayWindowManager`), sized to exactly the pet's own bounds.
- Drag-to-reposition, tap/double-tap detection (`PetOverlayView`). Tapping
  the pet brings the Flutter app to the foreground (`OverlayService.launchApp`,
  reusing the same launch `Intent` the notification's tap action uses) — this
  works even if the app was fully killed, since the tap is handled by the
  foreground service, not the Activity.
- Automatic wandering with edge-bounce and occasional idle pauses, driven by
  a single `Handler` loop, no busy threads (`MovementController`).
- Overlay permission flow with return-to-app re-check
  (`OverlayPermissionScreen`).
- Runtime `POST_NOTIFICATIONS` permission request (API 33+).
- Persistent settings (size, opacity, speed, movement, sound flag,
  auto-start) via `hive` on the Dart side, mirrored into native
  `SharedPreferences` (`OverlayPrefs`) so a `BOOT_COMPLETED` receiver can
  restart the overlay with no Dart VM running.
- Position persistence + restore across overlay restarts.
- Built-in pets ship as **emoji** (🐱🐶🐰🦊🐼🤖) — this avoids bundling any
  binary image assets while still exercising the full rendering pipeline
  (`PetRenderer` draws the glyph natively; `PetAvatar` renders the Flutter
  preview).
- **Custom asset import** ("Add Character" flow, Section 13): pick a PNG,
  JPG, WebP, GIF, or Lottie JSON file (`file_picker`), validate it (extension
  + size cap + an actual decode attempt — a real corruption check, not just
  a MIME sniff), preview it, name it, and save it — `ImportCustomPet` copies
  the validated file into app-private storage under a generated UUID rather
  than trusting the picker's transient path or the original filename.
  Long-press a custom pet in the library to delete it (never removes a
  built-in pet); deleting the active pet falls back to the default.
- **Native rendering for every pet type**, not just emoji, inside the actual
  overlay window:
  - Static images (PNG/JPG/WebP) via `BitmapFactory`, downsampled to the
    pet's on-screen size so a large photo doesn't balloon memory use.
  - Animated GIF via `ImageDecoder`'s `AnimatedImageDrawable` on API 28+;
    below that, `BitmapFactory` decodes the first frame as a static
    image — a graceful degrade with no special-case code.
  - Lottie JSON via `lottie-android`'s `LottieDrawable`.
  - All three decode on a background thread (`PetRenderer.loadContentAsync`)
    so a multi-megabyte file never blocks the main thread; a stale decode
    that finishes after the pet's been changed again is discarded via a
    monotonically increasing request id (`PetOverlayView.contentRequestId`).
  - Animated drawables self-schedule their own frames through Android's
    standard `Drawable.Callback` hosting pattern (`PetOverlayView` implements
    `invalidateDrawable`/`scheduleDrawable`/`unscheduleDrawable`) — the same
    mechanism `ImageView` uses internally — and are explicitly
    started/stopped on attach/detach so nothing keeps animating (or keeps a
    thread alive) once the overlay is hidden.
  - A failed decode (missing file, corrupted asset) falls back to the emoji
    glyph and surfaces a **non-fatal** `overlayError` event — the overlay
    keeps running rather than crashing or stopping the service.
- **Task reminders**: a full task list (title + deadline) lives in
  `features/tasks/`. The pet reacts to whichever *incomplete* task's
  deadline is soonest:
  - The floating overlay itself shows a live countdown badge (updated every
    second by `DeadlineTicker.kt`, a `Handler`-based loop mirroring
    `MovementController`'s pattern) whenever any task is active — formatted
    as `Nd Hh` / `Hh Mm` / `MM:SS` depending on how much time is left.
  - Within 1 hour of the deadline the pet's content is overridden entirely
    with ⏰; once the deadline passes, 🚨 — regardless of pet type (emoji,
    image, GIF, or Lottie), since urgency is a temporary visual override on
    top of `PetOverlayView`, not a property of the pet itself.
  - `TaskController` (Riverpod) pushes the nearest deadline to native
    whenever a task is added, completed, or deleted, via a new
    `syncNextDeadline` bridge method — mirrored into `OverlayPrefs` exactly
    like pet/behavior settings, so it survives a service restart or reboot
    without the Dart VM running.
  - Home screen shows a one-line summary of the next deadline; the full list
    (add/complete/swipe-to-delete) lives on its own Tasks screen.
- Unit tests: settings clamping, pet repository (incl. JSON round-trip,
  add/delete, fallback-when-deleted), asset validation (real PNG decode via
  `dart:ui`, corrupted/empty/oversized/wrong-extension/malformed-Lottie-JSON
  rejection), task repository (add/update/delete, next-deadline selection),
  deadline formatting, a Flutter widget smoke test with a mocked
  `MethodChannel`.

## Deliberately deferred (follow-up work)

These are modeled in the domain layer (`OverlaySettings.soundEnabled`) so
they can be added without another migration, but are **not** wired
end-to-end yet:

- Custom emoji picker UI (built-ins are hardcoded; no free-text emoji entry
  yet).
- The system-event reaction framework (battery, screen lock/unlock →
  animation reactions). `OverlayController._onPlatformEvent` already has a
  `PetTappedEvent`/`PetDoubleTappedEvent` hook point for this.
- Actual sound playback (the `soundEnabled` setting persists but nothing
  plays yet).
- Kotlin-side unit tests for `MovementController`, `PetRenderer`, and
  `DeadlineTicker` (Dart-side equivalents — settings clamping, asset
  validation, deadline formatting — are covered; native movement/countdown
  math and native decode paths are not).
- Task due-time notifications (a system notification when a deadline hits,
  separate from the always-on overlay countdown/urgency emoji).

## Project structure

```
lib/
  core/            constants, platform bridge, storage, theme, router, DI
  features/
    pets/          domain/data/presentation — pet library, selection,
                    and custom asset import (ImportCustomPet/DeleteCustomPet,
                    PetAssetStorage validates + copies files into app storage)
    settings/      domain/data/presentation — persisted overlay settings
    overlay/       domain/data/presentation — start/stop, permissions,
                    the OverlayController that ties pets+settings+bridge together
    tasks/         domain/data/presentation — task list; TaskController pushes
                    the nearest incomplete deadline to the overlay on every change
android/app/src/main/kotlin/com/floatingpet/overlay/
  MainActivity.kt              MethodChannel host, permission handling
  OverlayService.kt            foreground service, owns the window lifecycle
  OverlayWindowManager.kt      WindowManager + LayoutParams + drag/position
  MovementController.kt        auto-wander/bounce loop
  DeadlineTicker.kt            1s countdown/urgency loop for the active task deadline
  PetOverlayView.kt            the pet's View: drawing, touch/gesture handling,
                                and Drawable.Callback hosting for animated content
  PetRenderer.kt                decodes image/GIF/Lottie content off the main
                                thread; draws the emoji fallback directly
  OverlayPrefs.kt               native SharedPreferences mirror (for boot restore)
  OverlayEventBridge.kt         in-process Service -> Activity event relay
  OverlayNotificationFactory.kt persistent notification + channel
  BootCompletedReceiver.kt      restarts the overlay after reboot if enabled
```

## Run it

```bash
flutter pub get
flutter run   # pick an Android device/emulator when prompted
```

No physical Android device or emulator was attached in this environment —
`flutter build apk --debug` was used instead to verify the full Kotlin +
Dart stack actually compiles (`build/app/outputs/flutter-apk/app-debug.apk`).
Run `flutter run` yourself once a device is connected, or start one with:

```bash
flutter emulators --create --name pixel_test   # if you have an Android emulator image
flutter emulators --launch pixel_test
```

## Manual testing checklist (physical device)

1. **Permission flow**: fresh install → tap "Start floating pet" → should
   redirect to the permission screen → tap "Open settings" → grant "display
   over other apps" → return to app → banner clears automatically.
2. **Start/stop**: tap start, confirm the pet appears and the "Floating Pet
   is active" notification shows; tap the notification's "Stop" action,
   confirm the pet disappears and the app's status updates to "Stopped"
   without needing to reopen the app.
3. **Drag**: drag the pet around; it should track your finger exactly and
   stop at screen edges; releasing it should resume auto-movement if enabled.
3a. **Tap to open**: swipe the app away from recents entirely (kill it) with
    the overlay still running, then tap the pet — the app should launch and
    come to the foreground, confirming this doesn't depend on the Activity
    having been alive.
4. **Auto-movement**: with movement enabled and the pet untouched, confirm
   it wanders and bounces off all four edges without ever going off-screen.
5. **Settings live-update**: with the overlay running, change size/opacity
   in Settings and confirm the on-screen pet updates immediately.
6. **Backgrounding**: swipe the Flutter app away entirely (remove from
   recents) — the pet should keep floating and moving.
7. **Rotation**: rotate the device while the overlay is running — the pet
   should stay on-screen, not get clipped or stuck outside the new bounds.
8. **Position restore**: drag the pet to a corner, stop the overlay, start
   it again — it should reappear where you left it.
9. **Reboot + auto-start**: enable "Start automatically" in Settings, reboot
   the device, unlock it — the pet should appear without opening the app.
10. **Permission revoked mid-run**: start the overlay, then revoke "display
    over other apps" from system Settings while it's running — the service
    should stop itself and surface an error rather than crashing.
11. **Custom import — image/GIF**: Pet library → Add character → pick a PNG
    and a GIF; confirm both preview correctly, save, select each as the
    active pet, start the overlay, and confirm the GIF actually animates
    on-screen (not just its first frame) and the static image renders sharp
    at a few different Size settings.
12. **Custom import — Lottie**: import a small Lottie JSON animation
    (e.g. from lottiefiles.com), confirm it plays in both the Add Character
    preview and the live overlay.
13. **Custom import — invalid file**: try importing a `.txt` file and a
    corrupted/truncated image — both should show a clear error and never
    crash the app.
14. **Delete custom pet**: long-press a custom pet in the library, confirm
    the delete dialog, confirm it's gone from the grid and its file is gone
    from `<app files>/pets/` (`adb shell run-as com.floatingpet.overlay ls
    files/pets`).
15. **Corrupted/missing asset**: delete a custom pet's file directly via adb
    (bypassing the app's own delete flow) while it's still listed as a pet,
    then select it and start the overlay — `PetRenderer` should fail the
    decode gracefully, fall back to the emoji glyph, and surface a
    non-fatal error rather than crashing the service.
16. **Task countdown appears**: with the overlay running, add a task with a
    deadline a few minutes out — the countdown badge should appear on the
    pet within a second or two (no restart needed) and tick down live.
17. **Urgency emoji swap**: add a task due in under a minute — confirm the
    pet's content is fully replaced by ⏰ once inside the 1-hour warning
    window, then by 🚨 once the deadline passes — and confirm it reverts to
    the normal pet when that task is marked complete or deleted.
18. **Multiple tasks, nearest wins**: add two tasks with different
    deadlines — confirm the overlay always reflects the *soonest incomplete*
    one, and re-checks correctly as you complete/delete the currently-shown
    one (the display should fall back to the next-soonest, or clear
    entirely if none remain).
19. **Countdown survives restart**: with an active task deadline, stop and
    restart the overlay — the countdown should resume immediately (from
    `OverlayPrefs`), not reset to "no task" and wait for Dart to resync it.
20. **Countdown across reboot**: with auto-start and an active task deadline
    both set, reboot the device — the countdown/urgency state should be
    correct as soon as the overlay reappears.

## Release build

```bash
flutter build appbundle --release
```

To sign a real release build, create `android/key.properties` (already
excluded via `.gitignore` — never commit it) pointing at a keystore you
generate with:

```bash
keytool -genkey -v -keystore ~/floating-pet-release.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias floating_pet
```

```properties
# android/key.properties
storePassword=<your store password>
keyPassword=<your key password>
keyAlias=floating_pet
storeFile=/absolute/path/to/floating-pet-release.jks
```

`android/app/build.gradle.kts` picks this up automatically when present and
falls back to debug signing when it's absent, so `flutter build apk
--release` keeps working on machines without a keystore. R8 minification +
resource shrinking are already enabled for the release build type.

Play Store notes: this app requests `SYSTEM_ALERT_WINDOW`, which requires a
completed Play Console "Permissions declaration" explaining the overlay use
case before submission, and a privacy-practices declaration since it reads
device settings state (no personal data is collected or transmitted — all
storage is local).

## Troubleshooting

- **"applies the Kotlin Gradle Plugin, which will cause build failures in
  future versions of Flutter"** — a warning (not an error) from
  `flutter build`. This Flutter release (3.44.6) ships its "built-in Kotlin"
  toggle disabled by default (`android.builtInKotlin=false` in
  `android/gradle.properties`), which is why `android/app/build.gradle.kts`
  applies `org.jetbrains.kotlin.android` explicitly. Migrate by following
  https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers
  once that mode is stable on your Flutter version.
- **Pet doesn't appear after tapping Start**: check `adb logcat | grep
  OverlayWindowManager` — `addView` throwing usually means the overlay
  permission was revoked after being granted, or another overlay window is
  already attached (`OverlayWindowManager.isShowing` guards against a second
  `show()` call, but a stale `WindowManager` reference across a service
  recreation could still surface here).
- **Notification doesn't show**: confirm `POST_NOTIFICATIONS` is granted on
  API 33+ (Settings → Apps → Floating Streak → Notifications). The
  service still runs without it — only the visible notification is
  suppressed.
- **Overlay survives after force-stopping the app from system Settings**:
  expected — Android force-stop kills the whole process including the
  service, so this is not a leak; killing only "the app" (swiping from
  recents) intentionally leaves the foreground service running.

## Production-readiness checklist

- [x] Compiles clean: `flutter analyze` (0 issues), `flutter test` (34/34
      assertions passing), `flutter build apk --debug` (succeeds, Lottie
      dependency included).
- [x] No deprecated overlay APIs (`TYPE_APPLICATION_OVERLAY` only, minSdk 26
      floor makes the legacy `TYPE_PHONE`/`TYPE_SYSTEM_ALERT` branches moot).
- [x] Foreground service declares `foregroundServiceType="specialUse"` with
      the required subtype property for API 34+.
- [x] All `MethodChannel` arguments validated/clamped on the Kotlin side.
- [x] Imported files validated (extension, size cap, real decode attempt)
      before being copied into app storage; never trusts the original
      filename or a bare MIME guess.
- [x] Image/GIF/Lottie decoding runs off the main thread; stale results from
      a superseded pet change are discarded rather than applied.
- [x] Animated content is explicitly stopped on view detach — nothing keeps
      animating (or a thread alive) once the overlay is hidden.
- [x] R8 minification + resource shrinking enabled for release.
- [x] Release signing reads from a non-committed `key.properties`, no
      hardcoded secrets.
- [x] Task deadline state mirrored into native storage exactly like
      settings/position, so the countdown survives a service restart or
      reboot without depending on the Dart VM.
- [ ] Reaction system beyond deadlines (battery/lock-screen events), sound
      playback, custom emoji picker, due-time notifications — see
      "Deliberately deferred" above.
- [ ] Manual device testing checklist above — not yet run against a
      physical device in this environment (none was attached); needs a real
      run before shipping, especially items 11–20 (custom import/rendering,
      task deadline countdown/urgency).
- [ ] Play Store data-safety form / permissions declaration for
      `SYSTEM_ALERT_WINDOW` — not filed (no Play Console access here).
# floating-pet-overlay
