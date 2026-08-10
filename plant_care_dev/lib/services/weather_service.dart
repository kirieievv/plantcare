/// Where the user is and what the weather is doing there (SPEC 12, stage 1).
///
/// Two things this deliberately does not do:
///
///   * it never asks for the location permission — an IP lookup is accurate
///     enough for weather, and the dialog on first launch costs sign-ups;
///   * it never decides anything from the temperature. No "above 32 °C water
///     earlier" lives here or anywhere else in the app. The number reaches the
///     agent, which can weigh it against the species, the pot and the placement,
///     and changing that judgement costs a prompt rather than a release.
library;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:plant_care/services/auth_service.dart';
import 'package:plant_care/services/language_service.dart';
import 'package:plant_care/utils/cloud_functions.dart';

/// The four states the header draws, straight from the design.
enum WeatherCondition { sun, cloud, rain, cold }

WeatherCondition _conditionFrom(String? raw) => switch (raw) {
  'sun' => WeatherCondition.sun,
  'rain' => WeatherCondition.rain,
  'cold' => WeatherCondition.cold,
  _ => WeatherCondition.cloud,
};

/// Where the user is, as resolved once and then reused.
class UserLocation {
  final String city;
  final String? countryCode;
  final double lat;
  final double lon;
  final String? timezone;

  /// 'ip' or 'manual'. A manual value is never overwritten by a lookup —
  /// otherwise the user's correction would be undone on the next launch.
  final String source;

  const UserLocation({
    required this.city,
    required this.lat,
    required this.lon,
    this.countryCode,
    this.timezone,
    this.source = 'ip',
  });

  bool get isManual => source == 'manual';

  /// Fahrenheit is a United States thing, not an English-language thing
  /// (SPEC 6.1). Someone in Germany reading the app in English still sees °C.
  bool get usesFahrenheit => (countryCode ?? '').toUpperCase() == 'US';

  static UserLocation? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final lat = (map['lat'] as num?)?.toDouble();
    final lon = (map['lon'] as num?)?.toDouble();
    final city = map['city']?.toString();
    if (lat == null || lon == null || city == null || city.isEmpty) return null;
    return UserLocation(
      city: city,
      countryCode: map['countryCode']?.toString(),
      lat: lat,
      lon: lon,
      timezone: map['timezone']?.toString(),
      source: map['source']?.toString() ?? 'ip',
    );
  }

  Map<String, dynamic> toMap() => {
    'city': city,
    'countryCode': countryCode,
    'lat': lat,
    'lon': lon,
    'timezone': timezone,
    'source': source,
  };
}

/// Current conditions. Always Celsius in here — conversion happens at the
/// moment of drawing a label and nowhere else.
class WeatherInfo {
  final double tempC;
  final WeatherCondition condition;
  final double? humidity;

  const WeatherInfo({
    required this.tempC,
    required this.condition,
    this.humidity,
  });

  /// Rounded for display, in the unit the user's country expects.
  int temperatureIn({required bool fahrenheit}) =>
      fahrenheit ? (tempC * 9 / 5 + 32).round() : tempC.round();

