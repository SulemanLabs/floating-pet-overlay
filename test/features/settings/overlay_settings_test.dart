import 'package:flutter_test/flutter_test.dart';

import 'package:floating_streak/features/settings/domain/entities/overlay_settings.dart';

void main() {
  group('OverlaySettings.copyWith clamping', () {
    test('clamps sizePercent to the [0.5, 2.0] range', () {
      const settings = OverlaySettings();

      expect(settings.copyWith(sizePercent: 5.0).sizePercent, 2.0);
      expect(settings.copyWith(sizePercent: -1.0).sizePercent, 0.5);
      expect(settings.copyWith(sizePercent: 1.25).sizePercent, 1.25);
    });

    test('clamps opacity to the [0.1, 1.0] range', () {
      const settings = OverlaySettings();

      expect(settings.copyWith(opacity: 0.0).opacity, 0.1);
      expect(settings.copyWith(opacity: 3.0).opacity, 1.0);
    });

    test('clamps speed to the [0.0, 1.0] range', () {
      const settings = OverlaySettings();

      expect(settings.copyWith(speed: -0.5).speed, 0.0);
      expect(settings.copyWith(speed: 2.0).speed, 1.0);
    });

    test('leaves untouched fields unchanged', () {
      const settings = OverlaySettings(movementEnabled: false, soundEnabled: false, autoStartEnabled: true);

      final updated = settings.copyWith(opacity: 0.5);

      expect(updated.movementEnabled, false);
      expect(updated.soundEnabled, false);
      expect(updated.autoStartEnabled, true);
    });
  });
}
