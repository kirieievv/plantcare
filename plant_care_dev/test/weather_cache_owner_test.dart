/// Whose city the cached city is.
///
/// The cache lives in the device's preferences, which made it the phone's
/// rather than the person's. Signing a second account in on the same phone gave
/// it the first account's city: the profile showed it, the watering schedule was
/// adjusted against it, and — because the daily resolve looks at when the
/// *device* last resolved — the new account never had a city recorded of its
/// own. In the admin panel it read as no city at all, which was the true
/// answer to a question nobody had asked correctly.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:plant_care/services/weather_service.dart';

void main() {
  test('a cache is usable by the account that wrote it', () {
    expect(cacheBelongsTo('user-a', 'user-a'), isTrue);
  });

  test("another account's cache is not", () {
    // The reported case: one phone, two accounts, one city between them.
    expect(cacheBelongsTo('user-a', 'user-b'), isFalse);
  });

  test('a cache from before owners were recorded counts as foreign', () {
    // Every install that predates this has one. Treating it as ours would keep
    // exactly the bug being fixed alive on every phone already out there.
    expect(cacheBelongsTo(null, 'user-a'), isFalse);
  });

  test('nobody signed in owns nothing', () {
    expect(cacheBelongsTo('user-a', null), isFalse);
    expect(cacheBelongsTo(null, null), isFalse);
  });
}
