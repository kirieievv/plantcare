import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/botanly_theme.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/notification_service.dart';
import '../services/theme_service.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'auth_screen.dart';
import 'forgot_password_email_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _email = true;
  bool _push = true;
  String _quietStart = '22:00';
  String _quietEnd = '08:00';
  String _theme = 'light';
  String _language = 'en';
  bool _loading = true;
  UserModel? _profile;

  static const _langNames = {
    'de': 'Deutsch',
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
  };

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final futures = await Future.wait([
        UserService.getCurrentUserProfile(),
        AuthService.getUserPreferences(),
      ]);
      final profile = futures[0] as UserModel?;
      final prefs = futures[1] as Map<String, dynamic>;

      final rawTheme = prefs['theme'] as String?;
      final rawLang = prefs['language'] as String?;
      final rawReminder = prefs['watering_reminders'];

      // Load per-channel settings from Firestore
      final uid = AuthService.currentUser?.uid;
      bool emailPref = rawReminder != false;
      bool pushPref = rawReminder != false;
      String quietStart = '22:00';
      String quietEnd = '08:00';

      if (uid != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          if (doc.exists) {
            final data = doc.data()!;
            final ch = data['wateringReminderChannels'];
            if (ch is Map) {
              emailPref = ch['email'] != false;
              pushPref = ch['push'] != false;
            }
            final qh = data['quietHours'];
            if (qh is Map) {
              quietStart = qh['start'] as String? ?? '22:00';
              quietEnd = qh['end'] as String? ?? '08:00';
            }
          }
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _theme =
            (rawTheme == 'dark' || rawTheme == 'light') ? rawTheme! : 'light';
        _language = ['en', 'de', 'es', 'fr'].contains(rawLang)
            ? rawLang!
            : 'en';
        _email = emailPref;
        _push = pushPref;
        _quietStart = quietStart;
        _quietEnd = quietEnd;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _persistChannels() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'wateringReminderChannels': {
            'email': _email,
            'push': _push,
          },
        },
        SetOptions(merge: true),
      );
      await AuthService.saveUserPreferences({
        'watering_reminders': _email || _push,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: BotanlyColors.red));
    }
  }

  Future<void> _saveTheme(String value) async {
    setState(() => _theme = value);
    try {
      await ThemeService.setThemePreference(value);
      await AuthService.saveUserPreferences({'theme': value});
    } catch (_) {}
  }

  Future<void> _saveLanguage(String value) async {
    setState(() => _language = value);
    try {
      await LanguageService.setLanguage(value);
      await AuthService.saveUserPreferences({'language': value});
    } catch (_) {}
  }

  Future<void> _showQuietHoursDialog() async {
    String start = _quietStart;
    String end = _quietEnd;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Quiet hours',
            style: GoogleFonts.fraunces(
              fontSize: 19,
              fontWeight: FontWeight.w400,
              color: BotanlyColors.moss,
              letterSpacing: -.3,
            )),
        content: StatefulBuilder(
          builder: (_, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Notifications will be silenced between these times.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    color: BotanlyColors.inkMute,
                  )),
              const SizedBox(height: 16),
              _timeField('Start', start, (v) => setLocal(() => start = v)),
              const SizedBox(height: 12),
              _timeField('End', end, (v) => setLocal(() => end = v)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.dmSans(color: BotanlyColors.inkSoft)),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _quietStart = start;
                _quietEnd = end;
              });
              Navigator.pop(ctx);
              try {
                await NotificationService().updateQuietHours(start, end);
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: BotanlyColors.sage),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out of Botanly?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign out',
                  style: TextStyle(color: BotanlyColors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    }
  }

  String get _displayName =>
      _profile?.name ??
      FirebaseAuth.instance.currentUser?.displayName ??
      'Plant Lover';

  String get _displayEmail =>
      _profile?.email ??
      FirebaseAuth.instance.currentUser?.email ??
      '';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Material(
        color: Colors.white,
        child: Center(child: CircularProgressIndicator(color: BotanlyColors.sage)),
      );
    }

    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          children: [
            _userCard(),
            const SizedBox(height: 18),
            Text('Preferences',
                style: GoogleFonts.fraunces(
                  fontSize: 19,
                  fontWeight: FontWeight.w400,
                  color: BotanlyColors.moss,
                  letterSpacing: -.3,
                )),
            const SizedBox(height: 8),
            _preferencesCard(),
            const SizedBox(height: 18),
            Text('Account',
                style: GoogleFonts.fraunces(
                  fontSize: 19,
                  fontWeight: FontWeight.w400,
                  color: BotanlyColors.moss,
                  letterSpacing: -.3,
                )),
            const SizedBox(height: 8),
            _accountCard(),
          ],
        ),
      ),
    );
  }

  Widget _userCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: BotanlyColors.sagePale2,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _displayName.isEmpty
                        ? '?'
                        : _displayName[0].toUpperCase(),
                    style: GoogleFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: BotanlyColors.sage,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_displayName,
                        style: GoogleFonts.fraunces(
                          fontSize: 21,
                          fontWeight: FontWeight.w400,
                          color: BotanlyColors.moss,
                          letterSpacing: -.4,
                        )),
                    const SizedBox(height: 2),
                    Text(_displayEmail,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: BotanlyColors.inkMute,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: BotanlyColors.sagePale2,
              border: Border.all(color: BotanlyColors.sagePale),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, color: BotanlyColors.sage, size: 13),
                const SizedBox(width: 5),
                Text('Logged in',
                    style: GoogleFonts.dmSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: BotanlyColors.sageDark,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _preferencesCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Watering reminders',
              style: GoogleFonts.dmSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: BotanlyColors.ink,
              )),
          const SizedBox(height: 2),
          Text('Get notified when your plants need water.',
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                color: BotanlyColors.inkMute,
                height: 1.4,
              )),
          const SizedBox(height: 6),
          const Divider(color: BotanlyColors.line, height: 14),
          _switchRow(
              'Email reminders',
              'Receive watering reminders by email',
              _email,
              (v) => setState(() {
                    _email = v;
                    _persistChannels();
                  })),
          const Divider(color: BotanlyColors.line, height: 1),
          _switchRow(
              'Push notifications',
              'Get instant alerts on your device',
              _push,
              (v) => setState(() {
                    _push = v;
                    _persistChannels();
                  })),
          const Divider(color: BotanlyColors.line, height: 1),
          _quietHoursRow(),
          const Divider(color: BotanlyColors.line, height: 1),
          _dropdownRow(
            label: 'Theme',
            currentLabel: _theme == 'light' ? 'Light' : 'Dark',
            value: _theme,
            options: const {'light': 'Light', 'dark': 'Dark'},
            onChanged: _saveTheme,
          ),
          const Divider(color: BotanlyColors.line, height: 1),
          _dropdownRow(
            label: 'Language',
            currentLabel: _langNames[_language] ?? _language,
            value: _language,
            options: _langNames,
            onChanged: _saveLanguage,
          ),
        ],
      ),
    );
  }

  Widget _switchRow(
      String t, String s, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t,
                    style: GoogleFonts.dmSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                      color: BotanlyColors.ink,
                    )),
                const SizedBox(height: 2),
                Text(s,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: BotanlyColors.inkMute,
                    )),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: BotanlyColors.sage,
          ),
        ],
      ),
    );
  }

  Widget _quietHoursRow() {
    return InkWell(
      onTap: _showQuietHoursDialog,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quiet hours',
                      style: GoogleFonts.dmSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        color: BotanlyColors.ink,
                      )),
                  const SizedBox(height: 2),
                  Text('$_quietStart — $_quietEnd',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: BotanlyColors.inkMute,
                      )),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined,
                size: 16, color: BotanlyColors.inkMute),
          ],
        ),
      ),
    );
  }

  Widget _dropdownRow({
    required String label,
    required String currentLabel,
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.dmSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                      color: BotanlyColors.ink,
                    )),
                const SizedBox(height: 2),
                Text(currentLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: BotanlyColors.inkMute,
                    )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: BotanlyColors.sageSoft,
              border: Border.all(color: BotanlyColors.line),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: value,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down,
                  size: 16, color: BotanlyColors.moss),
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: BotanlyColors.moss,
              ),
              items: options.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => v != null ? onChanged(v) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeField(
      String label, String value, ValueChanged<String> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: BotanlyColors.inkSoft,
              )),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: TextEditingController(text: value),
            onChanged: onChanged,
            keyboardType: TextInputType.datetime,
            style:
                GoogleFonts.dmSans(fontSize: 14, color: BotanlyColors.ink),
            decoration: InputDecoration(
              filled: true,
              fillColor: BotanlyColors.sageSoft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: BotanlyColors.line, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _accountCard() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _accountRow(
            icon: Icons.security_outlined,
            iconColor: BotanlyColors.blue,
            iconBg: BotanlyColors.bluePale,
            title: 'Change password',
            subtitle: 'Update your account password',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ForgotPasswordEmailScreen(),
                ),
              );
            },
          ),
          const Divider(color: BotanlyColors.line, height: 1),
          _accountRow(
            icon: Icons.logout,
            iconColor: BotanlyColors.amber,
            iconBg: BotanlyColors.amberPale,
            title: 'Sign out',
            subtitle: 'Sign out of your account',
            onTap: _signOut,
          ),
        ],
      ),
    );
  }

  Widget _accountRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.dmSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        color: BotanlyColors.ink,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: BotanlyColors.inkMute,
                      )),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: BotanlyColors.inkMute),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: BotanlyShadows.card,
      );
}
