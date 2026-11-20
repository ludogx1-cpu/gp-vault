import 'package:flutter/material.dart';

/// Golden Paw brand gold ("Rich Gold", #C9A227) as a full Material swatch,
/// so it can replace Colors.amber anywhere, including `.shade700`-style
/// lookups. Change the colours here to re-theme the whole app.
const MaterialColor kGold = MaterialColor(0xFFC9A227, <int, Color>{
  50: Color(0xFFFBF6E6),
  100: Color(0xFFF5E9C2),
  200: Color(0xFFEEDB9A),
  300: Color(0xFFE5CB6E),
  400: Color(0xFFD8B848),
  500: Color(0xFFC9A227),
  600: Color(0xFFB38E1F),
  700: Color(0xFF9A7A1B),
  800: Color(0xFF7F6416),
  900: Color(0xFF5E4A10),
});

/// Golden Paw "Charcoal" (#1C1C1C): a greyish black used instead of jet
/// black for the header, footer and dark sidebar. Change it here to
/// re-tint all of them.
const Color kCharcoal = Color(0xFF1C1C1C);

/// Light grey (#EDEDED) used for the header, footer, bottom bar and sidebar
/// in light mode, in place of Charcoal.
const Color kChromeLight = Color(0xFFEDEDED);
