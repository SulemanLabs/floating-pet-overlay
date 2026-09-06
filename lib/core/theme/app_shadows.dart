import 'package:flutter/material.dart';

/// Very subtle neutral shadows — kept minimal on purpose. Most surfaces
/// should rely on a thin border rather than elevation; use these only where
/// a touch of lift is genuinely useful (e.g. a bottom sheet, a floating
/// action button).
abstract final class AppShadows {
  static const none = <BoxShadow>[];

  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 2)),
  ];

  static const elevated = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 6)),
  ];

  static const dark = <BoxShadow>[
    BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static List<BoxShadow> forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : card;
}
