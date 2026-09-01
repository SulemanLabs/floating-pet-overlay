import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:floating_pet_overlay/app.dart';
import 'package:floating_pet_overlay/core/constants/platform_channel_constants.dart';
import 'package:floating_pet_overlay/core/providers/core_providers.dart';
import 'package:floating_pet_overlay/core/storage/local_storage.dart';

void main() {
  const channel = MethodChannel(PlatformChannelConstants.controlChannel);

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case PlatformChannelConstants.methodIsOverlayPermissionGranted:
        case PlatformChannelConstants.methodIsNotificationPermissionGranted:
        case PlatformChannelConstants.methodStartOverlay:
        case PlatformChannelConstants.methodStopOverlay:
        case PlatformChannelConstants.methodSyncSettings:
          return true;
        case PlatformChannelConstants.methodGetOverlayStatus:
          return 'stopped';
        default:
          return true;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  testWidgets('Home screen renders with a default pet and start button', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.create();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: const FloatingPetOverlayApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Floating Pet Overlay'), findsOneWidget);
    expect(find.text('Start floating pet'), findsOneWidget);
  });
}
