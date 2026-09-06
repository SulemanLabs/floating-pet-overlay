import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'package:floating_streak/core/errors/failures.dart';
import 'package:floating_streak/features/pets/data/datasources/pet_asset_storage.dart';
import 'package:floating_streak/features/pets/domain/entities/pet_entity.dart';

/// Renders a real 1x1 PNG through `dart:ui` rather than hand-crafting PNG
/// bytes — guarantees a codec-valid file without hardcoding a fragile,
/// hard-to-verify-by-eye byte sequence.
Future<Uint8List> _generateOnePixelPng() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 1, 1), ui.Paint()..color = const ui.Color(0xFFFF0000));
  final image = await recorder.endRecording().toImage(1, 1);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return byteData!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late PetAssetStorage storage;
  late Uint8List onePixelPng;

  setUpAll(() async {
    onePixelPng = await _generateOnePixelPng();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pet_asset_storage_test');
    storage = PetAssetStorage();
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('validate rejects a file that does not exist', () async {
    expect(
      () => storage.validate('${tempDir.path}/missing.png'),
      throwsA(isA<AssetValidationFailure>()),
    );
  });

  test('validate rejects an empty file', () async {
    final file = File('${tempDir.path}/empty.png')..writeAsBytesSync([]);
    expect(() => storage.validate(file.path), throwsA(isA<AssetValidationFailure>()));
  });

  test('validate rejects an unsupported extension', () async {
    final file = File('${tempDir.path}/pet.exe')..writeAsBytesSync([1, 2, 3]);
    expect(() => storage.validate(file.path), throwsA(isA<AssetValidationFailure>()));
  });

  test('validate accepts a real PNG and reports its dimensions', () async {
    final file = File('${tempDir.path}/pet.png')..writeAsBytesSync(onePixelPng);
    final result = await storage.validate(file.path);
    expect(result.type, PetType.image);
    expect(result.width, 1);
    expect(result.height, 1);
  });

  test('validate rejects a corrupted image', () async {
    final file = File('${tempDir.path}/pet.png')..writeAsBytesSync([1, 2, 3, 4, 5]);
    expect(() => storage.validate(file.path), throwsA(isA<AssetValidationFailure>()));
  });

  test('validate treats .gif as PetType.gif', () async {
    final file = File('${tempDir.path}/pet.gif')..writeAsBytesSync(onePixelPng);
    final result = await storage.validate(file.path);
    expect(result.type, PetType.gif);
  });

  test('validate accepts a minimal Lottie-shaped JSON file', () async {
    final file = File('${tempDir.path}/pet.json')
      ..writeAsStringSync(jsonEncode({'v': '5.9.0', 'w': 100, 'h': 100, 'layers': []}));
    final result = await storage.validate(file.path);
    expect(result.type, PetType.lottie);
  });

  test('validate rejects JSON that is not Lottie-shaped', () async {
    final file = File('${tempDir.path}/pet.json')..writeAsStringSync(jsonEncode({'hello': 'world'}));
    expect(() => storage.validate(file.path), throwsA(isA<AssetValidationFailure>()));
  });

  test('validate rejects malformed JSON', () async {
    final file = File('${tempDir.path}/pet.json')..writeAsStringSync('{not valid json');
    expect(() => storage.validate(file.path), throwsA(isA<AssetValidationFailure>()));
  });
}
