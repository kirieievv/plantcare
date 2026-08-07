import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/services/auth_service.dart';
import 'package:plant_care/services/language_service.dart';
import 'package:plant_care/services/notification_service.dart';
import 'package:plant_care/services/theme_service.dart';
import 'package:plant_care/theme/botanly_theme.dart';
import 'package:plant_care/widgets/botanly_cabinet_kit.dart';
import 'package:plant_care/widgets/botanly_shimmer.dart';

/// Settings — UI from `Botanly /screens/settings_screen.html`. All logic
/// (preferences, notifications, quiet hours, change password, sign out) is
/// preserved 1:1 from the production version.
class SettingsScreen extends StatefulWidget {
  final User user;

  const SettingsScreen({super.key, required this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTheme = 'light';
  String _selectedLanguage =
      LanguageService.localeNotifier.value.languageCode;
  bool _isLoading = false;

  bool _reminderEmail = true;
  bool _reminderPush = true;

  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '08:00';

  bool _prefsLoaded = false;
  bool _notifLoaded = false;
  bool get _allLoaded => _prefsLoaded && _notifLoaded;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _loadNotificationSettings();
    LanguageService.localeNotifier.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    LanguageService.localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (!mounted) return;
    setState(() {
      _selectedLanguage = LanguageService.localeNotifier.value.languageCode;
    });
  }

  Future<void> _loadUserPreferences() async {
    try {
      final preferences = await AuthService.getUserPreferences();
      final rawTheme = preferences['theme'] as String?;
      final normalizedTheme =
          (rawTheme == 'dark' || rawTheme == 'light') ? rawTheme! : 'light';
      if (!mounted) return;
      setState(() {
        _selectedTheme = normalizedTheme;
        _prefsLoaded = true;
      });
    } catch (e) {
      if (mounted) setState(() => _prefsLoaded = true);
    }
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await AuthService.getUserPreferences();
      final legacyReminders = prefs['watering_reminders'] ?? true;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final ch = data?['wateringReminderChannels'];
        if (!mounted) return;
        setState(() {
          _quietHoursStart = data?['quietHours']?['start'] ?? '22:00';
          _quietHoursEnd = data?['quietHours']?['end'] ?? '08:00';
          if (ch is Map) {
            _reminderEmail = ch['email'] != false;
            _reminderPush = ch['push'] != false;
          } else {
            _reminderEmail = legacyReminders;
            _reminderPush = legacyReminders;
          }
          _notifLoaded = true;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _reminderEmail = legacyReminders;
          _reminderPush = legacyReminders;
          _notifLoaded = true;
        });
      }
    } catch (e) {
      print('Error loading notification settings: $e');
      if (mounted) setState(() => _notifLoaded = true);
    }
  }

  Future<void> _persistReminderChannels() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set(
        {
          'wateringReminderChannels': {
            'email': _reminderEmail,
            'push': _reminderPush,
          },
        },
        SetOptions(merge: true),
      );
      await AuthService.saveUserPreferences({
        'watering_reminders': _reminderEmail || _reminderPush,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToSaveReminderChannels(e.toString())),
          backgroundColor: BotanlyColors.red,
        ),
      );
    }
  }

  int _hourFrom(String value) => int.tryParse(value.split(':').first) ?? 0;
  int _minuteFrom(String value) => int.tryParse(value.split(':').last) ?? 0;
  String _formatTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Future<void> _openQuietHoursEditor() async {
    final l10n = AppLocalizations.of(context)!;
    final initialStart = TimeOfDay(
        hour: _hourFrom(_quietHoursStart),
        minute: _minuteFrom(_quietHoursStart));
    final initialEnd = TimeOfDay(
        hour: _hourFrom(_quietHoursEnd),
        minute: _minuteFrom(_quietHoursEnd));

    TimeOfDay start = initialStart;
    TimeOfDay end = initialEnd;

    final saved = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x73000000),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Future<void> pick(bool isStart) async {
              final picked = await showTimePicker(
                context: ctx,
                initialTime: isStart ? start : end,
              );
              if (picked != null) {
                setLocal(() {
                  if (isStart) {
                    start = picked;
                  } else {
                    end = picked;
                  }
                });
              }
            }

            String fmt(TimeOfDay t) => _formatTime(t.hour, t.minute);

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.quietHoursLabel,
                      style: GoogleFonts.fraunces(
                        fontSize: 19,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.3,
                        color: BotanlyColors.moss,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Notifications will be silenced between these times.',
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: BotanlyColors.inkMute,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _timeRow('Start', fmt(start), () => pick(true)),
                    const SizedBox(height: 12),
                    _timeRow('End', fmt(end), () => pick(false)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: BotanlyPrimaryButton(
                            label: l10n.save,
                            onPressed: () =>
                                Navigator.of(ctx).pop(true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: BotanlySecondaryButton(
                            label: l10n.cancel,
                            onPressed: () =>
                                Navigator.of(ctx).pop(false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true) {
      await _updateQuietHours(
        newStart: _formatTime(start.hour, start.minute),
        newEnd: _formatTime(end.hour, end.minute),
      );
    }
  }

  Widget _timeRow(String label, String value, VoidCallback onTap) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4A5C46),
            ),
          ),
        ),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8EB),
                  border: Border.all(
                      color: const Color(0xFFE4EBE1), width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1B2A18),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateQuietHours({String? newStart, String? newEnd}) async {
    final start = newStart ?? _quietHoursStart;
    final end = newEnd ?? _quietHoursEnd;

    setState(() {
      _quietHoursStart = start;
      _quietHoursEnd = end;
    });

    try {
      await NotificationService().updateQuietHours(start, end);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToUpdateQuietHours(e.toString())),
          backgroundColor: BotanlyColors.red,
        ),
      );
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changePasswordTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration:
                    InputDecoration(labelText: l10n.currentPassword),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.enterCurrentPassword;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.newPassword),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.enterNewPassword;
                  }
                  if (value.trim().length < 6) {
                    return l10n.passwordAtLeast6;
                  }
                  if (value.trim() ==
                      currentPasswordController.text.trim()) {
                    return l10n.newPasswordMustBeDifferent;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration:
                    InputDecoration(labelText: l10n.confirmNewPassword),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.confirmYourNewPassword;
                  }
                  if (value.trim() != newPasswordController.text.trim()) {
                    return l10n.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (shouldSubmit != true) {
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.changePassword(
        currentPassword: currentPasswordController.text.trim(),
        newPassword: newPasswordController.text.trim(),
      );

      // LEGACY SNACKBAR (disabled 2026-08-03) — success confirmation, not wanted.
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text(l10n.passwordChangedSuccessfully),
      //       backgroundColor: BotanlyColors.sage,
      //     ),
      //   );
      // }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorChangingPassword(e.toString())),
            backgroundColor: BotanlyColors.red,
          ),
        );
      }
    } finally {
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOutConfirmTitle),
        content: Text(l10n.signOutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: BotanlyColors.red),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await NotificationService().removeFCMToken();
      await AuthService.signOut();
      if (mounted) {
        if (mounted) context.go('/welcome');
      }
    }
  }


  // ─────────────────────── Build ───────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: BotanlyColors.cabinetBg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
          children: [
            _buildUserCard(l10n),
            const SizedBox(height: 18),
            BotanlySectionTitle(l10n.preferencesTitle),
            const SizedBox(height: 8),
            _buildPreferencesCard(l10n),
            const SizedBox(height: 18),
            BotanlySectionTitle(l10n.accountTitle),
            const SizedBox(height: 8),
            _buildAccountCard(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(AppLocalizations l10n) {
    return BotanlyCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BotanlyAvatar(letter: null, size: 60),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.user.displayName ?? l10n.userLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.fraunces(
                        fontSize: 21,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.4,
                        color: BotanlyColors.moss,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.user.email ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: BotanlyColors.inkMute,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: BotanlyLoggedChip(label: l10n.loggedIn),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(AppLocalizations l10n) {
    return BotanlyCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Reminders header block
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFFE4EBE1))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.wateringReminders,
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1B2A18),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.wateringRemindersBlockSub,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                    color: BotanlyColors.inkMute,
                  ),
                ),
              ],
            ),
          ),
          ..._buildPreferenceRows(l10n),
        ],
      ),
    );
  }

  List<Widget> _buildPreferenceRows(AppLocalizations l10n) {
    if (!_allLoaded) {
      return [
        BotanlyShimmer(
          child: Column(
            children: List.generate(5, (i) => ShimmerSettingsRow(
              showDivider: i < 4,
            )),
          ),
        ),
      ];
    }

    final rows = <Widget>[
      BotanlySettingsRow(
        title: l10n.emailRemindersTitle,
        subtitle: l10n.emailRemindersSub,
        trailing: BotanlySwitch(
          value: _reminderEmail,
          onChanged: (v) {
            setState(() => _reminderEmail = v);
            _persistReminderChannels();
          },
        ),
        onTap: () {
          setState(() => _reminderEmail = !_reminderEmail);
          _persistReminderChannels();
        },
      ),
      BotanlySettingsRow(
        title: l10n.pushNotificationsTitle,
        subtitle: l10n.pushNotificationsSub,
        trailing: BotanlySwitch(
          value: _reminderPush,
          onChanged: (v) {
            setState(() => _reminderPush = v);
            _persistReminderChannels();
          },
        ),
        onTap: () {
          setState(() => _reminderPush = !_reminderPush);
          _persistReminderChannels();
        },
      ),
      BotanlySettingsRow(
        title: l10n.quietHoursLabel,
        subtitle: '$_quietHoursStart — $_quietHoursEnd',
        trailing: const Icon(Icons.edit_outlined,
            size: 16, color: BotanlyColors.inkMute),
        onTap: _openQuietHoursEditor,
      ),
      BotanlySettingsRow(
        title: l10n.languageLabel,
        subtitle: _selectedLanguage == 'en'
            ? l10n.english
            : _selectedLanguage == 'es'
                ? l10n.spanish
                : _selectedLanguage == 'fr'
                    ? l10n.french
                    : _selectedLanguage == 'ru'
                        ? l10n.russian
                        : _selectedLanguage == 'uk'
                            ? l10n.ukrainian
                            : l10n.german,
        showDivider: false,
        trailing: _SelectPill<String>(
          value: _selectedLanguage,
          items: [
            _SelectItem('de', l10n.german),
            _SelectItem('en', l10n.english),
            _SelectItem('es', l10n.spanish),
            _SelectItem('fr', l10n.french),
            _SelectItem('ru', l10n.russian),
            _SelectItem('uk', l10n.ukrainian),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _selectedLanguage = v);
            LanguageService.setLanguage(v);
            AuthService.saveUserPreferences({'language': v});
          },
        ),
      ),
    ];

    return List.generate(rows.length, (i) {
      return StaggeredFadeUp(
        index: i,
        show: true,
        child: rows[i],
      );
    });
  }

  Widget _buildAccountCard(AppLocalizations l10n) {
    return BotanlyCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Column(
        children: [
          BotanlySettingsRow(
            leadingIcon: Icons.shield_outlined,
            leadingBg: BotanlyColors.bluePale,
            leadingFg: BotanlyColors.blue,
            title: l10n.changePasswordTitleRow,
            subtitle: l10n.changePasswordSubRow,
            trailing: const Icon(Icons.chevron_right,
                size: 18, color: BotanlyColors.inkMute),
            onTap: _isLoading ? null : _showChangePasswordDialog,
          ),
          BotanlySettingsRow(
            leadingIcon: Icons.logout_rounded,
            leadingBg: BotanlyColors.amberPale,
            leadingFg: BotanlyColors.amber,
            title: l10n.signOut,
            subtitle: l10n.signOutSubRow,
            showDivider: false,
            trailing: const Icon(Icons.chevron_right,
                size: 18, color: BotanlyColors.inkMute),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }
}

class _SelectItem<T> {
  final T value;
  final String label;
  const _SelectItem(this.value, this.label);
}

class _SelectPill<T> extends StatelessWidget {
  final T value;
  final List<_SelectItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _SelectPill({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final current = items.firstWhere(
      (e) => e.value == value,
      orElse: () => items.first,
    );
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final selected = await showMenu<T>(
            context: context,
            position: _menuPositionFromContext(context),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            items: items
                .map((e) => PopupMenuItem<T>(
                      value: e.value,
                      child: Text(
                        e.label,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: e.value == value
                              ? BotanlyColors.sage
                              : BotanlyColors.moss,
                        ),
                      ),
                    ))
                .toList(),
          );
          if (selected != null) onChanged(selected);
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8EB),
            border: Border.all(color: const Color(0xFFE4EBE1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                current.label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: BotanlyColors.moss,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: BotanlyColors.moss),
            ],
          ),
        ),
      ),
    );
  }

  RelativeRect _menuPositionFromContext(BuildContext ctx) {
    final overlay =
        Overlay.of(ctx).context.findRenderObject() as RenderBox?;
    final box = ctx.findRenderObject() as RenderBox?;
    if (overlay == null || box == null) return RelativeRect.fill;
    final position = box.localToGlobal(Offset.zero, ancestor: overlay);
    return RelativeRect.fromLTRB(
      position.dx,
      position.dy + box.size.height + 4,
      overlay.size.width - position.dx - box.size.width,
      0,
    );
  }
}

