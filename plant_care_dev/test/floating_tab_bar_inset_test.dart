/// The gap a floating tab bar leaves for the content underneath it.
///
/// Every tab reserved a hand-counted number of pixels at the bottom of its
/// scroll view — 104 on Home, 120 elsewhere — for a bar that floats over the
/// content rather than pushing it up. On a phone with a home indicator the bar
/// takes more room than that, so the last plant card was clipped by the bar and
/// no amount of scrolling would free it.
///
/// The screens now ask instead of counting. This pins the mechanism they ask
/// through: with `extendBody: true` a Scaffold hands its body a MediaQuery whose
/// bottom padding is the height the bar actually occupies. If that ever stops
/// being true the screens go back to being clipped, and this test is what says
/// so before a device does.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a floating bar reports its height to the body', (tester) async {
    const barHeight = 77.0;
    const homeIndicator = 34.0;
    late double reported;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.only(bottom: homeIndicator),
        ),
        child: MaterialApp(
          home: Scaffold(
            extendBody: true,
            body: Builder(
              builder: (context) {
                reported = MediaQuery.of(context).padding.bottom;
                return const SizedBox.expand();
              },
            ),
            // Built the way the real bar is: it carries the home indicator in
            // its own padding rather than leaving it to the body. Measuring a
            // bar without that inset is what made this test claim 91 when the
            // app occupies 125.
            bottomNavigationBar: Builder(
              builder: (context) => Padding(
                padding: EdgeInsets.only(
                  bottom: 14 + MediaQuery.of(context).padding.bottom,
                ),
                child: const SizedBox(height: barHeight),
              ),
            ),
          ),
        ),
      ),
    );

    // The bar, its own margin and the home indicator underneath it — the whole
    // strip the content must clear, not just the part someone remembered.
    expect(reported, barHeight + 14 + homeIndicator);
  });

  testWidgets('without a floating bar the body keeps the system inset', (
    tester,
  ) async {
    late double reported;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                reported = MediaQuery.of(context).padding.bottom;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );

    // Nothing floating means nothing extra to clear, and a screen that adds its
    // own constant on top would be padding twice.
    expect(reported, 34);
  });
}
