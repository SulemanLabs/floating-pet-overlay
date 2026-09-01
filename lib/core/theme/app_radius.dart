import 'package:flutter/material.dart';

/// Corner-radius scale, plus ready-made [BorderRadius] values for the sizes
/// that get reused most.
abstract final class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;
  static const pill = 999.0;

  static const smRadius = BorderRadius.all(Radius.circular(sm));
  static const mdRadius = BorderRadius.all(Radius.circular(md));
  static const lgRadius = BorderRadius.all(Radius.circular(lg));
  static const xlRadius = BorderRadius.all(Radius.circular(xl));
  static const xxlRadius = BorderRadius.all(Radius.circular(xxl));
  static const pillRadius = BorderRadius.all(Radius.circular(pill));
}
