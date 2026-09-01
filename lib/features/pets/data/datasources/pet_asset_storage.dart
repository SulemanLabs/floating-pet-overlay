import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/pet_entity.dart';

class PetAssetValidationResult {
  const PetAssetValidationResult({required this.type, this.width, this.height});

  final PetType type;
  final int? width;
  final int? height;
}

/// Validates picked files and manages the app-private "pets" directory they
/// get copied into. Files are never referenced from their original picker
/// path — that path can be a transient cache location that disappears —
/// they're always copied into app storage first (Section 13: "do not depend
/// solely on the original filename", and don't copy arbitrary files blindly
/// without validating them first).
class PetAssetStorage {
  static const _maxBytes = 15 * 1024 * 1024;
  static const _imageExtensions = {'png', 'jpg', 'jpeg', 'webp'};
  static const _gifExtensions = {'gif'};
  static const _lottieExtensions = {'json'};

  Future<PetAssetValidationResult> validate(String sourcePath) async {
    final file = File(sourcePath);
    if (!await file.exists()) {
      throw const AssetValidationFailure('Selected file no longer exists.');
    }

    final length = await file.length();
    if (length <= 0) {
      throw const AssetValidationFailure('Selected file is empty.');
    }
    if (length > _maxBytes) {
      throw const AssetValidationFailure('File is too large (max 15 MB).');
    }

    final ext = p.extension(sourcePath).replaceFirst('.', '').toLowerCase();
    if (_imageExtensions.contains(ext)) {
      final size = await _decodeImageSize(file);
      return PetAssetValidationResult(type: PetType.image, width: size.$1, height: size.$2);
    }
    if (_gifExtensions.contains(ext)) {
      final size = await _decodeImageSize(file);
      return PetAssetValidationResult(type: PetType.gif, width: size.$1, height: size.$2);
    }
    if (_lottieExtensions.contains(ext)) {
      await _validateLottieJson(file);
      return const PetAssetValidationResult(type: PetType.lottie);
    }
    throw AssetValidationFailure('Unsupported file type ".$ext". Use PNG, JPG, WebP, GIF, or a Lottie JSON file.');
  }

  Future<(int, int)> _decodeImageSize(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final size = (frame.image.width, frame.image.height);
      frame.image.dispose();
      codec.dispose();
      return size;
    } catch (_) {
      throw const AssetValidationFailure('Could not read this image — it may be corrupted.');
    }
  }

  Future<void> _validateLottieJson(File file) async {
    final String raw;
    try {
      raw = await file.readAsString();
    } catch (_) {
      throw const AssetValidationFailure('Could not read this file as text.');
    }
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const AssetValidationFailure('This file is not valid JSON.');
    }
    if (decoded is! Map || !decoded.containsKey('layers')) {
      throw const AssetValidationFailure('This JSON file does not look like a Lottie animation.');
    }
  }

  /// Copies a validated source file into `<app documents>/pets/<petId>.<ext>`.
  Future<String> copyIntoAppStorage({required String sourcePath, required String petId}) async {
    final ext = p.extension(sourcePath);
    final documentsDir = await getApplicationDocumentsDirectory();
    final petsDir = Directory(p.join(documentsDir.path, 'pets'));
    if (!await petsDir.exists()) {
      await petsDir.create(recursive: true);
    }
    final destinationPath = p.join(petsDir.path, '$petId$ext');
    await File(sourcePath).copy(destinationPath);
    return destinationPath;
  }

  Future<void> deleteAsset(String assetPath) async {
    final file = File(assetPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
