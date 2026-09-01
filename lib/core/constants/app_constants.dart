/// App-wide constant values shared across features.
class AppConstants {
  const AppConstants._();

  static const String appName = 'Floating Pet Overlay';

  // Settings bounds — mirrored on the native side so both layers agree.
  static const double minSizePercent = 0.5;
  static const double maxSizePercent = 2.0;
  static const double defaultSizePercent = 1.0;

  static const double minOpacity = 0.1;
  static const double maxOpacity = 1.0;
  static const double defaultOpacity = 1.0;

  static const double minSpeed = 0.0;
  static const double maxSpeed = 1.0;
  static const double defaultSpeed = 0.5;

  static const bool defaultMovementEnabled = true;
  static const bool defaultSoundEnabled = true;
  static const bool defaultAutoStartEnabled = false;

  static const String defaultPetId = 'builtin_cat';
}
