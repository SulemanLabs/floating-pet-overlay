import 'package:flutter/material.dart';

/// Soft, pink-tinted shadows. Kept subtle on purpose — avoid stacking these
/// with heavy Material elevation.
abstract final class AppShadows {
  static const none = <BoxShadow>[];

  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x14D93678), blurRadius: 20, offset: Offset(0, 8), spreadRadius: -4),
    BoxShadow(color: Color(0x0A241923), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const elevated = <BoxShadow>[
    BoxShadow(color: Color(0x1FD93678), blurRadius: 28, offset: Offset(0, 12), spreadRadius: -4),
    BoxShadow(color: Color(0x14241923), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const dark = <BoxShadow>[
    BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 8), spreadRadius: -4),
  ];

  static List<BoxShadow> forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : card;
}
