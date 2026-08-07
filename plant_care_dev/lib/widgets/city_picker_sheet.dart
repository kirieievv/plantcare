/// Picking the city the weather is read for.
///
/// Replaces a stock Material dialog with a free-text field, which had two
/// problems beyond looking foreign to the rest of the app: a typed name is not
/// a place, so the weather kept coming from the old coordinates, and there was
/// no way to tell four Springfields apart.
///
/// Every row here carries its own coordinates. Choosing one is what moves the
/// weather, not the text.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/services/weather_service.dart';
import 'package:plant_care/theme/botanly_glass.dart';
import 'package:plant_care/widgets/botanly_kit.dart';

/// Opens the picker. Returns the chosen city, or null if the user backed out.
Future<CitySuggestion?> showCityPicker(BuildContext context) {
  return showModalBottomSheet<CitySuggestion>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CityPickerSheet(),
  );
}

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet();

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final _query = TextEditingController();

  /// Typing is fast and the lookup is a network call, so the field waits for a
  /// pause rather than firing per keystroke.
  static const _debounce = Duration(milliseconds: 350);
  Timer? _pending;

  List<CitySuggestion> _results = const [];
  bool _searching = false;

  /// True once a search has come back empty — used to tell "nothing found" from
  /// "nothing typed yet", which are different screens.
  bool _searched = false;

  @override
  void dispose() {
    _pending?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _pending?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _results = const [];
        _searched = false;
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _pending = Timer(_debounce, () => _search(value));
  }

  Future<void> _search(String value) async {
    final found = await WeatherService().searchCities(value);
    if (!mounted) return;
    // A late answer to an edited query would overwrite a newer one.
    if (value.trim() != _query.text.trim()) return;
    setState(() {
      _results = found;
      _searching = false;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final insets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      // Lifts with the keyboard: the suggestions are useless underneath it.
      padding: EdgeInsets.only(bottom: insets),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: ColoredBox(
              color: const Color(0xF2FCFDFB),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0x26141E0F),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.profileCityLabel,
                      style: glassFont(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 21 * -0.03,
                        color: kGlassInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.profileCityHint,
                      style: glassFont(
                        fontSize: 12.5,
                        height: 1.4,
                        color: kGlassMut,
                      ),
                    ),
                    const SizedBox(height: 14),
                    BotanlyField(
                      controller: _query,
                      hint: l10n.cityPickerHint,
                      glyph: BotanlySvg.pin,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: _onChanged,
                    ),
                    const SizedBox(height: 12),
                    Flexible(child: _results.isEmpty ? _empty(l10n) : _list()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(AppLocalizations l10n) {
    // Three states, three messages. A spinner where "type two letters" belongs
    // reads as the app being slow rather than as waiting for the user.
    final String message;
    if (_searching) {
      message = l10n.cityPickerSearching;
    } else if (_searched) {
      message = l10n.cityPickerNothingFound;
    } else {
      message = l10n.cityPickerStartTyping;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: glassFont(fontSize: 13, height: 1.4, color: kGlassMut2),
      ),
    );
  }

  Widget _list() {
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final city = _results[i];
        return BotanlyPress(
          scale: 0.99,
          onTap: () => Navigator.of(context).pop(city),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xC7FFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xEBFFFFFF), width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: kGlassLeafBg,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const BotanlyGlyph(
                    BotanlySvg.pin,
                    size: 16,
                    color: kGlassAccent,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        city.city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: glassFont(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 15 * -0.015,
                          color: kGlassInk,
                        ),
                      ),
                      if (city.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          city.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: glassFont(
                            fontSize: 12.5,
                            color: kGlassMut,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const BotanlyGlyph(
                  BotanlySvg.chevronRight,
                  size: 15,
                  color: kGlassChevron,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
