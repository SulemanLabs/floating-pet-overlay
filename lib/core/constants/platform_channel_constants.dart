/// Names shared verbatim with the Kotlin side. Keep this file and
/// `MainActivity.kt` / `OverlayService.kt` in sync manually — there is no
/// codegen bridging the two languages.
class PlatformChannelConstants {
  const PlatformChannelConstants._();

  static const String controlChannel = 'com.floatingpet.overlay/control';

  // Flutter -> Android
  static const String methodStartOverlay = 'startOverlay';
  static const String methodStopOverlay = 'stopOverlay';
  static const String methodUpdatePet = 'updatePet';
  static const String methodUpdateSize = 'updateSize';
  static const String methodUpdateOpacity = 'updateOpacity';
  static const String methodUpdateSpeed = 'updateSpeed';
  static const String methodSetMovementEnabled = 'setMovementEnabled';
  static const String methodSyncSettings = 'syncSettings';
  static const String methodRequestOverlayPermission = 'requestOverlayPermission';
  static const String methodIsOverlayPermissionGranted = 'isOverlayPermissionGranted';
  static const String methodGetOverlayStatus = 'getOverlayStatus';
  static const String methodIsNotificationPermissionGranted = 'isNotificationPermissionGranted';
  static const String methodRequestNotificationPermission = 'requestNotificationPermission';
  static const String methodSyncNextDeadline = 'syncNextDeadline';
  static const String methodUpdateStreak = 'updateStreak';
  static const String methodClearStreak = 'clearStreak';

  // Android -> Flutter
  static const String eventOverlayStarted = 'overlayStarted';
  static const String eventOverlayStopped = 'overlayStopped';
  static const String eventPetTapped = 'petTapped';
  static const String eventPetDoubleTapped = 'petDoubleTapped';
  static const String eventPermissionChanged = 'permissionChanged';
  static const String eventOverlayError = 'overlayError';

  // Argument keys
  static const String argPetType = 'petType';
  static const String argPetEmoji = 'petEmoji';
  static const String argPetAssetPath = 'petAssetPath';
  static const String argSizePercent = 'sizePercent';
  static const String argOpacity = 'opacity';
  static const String argSpeed = 'speed';
  static const String argMovementEnabled = 'movementEnabled';
  static const String argAutoStartEnabled = 'autoStartEnabled';
  static const String argGranted = 'granted';
  static const String argMessage = 'message';
  static const String argStatus = 'status';
  static const String argDeadlineMillis = 'deadlineMillis';
  static const String argStreakMode = 'streakMode';
  static const String argStreakStatus = 'streakStatus';
  static const String argStreakStartMillis = 'streakStartMillis';
  static const String argStreakEndMillis = 'streakEndMillis';
}
