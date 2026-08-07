/// Settings — reminders, quiet hours, password, sign out (v4, ORDER stage 6).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/services/auth_service.dart';
import 'package:plant_care/services/language_service.dart';
import 'package:plant_care/services/notification_service.dart';
import 'package:plant_care/theme/botanly_glass.dart';
import 'package:plant_care/widgets/botanly_kit.dart';
import 'package:plant_care/widgets/botanly_sheet.dart';

class SettingsV4Screen extends StatefulWidget {
  final User user;

  const SettingsV4Screen({super.key, required this.user});

  @override
  State<SettingsV4Screen> createState() => _SettingsV4ScreenState();
}

class _SettingsV4ScreenState extends State<SettingsV4Screen> {
  bool _email = true;
  bool _push = true;
  String _quietStart = '22:00';
  String _quietEnd = '08:00';
  bool _loaded = false;

  /// The name shown on the account card, taken from the profile.
  ///
  /// Not the Firebase Auth display name, which is where this used to come
  /// from. That one is written once at sign-up and by nothing since — the
  /// registration screen that asked for it was removed, and editing the
  /// profile writes here instead. So the header could show a name typed a
  /// year ago while the profile showed a different one, with no way to
  /// reconcile them. The profile is the only place a name can be set, so it
  /// is the only place worth reading.
  String _name = '';

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await AuthService.getUserPreferences();
      final legacy = prefs['watering_reminders'] ?? true;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();
      final data = doc.data();
      final channels = data?['wateringReminderChannels'];

      if (!mounted) return;
      setState(() {
        _name = (data?['name'] as String? ?? '').trim();
        _quietStart = data?['quietHours']?['start'] ?? '22:00';
        _quietEnd = data?['quietHours']?['end'] ?? '08:00';
        if (channels is Map) {
          _email = channels['email'] != false;
          _push = channels['push'] != false;
        } else {
          _email = legacy;
          _push = legacy;
        }
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _saveChannels() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set({
            'wateringReminderChannels': {'email': _email, 'push': _push},
          }, SetOptions(merge: true));
      await AuthService.saveUserPreferences({
        'watering_reminders': _email || _push,
      });
      if (mounted) showBotanlyToast(context, l10n.settingsSavedToast);
    } catch (e) {
      if (!mounted) return;
      showBotanlyToast(
        context,
        l10n.failedToSaveReminderChannels(e.toString()),
        success: false,
      );
    }
  }

  Future<void> _openQuietHours() async {
    final result = await showBotanlySheet<({String start, String end})>(
      context: context,
      builder: (_) => _QuietHoursSheet(start: _quietStart, end: _quietEnd),
    );
    if (result == null || !mounted) return;

    setState(() {
      _quietStart = result.start;
      _quietEnd = result.end;
    });

    try {
      await NotificationService().updateQuietHours(result.start, result.end);
      if (mounted) showBotanlyToast(context, l10n.quietHoursUpdatedToast);
    } catch (e) {
      if (!mounted) return;
      showBotanlyToast(
        context,
        l10n.failedToUpdateQuietHours(e.toString()),
        success: false,
      );
    }
  }

