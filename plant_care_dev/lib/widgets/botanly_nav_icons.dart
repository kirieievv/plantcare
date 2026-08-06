import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Stroke icons from `Botanly /screens/dashboard_screen.html` bottom nav
/// (viewBox 0 0 24 24, stroke-width 1.8, round caps).
String _hexRgb(Color c) {
  final r = (c.r * 255.0).round().clamp(0, 255);
  final g = (c.g * 255.0).round().clamp(0, 255);
  final b = (c.b * 255.0).round().clamp(0, 255);
  return '#${r.toRadixString(16).padLeft(2, '0')}'
      '${g.toRadixString(16).padLeft(2, '0')}'
      '${b.toRadixString(16).padLeft(2, '0')}';
}

class BotanlyNavGlyph extends StatelessWidget {
  final int tabIndex;
  final Color stroke;
  final double size;

  const BotanlyNavGlyph({
    super.key,
    required this.tabIndex,
    required this.stroke,
    this.size = 22,
  });

  String _svg() {
    final s = _hexRgb(stroke);
    switch (tabIndex) {
      case 0:
        return '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
<path d="M3 9.5L12 3l9 6.5V20a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V9.5z" stroke="$s" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
<polyline points="9 21 9 12 15 12 15 21" stroke="$s" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';
      case 1:
        return '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
<path d="M12 22V12m0 0C12 7 16 3 21 3c0 6-4 9-9 9zm0 0C12 7 8 3 3 3c0 6 4 9 9 9z" stroke="$s" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';
      case 2:
        return '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
<circle cx="12" cy="12" r="9" stroke="$s" stroke-width="1.8"/>
<line x1="12" y1="8" x2="12" y2="16" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
<line x1="8" y1="12" x2="16" y2="12" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
</svg>
''';
      case 3:
        return '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
<circle cx="12" cy="8" r="3.5" stroke="$s" stroke-width="1.8"/>
<path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" stroke="$s" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';
      case 4:
        return '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
<circle cx="12" cy="12" r="3" stroke="$s" stroke-width="1.8"/>
<path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" stroke="$s" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';
    }
    return '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
<circle cx="12" cy="12" r="3" stroke="$s" stroke-width="1.8"/>
</svg>
''';
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg(), width: size, height: size);
  }
}
