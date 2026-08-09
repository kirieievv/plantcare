/// The camera/gallery sheet.
///
/// Worth a test because the thing that broke before was not the picking but the
/// sheet: four screens each had their own copy, one of them still in English,
/// and one never offered the camera at all. These pin down what the shared
/// helper shows and what it returns when the user backs out.
library;

import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/utils/image_source_picker.dart';

void main() {
  // No platform override here: the helper takes the native path on anything
  // that isn't web, and the test harness reports android — which is one of the
  // two platforms this sheet is for.
  Future<Future<Uint8List?>> openSheet(
    WidgetTester tester,
    Locale locale,
  ) async {
    late Future<Uint8List?> pending;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Material(
            child: TextButton(
              onPressed: () => pending = pickImageBytes(context),
              child: const Text('pick'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();
    return pending;
  }

  testWidgets('offers camera and gallery in the app language', (tester) async {
    await openSheet(tester, const Locale('ru'));

    expect(find.byType(CupertinoActionSheet), findsOneWidget);
    expect(find.text('Камера'), findsOneWidget);
    expect(find.text('Галерея'), findsOneWidget);
    expect(find.text('Отмена'), findsOneWidget);
  });

  testWidgets('follows the locale, not the device', (tester) async {
    await openSheet(tester, const Locale('de'));

    expect(find.text('Kamera'), findsOneWidget);
    expect(find.text('Galerie'), findsOneWidget);
    expect(find.text('Abbrechen'), findsOneWidget);
  });

  testWidgets('cancelling returns null, not an error', (tester) async {
    final pending = await openSheet(tester, const Locale('ru'));

    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    // Null means "changed their mind" and must stay distinguishable from a
    // failure — the screens show an error banner for the latter.
    expect(await pending, isNull);
  });
}