  static WeatherInfo? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final temp = (map['tempC'] as num?)?.toDouble();
    if (temp == null) return null;
    return WeatherInfo(
      tempC: temp,
      condition: _conditionFrom(map['condition']?.toString()),
      humidity: (map['humidity'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'tempC': tempC,
    'condition': condition.name,
    'humidity': humidity,
  };
}

/// One city suggestion. Region and country are what tell four Springfields
/// apart; the coordinates are what make choosing one actually change the sky.
class CitySuggestion {
  final String city;
  final String? region;
  final String? country;
  final String? countryCode;
  final double lat;
  final double lon;
  final String? timezone;

  const CitySuggestion({
    required this.city,
    required this.lat,
    required this.lon,
    this.region,
    this.country,
    this.countryCode,
    this.timezone,
  });

  /// "Bavaria, Germany" — enough to pick the right one, short enough for a row.
  String get subtitle =>
      [region, country].where((p) => p != null && p.isNotEmpty).join(', ');

  UserLocation toLocation() => UserLocation(
    city: city,
    countryCode: countryCode,
    lat: lat,
    lon: lon,
    timezone: timezone,
    source: 'manual',
  );

  static CitySuggestion? fromMap(Map<String, dynamic> map) {
    final lat = (map['lat'] as num?)?.toDouble();
    final lon = (map['lon'] as num?)?.toDouble();
    final city = map['city']?.toString();
    if (lat == null || lon == null || city == null || city.isEmpty) return null;
    return CitySuggestion(
      city: city,
      region: map['region']?.toString(),
      country: map['country']?.toString(),
      countryCode: map['countryCode']?.toString(),
      lat: lat,
      lon: lon,
      timezone: map['timezone']?.toString(),
    );
  }
}

/// Location plus weather, as the header needs them.
typedef WeatherReading = ({UserLocation? location, WeatherInfo? weather});

/// Whether a cache written by [storedOwner] may be used by [currentUid].
///
/// The city cache lives in the device's preferences, so without an owner it is
/// the phone's rather than the person's. A second account signing in inherited
/// the first one's city — shown in the profile, used to adjust watering, and
/// never written to that account's own record, because the daily resolve saw
/// the *device* had resolved recently and skipped.
///
/// An unclaimed cache counts as somebody else's. That is deliberate: every
/// install that predates this has one, and treating it as foreign costs a
/// single lookup and leaves each account with a city it actually owns.
bool cacheBelongsTo(String? storedOwner, String? currentUid) {
  if (currentUid == null || storedOwner == null) return false;
  return storedOwner == currentUid;
}

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  static const _kLastResolvedKey = 'weather_location_resolved_at';
  static const _kCachedLocation = 'weather_location_cache';
  static const _kCachedWeather = 'weather_reading_cache';

  /// Which account the cached city belongs to.
  ///
  /// Without this the cache is the device's rather than the person's, and a
  /// second account signing in on the same phone inherits the first one's city:
  /// the header shows it, and the daily resolve is skipped because the *device*
  /// resolved recently — so the new account's `geo` is never written and its
  /// watering is adjusted against a city it never chose.
  static const _kCacheOwner = 'weather_cache_owner';

  /// The city is looked up at most once a day (SPEC 3.1). People do not move
  /// between cities often enough to justify a request per launch.
  static const _resolveInterval = Duration(hours: 24);

  WeatherReading? _cached;

  /// The last reading, if this session already has one.
  WeatherReading? get current => _cached;

  final _controller = StreamController<WeatherReading>.broadcast();

  /// Emits whenever the reading changes. The header listens; it never waits.
  Stream<WeatherReading> get stream => _controller.stream;

  /// Loads whatever is known without going to the network.
  ///
  /// Called before [refresh] so the header can draw immediately: the screen
  /// must never block on weather, and yesterday's city is still the right city.
  Future<WeatherReading> loadCached() async {
    if (_cached != null) return _cached!;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!cacheBelongsTo(
        prefs.getString(_kCacheOwner),
        AuthService.currentUser?.uid,
      )) {
        // Somebody else's city, or a cache from before this was recorded.
        // Either way it is not ours to show, and pretending we have nothing is
        // what sends us to resolve it properly.
        _cached = (location: null, weather: null);
        return _cached!;
      }
      final location = UserLocation.fromMap(
        _decode(prefs.getString(_kCachedLocation)),
      );
      final weather = WeatherInfo.fromMap(
        _decode(prefs.getString(_kCachedWeather)),
      );
      _cached = (location: location, weather: weather);
    } catch (e) {
      debugPrint('⚠️ WeatherService: could not read cache: $e');
      _cached = (location: null, weather: null);
    }
    return _cached!;
  }

  Map<String, dynamic>? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Resolves the city if it is due, then fetches the weather for it.
  ///
  /// Every failure here is silent by design: no city means the header shows the
  /// date alone, which is the specified fallback. Nothing about this is worth
  /// an error message to someone who opened the app to water a plant.
  /// [userAsked] marks a pull-to-refresh rather than an arrival. It lowers how
  /// old the server's cached reading may be, and deliberately does *not* touch
  /// the city: a city is re-resolved once a day because it rarely changes and
  /// the lookup service has limits of its own, and a gesture on the home screen
  /// is not evidence the user moved.
  Future<WeatherReading> refresh({
    bool relocate = false,
    bool userAsked = false,
  }) async {
    final cached = await loadCached();
    try {
      final location = await _resolveLocation(cached.location, force: relocate);
      if (location == null) {
        return _publish((location: null, weather: null));
      }

      final weather = await _fetchWeather(location, userAsked: userAsked);
      return _publish((location: location, weather: weather ?? cached.weather));
    } catch (e) {
      debugPrint('⚠️ WeatherService: refresh failed: $e');
      return cached;
    }
  }

  WeatherReading _publish(WeatherReading reading) {
    _cached = reading;
    _controller.add(reading);
    unawaited(_persist(reading));
    return reading;
  }

  Future<void> _persist(WeatherReading reading) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = AuthService.currentUser?.uid;
      if (uid != null) await prefs.setString(_kCacheOwner, uid);
      if (reading.location != null) {
        await prefs.setString(
          _kCachedLocation,
          jsonEncode(reading.location!.toMap()),
        );
      }
      if (reading.weather != null) {
        await prefs.setString(
          _kCachedWeather,
          jsonEncode(reading.weather!.toMap()),
        );
      }
    } catch (e) {
      debugPrint('⚠️ WeatherService: could not write cache: $e');
    }
  }

  Future<UserLocation?> _resolveLocation(
    UserLocation? known, {
    bool force = false,
  }) async {
    // A city the user typed themselves is final. Re-resolving it by IP is how
    // a correction gets quietly undone every morning.
    if (known != null && known.isManual && !force) return known;

    if (!force && !await _resolveDue()) return known;

    final uid = AuthService.currentUser?.uid;
    if (uid == null) return known;

    final response = await http
        .post(
          Uri.parse(resolveUserLocationUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': uid,
            'language': LanguageService.localeNotifier.value.languageCode,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return known;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final resolved = UserLocation.fromMap(
      body['location'] as Map<String, dynamic>?,
    );
    await _markResolved();
    return resolved ?? known;
  }

  Future<bool> _resolveDue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // The daily interval is about how often a person moves, not about how
      // often the phone is used. Somebody else's stamp says nothing about this
      // account, and honouring it is what left new accounts with no city of
      // their own recorded at all.
      if (!cacheBelongsTo(
        prefs.getString(_kCacheOwner),
        AuthService.currentUser?.uid,
      )) {
        return true;
      }
      final last = prefs.getInt(_kLastResolvedKey);
      if (last == null) return true;
      final since = DateTime.now().millisecondsSinceEpoch - last;
      return since >= _resolveInterval.inMilliseconds;
    } catch (_) {
      return true;
    }
  }

  Future<void> _markResolved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _kLastResolvedKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  Future<WeatherInfo?> _fetchWeather(
    UserLocation location, {
    bool userAsked = false,
  }) async {
    final response = await http
        .post(
          Uri.parse(getWeatherUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'lat': location.lat,
            'lon': location.lon,
            // The server keeps a per-city cache and decides for itself; this
            // only tells it which of its two ages to apply.
            if (userAsked) 'fresh': true,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return WeatherInfo.fromMap(body['weather'] as Map<String, dynamic>?);
  }

  /// Suggestions for what the user has typed so far, in their language.
  ///
  /// Returns an empty list on any failure: a dead suggestion service must not
  /// block someone from typing a city name.
  Future<List<CitySuggestion>> searchCities(String query) async {
    if (query.trim().length < 2) return const [];
    try {
      final response = await http
          .post(
            Uri.parse(searchCitiesUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'query': query.trim(),
              'language': LanguageService.localeNotifier.value.languageCode,
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return const [];
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (body['cities'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CitySuggestion.fromMap)
          .whereType<CitySuggestion>()
          .toList();
    } catch (e) {
      debugPrint('⚠️ WeatherService: city search failed: \$e');
      return const [];
    }
  }

  /// Stores a city the user picked and re-reads the weather for it.
  ///
  /// Written to Firestore as well as cached, with `source: manual` — that flag
  /// is what stops the next IP lookup from undoing the choice. Kept under `geo`
  /// rather than `location`, which the profile owns as free text.
  Future<WeatherReading> setManualCity(UserLocation location) async {
    final manual = UserLocation(
      city: location.city,
      countryCode: location.countryCode,
      lat: location.lat,
      lon: location.lon,
      timezone: location.timezone,
      source: 'manual',
    );

    final uid = AuthService.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'geo': {...manual.toMap(), 'updatedAt': FieldValue.serverTimestamp()},
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('⚠️ WeatherService: could not store the chosen city: \$e');
      }
    }

    // New coordinates, so a real re-read rather than the cached city's numbers.
    final weather = await _fetchWeather(manual);
    return _publish((location: manual, weather: weather));
  }
}
