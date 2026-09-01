/// Base class for recoverable, expected failures surfaced to the UI layer.
///
/// These are distinct from unexpected exceptions — a [Failure] is something
/// the UI should present to the user (a message, a retry, a permission
/// prompt), not something that should crash a widget tree.
sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => message;
}

class PlatformBridgeFailure extends Failure {
  const PlatformBridgeFailure(super.message);
}

class OverlayPermissionFailure extends Failure {
  const OverlayPermissionFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class AssetValidationFailure extends Failure {
  const AssetValidationFailure(super.message);
}

class StreakValidationFailure extends Failure {
  const StreakValidationFailure(super.message);
}

class EmojiValidationFailure extends Failure {
  const EmojiValidationFailure(super.message);
}
