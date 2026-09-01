import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart' as lottie;

import '../../../../core/theme/app_shadows.dart';
import '../../domain/entities/pet_entity.dart';

/// Renders a [PetEntity] preview inside the Flutter UI (pet library, home
/// screen preview card, Add Character preview). The native overlay renders
/// the same content independently via `PetRenderer.kt` — this widget is
/// Flutter-only and the two are not pixel-identical, but show the same asset.
class PetAvatar extends StatelessWidget {
  const PetAvatar({super.key, required this.pet, this.size = 64, this.opacity = 1.0, this.backgroundColor});

  final PetEntity pet;
  final double size;
  final double opacity;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final content = switch (pet.type) {
      PetType.emoji => Text(pet.emoji ?? '❓', style: TextStyle(fontSize: size * 0.6)),
      PetType.image || PetType.gif => _AssetPreview(path: pet.assetPath, size: size),
      PetType.lottie => _LottiePreview(path: pet.assetPath, size: size),
    };

    final resolvedBackground = backgroundColor ?? Theme.of(context).colorScheme.primaryContainer;

    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: resolvedBackground,
          boxShadow: size >= 96 ? AppShadows.forBrightness(Theme.of(context).brightness) : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }
}

class _AssetPreview extends StatelessWidget {
  const _AssetPreview({required this.path, required this.size});

  final String? path;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (path == null) return Icon(Icons.image_outlined, size: size * 0.5);
    return Image.file(
      File(path!),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image_outlined, size: size * 0.5),
    );
  }
}

class _LottiePreview extends StatelessWidget {
  const _LottiePreview({required this.path, required this.size});

  final String? path;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (path == null) return Icon(Icons.animation_outlined, size: size * 0.5);
    return lottie.Lottie.file(
      File(path!),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image_outlined, size: size * 0.5),
    );
  }
}
