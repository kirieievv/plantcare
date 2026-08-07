/// Renders the glass primitive over the real home background.
///
/// The point is the *colour* of the surface, not the text: a card should pick up
/// the wash behind it (blur + saturate 180%) and carry a bright lip along its top
/// edge. Run with `flutter test --update-goldens` to refresh.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plant_care/widgets/botanly_kit.dart';
import 'package:plant_care/theme/botanly_glass.dart';

/// The surface as it was before this pass: blur only, no saturation, no lip.
class _PlainGlass extends StatelessWidget {
  final Widget child;

  const _PlainGlass({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: kGlassShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 13, sigmaY: 13),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: kGlassFill,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: kGlassBorder, width: 0.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('glass over the home background', (tester) async {
    tester.view.physicalSize = const Size(375, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: BotanlyBackground()),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Top: the handoff's surface. Bottom: blur only, for
                    // comparison — the gap between them is what reads as "the
                    // app looks duller than the design".
                    const GlassSurface(
                      radius: 22,
                      child: SizedBox(height: 68, width: double.infinity),
                    ),
                    const SizedBox(height: 12),
                    const _PlainGlass(child: SizedBox(width: double.infinity)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(Stack).first,
      matchesGoldenFile('goldens/glass_surface.png'),
    );
  });
}
