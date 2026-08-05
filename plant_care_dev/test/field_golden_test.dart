/// Renders the glass text field under the real app theme.
///
/// The app theme fills its inputs and gives them an outline in every state; the
/// field is supposed to override all of it and draw exactly one frame — its own.
/// This is here because "looks fixed" was not good enough twice.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_care/theme/botanly_glass.dart';
import 'package:plant_care/widgets/botanly_kit.dart';

void main() {
  testWidgets('glass field draws one frame', (tester) async {
    tester.view.physicalSize = const Size(375, 120);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        // The app's input theme, reproduced without the font layer: this is
        // the part that fights the glass field, and google_fonts cannot load in
        // a test.
        theme: ThemeData(
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0x334A5D43)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0x334A5D43)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: kGlassAccent, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        home: Scaffold(
          backgroundColor: const Color(0xFFE8EFE6),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: GlassSurface(
              padding: const EdgeInsets.all(14),
              child: BotanlyField(
                controller: TextEditingController(),
                hint: 'e.g., Monstera, Snake Plant',
                glyph: BotanlySvg.leaf,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(GlassSurface),
      matchesGoldenFile('goldens/glass_field.png'),
    );
  });
}
