/// Typed events emitted by the native overlay side, delivered over the
/// bidirectional MethodChannel (see `MainActivity.kt`'s
/// `OverlayBridge.Listener` implementation).
sealed class OverlayPlatformEvent {
  const OverlayPlatformEvent();
}

class OverlayStartedEvent extends OverlayPlatformEvent {
  const OverlayStartedEvent();
}

class OverlayStoppedEvent extends OverlayPlatformEvent {
  const OverlayStoppedEvent();
}

class PetTappedEvent extends OverlayPlatformEvent {
  const PetTappedEvent();
}

class PetDoubleTappedEvent extends OverlayPlatformEvent {
  const PetDoubleTappedEvent();
}

class PermissionChangedEvent extends OverlayPlatformEvent {
  const PermissionChangedEvent(this.granted);

  final bool granted;
}

class OverlayErrorEvent extends OverlayPlatformEvent {
  const OverlayErrorEvent(this.message);

  final String message;
}