  Future<void> _openLanguage() async {
    await showBotanlySheet<void>(
      context: context,
      builder: (sheetContext) => BotanlySheet(
        header: BotanlySheetHeader(
          glyph: BotanlySvg.infoCircle,
          tint: kGlassWaterBg,
          foreground: kGlassWater,
          title: l10n.language,
        ),
        children: [
          for (final locale in AppLocalizations.supportedLocales)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: BotanlyListRow(
                glyph: BotanlySvg.infoCircle,
                glyphBg: kGlassWaterBg,
                glyphColor: kGlassWater,
                title: _languageName(locale.languageCode),
                trailing:
                    LanguageService.localeNotifier.value.languageCode ==
                        locale.languageCode
                    ? const BotanlyGlyph(
                        BotanlySvg.check,
                        size: 17,
                        color: kGlassAccent,
                      )
                    : const SizedBox.shrink(),
                onTap: () async {
                  await LanguageService.setLanguage(locale.languageCode);
                  if (!sheetContext.mounted) return;
                  Navigator.of(sheetContext).pop();
                  if (mounted)
                    showBotanlyToast(context, l10n.settingsSavedToast);
                },
              ),
            ),
        ],
      ),
    );
    if (mounted) setState(() {});
  }

  static String _languageName(String code) => switch (code) {
    'ru' => 'Русский',
    'uk' => 'Українська',
    'de' => 'Deutsch',
    'es' => 'Español',
    'fr' => 'Français',
    _ => 'English',
  };

  Future<void> _changePassword() async {
    final changed = await showBotanlySheet<bool>(
      context: context,
      builder: (_) => const _ChangePasswordSheet(),
    );
    if (changed == true && mounted) {
      showBotanlyToast(context, l10n.passwordChangedSuccessfully);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showBotanlySheet<bool>(
      context: context,
      builder: (_) => BotanlySheet(
        header: BotanlySheetHeader(
          glyph: BotanlySvg.close,
          tint: kGlassWarmBg,
          foreground: kGlassAlert,
          title: l10n.signOutConfirmTitle,
        ),
        footer: Row(
          children: [
            Expanded(
              child: BotanlyButton(
                label: l10n.cancel,
                kind: BotanlyButtonKind.ghost,
                onTap: () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: BotanlyButton(
                label: l10n.signOut,
                kind: BotanlyButtonKind.destructive,
                onTap: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
        children: [
          Text(
            l10n.signOutConfirmMessage,
            style: glassFont(fontSize: 15, height: 1.6, color: kGlassInk2),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await AuthService.signOut();
    if (mounted) context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF0EC),
      body: Stack(
        children: [
          const Positioned.fill(child: BotanlyBackground()),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: !_loaded
                  ? const Center(
                      child: CircularProgressIndicator(color: kGlassAccent),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      children: [
                        _account(),
                        BotanlySectionLabel(l10n.preferences),
                        _remindersCard(),
                        const SizedBox(height: 9),
                        BotanlyListRow(
                          glyph: BotanlySvg.infoCircle,
                          glyphBg: kGlassWaterBg,
                          glyphColor: kGlassWater,
                          title: l10n.language,
                          subtitle: _languageName(
                            LanguageService.localeNotifier.value.languageCode,
                          ),
                          onTap: _openLanguage,
                        ),
                        BotanlySectionLabel(l10n.securityLabel),
                        BotanlyListRow(
                          glyph: BotanlySvg.edit,
                          title: l10n.changePassword,
                          subtitle: l10n.changePasswordHint,
                          onTap: _changePassword,
                        ),
                        const SizedBox(height: 18),
                        BotanlyListRow(
                          glyph: BotanlySvg.close,
                          glyphBg: kGlassWarmBg,
                          glyphColor: kGlassAlert,
                          title: l10n.signOut,
                          onTap: _signOut,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _account() {
    final email = widget.user.email ?? '';
    // Empty means empty: no name line, no placeholder dash. The email moves up
    // and takes the headline, which is the one thing always known.
    final name = _name;

    return GlassSurface(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: kGlassLeafBg,
              shape: BoxShape.circle,
            ),
            child: const BotanlyGlyph(
              BotanlySvg.profile,
              size: 24,
              color: kGlassAccent,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? email : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: glassFont(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 16.5 * -0.02,
                    color: kGlassInk,
                  ),
                ),
                if (name.isNotEmpty && email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: glassFont(fontSize: 13, color: kGlassMut),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: kGlassLeafBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              l10n.signedInChip,
              style: glassFont(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: kGlassGreenText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _remindersCard() {
    return GlassSurface(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A heading, not a setting: production has no master switch for
          // reminders, only the two channels (CHANGELOG v4).
          Padding(
            padding: const EdgeInsets.only(right: 6, bottom: 4),
            child: Text(
              l10n.wateringReminders,
              style: glassFont(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 15.5 * -0.02,
                color: kGlassInk,
              ),
            ),
          ),
          _SwitchRow(
            glyph: BotanlySvg.chat,
            title: l10n.emailNotificationsLabel,
            value: _email,
            onChanged: (v) {
              setState(() => _email = v);
              _saveChannels();
            },
          ),
          _SwitchRow(
            glyph: BotanlySvg.infoCircle,
            title: l10n.pushNotifications,
            value: _push,
            onChanged: (v) {
              setState(() => _push = v);
              _saveChannels();
            },
          ),
          // Quiet hours belong to push: with push off there is nothing for them
          // to silence, so the row says why instead of pretending to work.
          Opacity(
            opacity: _push ? 1 : 0.5,
            child: _QuietRow(
              title: l10n.quietHoursLabel,
              subtitle: _push
                  ? '$_quietStart — $_quietEnd'
                  : l10n.quietHoursNeedsPush,
              onTap: _push ? _openQuietHours : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String glyph;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.glyph,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kGlassLeafBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: BotanlyGlyph(glyph, size: 17, color: kGlassAccent),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              title,
              style: glassFont(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: kGlassInk,
              ),
            ),
          ),
          BotanlySwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _QuietRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _QuietRow({required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return BotanlyPress(
      scale: 0.99,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 6, 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kGlassWaterBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const BotanlyGlyph(
                BotanlySvg.clock,
                size: 17,
                color: kGlassWater,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: glassFont(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: kGlassInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: glassFont(fontSize: 12.5, color: kGlassMut),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const BotanlyGlyph(
                BotanlySvg.chevronRight,
                size: 15,
                color: kGlassChevron,
              ),
          ],
        ),
      ),
    );
  }
}

/// Quiet hours: pick "from", pick "to", see the range light up.
///
/// A clock face rather than two time pickers — the thing the user is choosing
/// is a stretch of night, and two spinners never showed it as one.
class _QuietHoursSheet extends StatefulWidget {
  final String start;
  final String end;

  const _QuietHoursSheet({required this.start, required this.end});

  @override
  State<_QuietHoursSheet> createState() => _QuietHoursSheetState();
}

class _QuietHoursSheetState extends State<_QuietHoursSheet> {
  late int _start = _hour(widget.start);
  late int _end = _hour(widget.end);
  bool _editingStart = true;

  static int _hour(String value) => int.tryParse(value.split(':').first) ?? 0;

  /// Hours covered, walking forward from start and wrapping past midnight.
  int get _span {
    final raw = (_end - _start) % 24;
    return raw == 0 ? 24 : raw;
  }

  bool _inRange(int hour) {
    if (_start == _end) return true; // the whole day
    final from = _start;
    final to = _end;
    return from < to
        ? hour >= from && hour < to
        // Wrapped: everything after "from" or before "to" is inside the night.
        : hour >= from || hour < to;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BotanlySheet(
      header: BotanlySheetHeader(
        glyph: BotanlySvg.clock,
        tint: kGlassWaterBg,
        foreground: kGlassWater,
        title: l10n.quietHoursLabel,
      ),
      footer: Row(
        children: [
          Expanded(
            child: BotanlyButton(
              label: l10n.cancel,
              kind: BotanlyButtonKind.ghost,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: BotanlyButton(
              label: l10n.save,
              onTap: () => Navigator.of(context).pop((
                start: '${_start.toString().padLeft(2, '0')}:00',
                end: '${_end.toString().padLeft(2, '0')}:00',
              )),
            ),
          ),
        ],
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: _EndpointButton(
                label: l10n.quietHoursFrom,
                value: '${_start.toString().padLeft(2, '0')}:00',
                selected: _editingStart,
                onTap: () => setState(() => _editingStart = true),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _EndpointButton(
                label: l10n.quietHoursTo,
                value: '${_end.toString().padLeft(2, '0')}:00',
                selected: !_editingStart,
                onTap: () => setState(() => _editingStart = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 24,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            // 44 px minimum per cell, as the checklist demands.
            mainAxisExtent: 44,
          ),
          itemBuilder: (_, hour) {
            final selectedEndpoint = _editingStart
                ? hour == _start
                : hour == _end;
            final inside = _inRange(hour);

            return GestureDetector(
              onTap: () => setState(() {
                if (_editingStart) {
                  _start = hour;
                } else {
                  _end = hour;
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selectedEndpoint
                      ? kGlassWater
                      : inside
                      ? kGlassWaterBg
                      : const Color(0x0F141E0F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hour.toString().padLeft(2, '0'),
                  style: glassFont(
                    fontSize: 13.5,
                    fontWeight: selectedEndpoint
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: selectedEndpoint
                        ? Colors.white
                        : inside
                        ? kGlassBlueText
                        : kGlassMut,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: kGlassWaterBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const BotanlyGlyph(
                BotanlySvg.infoCircle,
                size: 16,
                color: kGlassBlueText,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  l10n.quietHoursSummary(_span),
                  style: glassFont(
                    fontSize: 13,
                    height: 1.4,
                    color: kGlassBlueText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EndpointButton extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _EndpointButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BotanlyPress(
      scale: 0.98,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? kGlassWaterBg : const Color(0xB3FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? kGlassWater : const Color(0xE6FFFFFF),
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: glassFont(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 10.5 * 0.07,
                color: kGlassMut,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: glassFont(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 18 * -0.02,
                color: selected ? kGlassBlueText : kGlassInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Change password — every production check, plus a strength meter.
class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  bool _showCurrent = false;
  bool _showNext = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// 0-3: length, then variety. Deliberately blunt — it nudges, it does not gate.
  int get _strength {
    final value = _next.text;
    if (value.length < 6) return 0;
    var score = 1;
    if (value.length >= 10) score++;
    final hasLetters = RegExp(r'[A-Za-zА-Яа-я]').hasMatch(value);
    final hasOther = RegExp(r'[0-9!-\/:-@\[-`{-~]').hasMatch(value);
    if (hasLetters && hasOther) score++;
    return score.clamp(0, 3);
  }

  Future<void> _submit(AppLocalizations l10n) async {
    final current = _current.text.trim();
    final next = _next.text.trim();
    final confirm = _confirm.text.trim();

    if (next.length < 6) {
      setState(() => _error = l10n.passwordTooShortError);
      return;
    }
    if (next == current) {
      setState(() => _error = l10n.passwordSameAsCurrentError);
      return;
    }
    if (next != confirm) {
      setState(() => _error = l10n.passwordsDoNotMatchError);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.changePassword(
        currentPassword: current,
        newPassword: next,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      setState(() {
        _busy = false;
        // The one failure the user can actually act on gets its own sentence.
        _error =
            message.contains('wrong-password') ||
                message.contains('invalid-credential')
            ? l10n.passwordCurrentWrongError
            : l10n.errorChangingPassword(message);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BotanlySheet(
      header: BotanlySheetHeader(
        glyph: BotanlySvg.edit,
        tint: kGlassLeafBg,
        foreground: kGlassAccent,
        title: l10n.changePassword,
      ),
      footer: Row(
        children: [
          Expanded(
            child: BotanlyButton(
              label: l10n.cancel,
              kind: BotanlyButtonKind.ghost,
              onTap: _busy ? null : () => Navigator.of(context).pop(false),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: BotanlyButton(
              label: l10n.save,
              loading: _busy,
              onTap: _busy ? null : () => _submit(l10n),
            ),
          ),
        ],
      ),
      children: [
        BotanlyField(
          controller: _current,
          hint: l10n.currentPassword,
          glyph: BotanlySvg.close,
          obscure: !_showCurrent,
          trailing: _EyeButton(
            open: _showCurrent,
            onTap: () => setState(() => _showCurrent = !_showCurrent),
          ),
        ),
        const SizedBox(height: 10),
        BotanlyField(
          controller: _next,
          hint: l10n.newPassword,
          glyph: BotanlySvg.check,
          obscure: !_showNext,
          onChanged: (_) => setState(() {}),
          trailing: _EyeButton(
            open: _showNext,
            onTap: () => setState(() => _showNext = !_showNext),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < _strength
                        ? (_strength == 1
                              ? kGlassWarm
                              : _strength == 2
                              ? kGlassSun
                              : kGlassAccent)
                        : const Color(0x1C141E0F),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        BotanlyField(
          controller: _confirm,
          hint: l10n.confirmPassword,
          glyph: BotanlySvg.check,
          obscure: !_showNext,
          onChanged: (_) => setState(() {}),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kGlassWarm.withAlpha(26),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _error!,
              style: glassFont(fontSize: 13, height: 1.4, color: kGlassAlert),
            ),
          ),
        ],
      ],
    );
  }
}

class _EyeButton extends StatelessWidget {
  final bool open;
  final VoidCallback onTap;

  const _EyeButton({required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: BotanlyGlyph(
            open ? BotanlySvg.scan : BotanlySvg.infoCircle,
            size: 17,
            color: kGlassMut,
          ),
        ),
      ),
    );
  }
}
