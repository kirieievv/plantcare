/// The sign-in screen at every width and in every language.
///
/// The "remember me / forgot password" row overflowed by 0.8 pt in Russian on a
/// 390 pt screen — invisible in release, a striped warning bar in debug. The
/// arithmetic is the same for every translation, and French is far longer than
/// Russian, so this pins the whole matrix rather than the one case that was
/// noticed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/screens/auth_screen.dart';

void main() {
  // 320 is the narrowest iPhone ever shipped (SE 1st gen); 390 is what the
  // design was drawn at.
  const widths = <double>[320, 375, 390, 430];

  for (final locale in AppLocalizations.supportedLocales) {
    for (final width in widths) {
      testWidgets(
        'sign-in fits ${width.toInt()} pt in ${locale.languageCode}',
        (tester) async {
          tester.view.physicalSize = Size(width, 844) * 3;
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const AuthScreen(isRegistration: false),
            ),
          );
          await tester.pump();

          // An overflow is reported as an exception, not as a failed frame.
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
