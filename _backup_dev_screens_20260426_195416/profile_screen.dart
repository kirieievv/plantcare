import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/botanly_theme.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _profile;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _locCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _locCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profile = await UserService.getCurrentUserProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
      if (profile != null) {
        _nameCtrl.text = profile.name;
        _bioCtrl.text = profile.bio ?? '';
        _locCtrl.text = profile.location ?? '';
      }
    });
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await UserService.updateUserProfile(
        name: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        location: _locCtrl.text.trim().isEmpty ? null : _locCtrl.text.trim(),
      );
      await _load();
      if (!mounted) return;
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Profile saved', style: GoogleFonts.dmSans(fontSize: 13)),
          backgroundColor: BotanlyColors.moss));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: BotanlyColors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign out?',
            style: GoogleFonts.fraunces(
              fontSize: 19,
              fontWeight: FontWeight.w400,
              color: BotanlyColors.moss,
            )),
        content: Text('You will be signed out of Botanly.',
            style: GoogleFonts.dmSans(fontSize: 13, color: BotanlyColors.inkMute)),
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

  String get _email =>
      _profile?.email ??
      FirebaseAuth.instance.currentUser?.email ??
      '';

  String get _location => _profile?.location ?? '';
  String get _bio => _profile?.bio ?? '';

  String get _memberSince {
    final created = FirebaseAuth.instance.currentUser?.metadata.creationTime;
    if (created == null) return '—';
    return DateFormat('MMM yyyy').format(created);
  }

  String get _lastLogin {
    final last =
        FirebaseAuth.instance.currentUser?.metadata.lastSignInTime;
    if (last == null) return '—';
    return DateFormat('MMM d, yyyy').format(last);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Material(
        color: Colors.white,
        child: Center(
          child: CircularProgressIndicator(color: BotanlyColors.sage),
        ),
      );
    }

    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          children: [
            _headerCard(),
            const SizedBox(height: 14),
            _profileInfoCard(),
            const SizedBox(height: 14),
            _accountInfoCard(),
            const SizedBox(height: 14),
            _actionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [BotanlyColors.sagePale2, BotanlyColors.sagePale],
              ),
            ),
            child: Center(
              child: Text(
                _displayName.isEmpty ? 'U' : _displayName[0].toUpperCase(),
                style: GoogleFonts.fraunces(
                  fontSize: 24,
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
                      height: 1.15,
                    )),
                const SizedBox(height: 3),
                Text(_email,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: BotanlyColors.inkMute,
                    )),
                if (_location.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: BotanlyColors.inkMute),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(_location,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: BotanlyColors.inkMute,
                            )),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectIcon(Icons.person_outline),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Profile information',
                    style: GoogleFonts.fraunces(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w400,
                      color: BotanlyColors.moss,
                      letterSpacing: -.2,
                    )),
              ),
              TextButton.icon(
                onPressed: () => setState(() {
                  _editing = !_editing;
                  if (_editing) {
                    _nameCtrl.text = _displayName;
                    _bioCtrl.text = _bio;
                    _locCtrl.text = _location;
                  }
                }),
                icon: Icon(_editing ? Icons.close : Icons.edit_outlined,
                    size: 13, color: BotanlyColors.sage),
                label: Text(_editing ? 'Close' : 'Edit',
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: BotanlyColors.sage,
                    )),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
          if (!_editing) ...[
            const SizedBox(height: 14),
            _infoRow(Icons.person_outline, 'NAME', _displayName),
            if (_bio.isNotEmpty)
              _infoRow(Icons.description_outlined, 'BIO', _bio),
            _infoRow(Icons.location_on_outlined, 'LOCATION',
                _location.isEmpty ? '—' : _location,
                last: true),
          ] else ...[
            const SizedBox(height: 14),
            _editField('Full name', Icons.person_outline, _nameCtrl),
            const SizedBox(height: 12),
            _editField('Bio', Icons.description_outlined, _bioCtrl,
                multiline: true),
            const SizedBox(height: 12),
            _editField('Location', Icons.location_on_outlined, _locCtrl),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BotanlyColors.sage,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                      shadowColor: BotanlyColors.sage.withOpacity(.3),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('Save',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            )),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _editing = false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: BotanlyColors.line, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.dmSans(
                          color: BotanlyColors.inkSoft,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        )),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _accountInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectIcon(Icons.account_circle_outlined),
              const SizedBox(width: 8),
              Text('Account info',
                  style: GoogleFonts.fraunces(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w400,
                    color: BotanlyColors.moss,
                    letterSpacing: -.2,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(
              Icons.calendar_today_outlined, 'MEMBER SINCE', _memberSince),
          _infoRow(Icons.access_time, 'LAST LOGIN', _lastLogin, last: true),
        ],
      ),
    );
  }

  Widget _actionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectIcon(Icons.settings_outlined),
              const SizedBox(width: 8),
              Text('Actions',
                  style: GoogleFonts.fraunces(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w400,
                    color: BotanlyColors.moss,
                    letterSpacing: -.2,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _signOut,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: BotanlyColors.redPale,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.logout,
                        size: 14, color: BotanlyColors.red),
                  ),
                  const SizedBox(width: 10),
                  Text('Sign out',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BotanlyColors.red,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectIcon(IconData icon) {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        color: BotanlyColors.sagePale2,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 15, color: BotanlyColors.sage),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: last
          ? null
          : const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: BotanlyColors.line))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: BotanlyColors.sageSoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 12, color: BotanlyColors.sage),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      letterSpacing: .4,
                      color: BotanlyColors.inkMute,
                    )),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.dmSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                      color: BotanlyColors.ink,
                      height: 1.45,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editField(String label, IconData icon, TextEditingController ctrl,
      {bool multiline = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(label.toUpperCase(),
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: .3,
                color: BotanlyColors.inkMute,
              )),
        ),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: 12, vertical: multiline ? 10 : 0),
          decoration: BoxDecoration(
            border: Border.all(color: BotanlyColors.line, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: multiline
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: multiline ? 3 : 0),
                child: Icon(icon, size: 15, color: BotanlyColors.sage),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  maxLines: multiline ? 3 : 1,
                  minLines: multiline ? 3 : 1,
                  style: GoogleFonts.dmSans(
                      fontSize: 14, color: BotanlyColors.ink),
                  decoration: const InputDecoration.collapsed(hintText: ''),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: BotanlyShadows.card,
      );
}
