/// Profile — subscription, details, account, and the two ways out (v4, stage 5).
library;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/user_model.dart';
import 'package:plant_care/screens/paywall_screen.dart';
import 'package:plant_care/services/auth_service.dart';
import 'package:plant_care/services/notification_service.dart';
import 'package:plant_care/services/subscription_service.dart';
import 'package:plant_care/services/user_service.dart';
import 'package:plant_care/services/weather_service.dart';
import 'package:plant_care/widgets/city_picker_sheet.dart';
import 'package:plant_care/theme/botanly_glass.dart';
import 'package:plant_care/widgets/botanly_kit.dart';
import 'package:plant_care/widgets/botanly_sheet.dart';
import 'package:plant_care/widgets/botanly_subscription_card.dart';

class ProfileV4Screen extends StatefulWidget {
  const ProfileV4Screen({super.key});

  @override
  State<ProfileV4Screen> createState() => _ProfileV4ScreenState();
}

class _ProfileV4ScreenState extends State<ProfileV4Screen> {
  final _name = TextEditingController();
  final _bio = TextEditingController();

  UserModel? _profile;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  String? _nameError;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final profile = await UserService.getCurrentUserProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
        _name.text = profile?.name ?? '';
        _bio.text = profile?.bio ?? '';
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = l10n.nameCannotBeEmpty);
      return;
    }

    setState(() {
      _saving = true;
      _nameError = null;
    });
    try {
      await UserService.updateUserProfile(
        name: name,
        bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
      );
      await _load();
      if (!mounted) return;
      setState(() => _editing = false);
      showBotanlyToast(context, l10n.profileUpdatedSuccessfully);
    } catch (e) {
      if (!mounted) return;
      showBotanlyToast(
        context,
        l10n.errorUpdatingProfile(e.toString()),
        success: false,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── subscription ──────────────────────────────────────────────────────────

  void _openSubscription(SubscriptionInfo info) {
    if (info.isActive) {
      _openManageSheet(info);
    } else {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
    }
  }

  void _openManageSheet(SubscriptionInfo info) {
    final grandfathered = info.status == SubscriptionStatus.grandfathered;

    showBotanlySheet<void>(
      context: context,
      builder: (sheetContext) => BotanlySheet(
        header: BotanlySheetHeader(
          glyph: grandfathered ? BotanlySvg.sparkle : BotanlySvg.check,
          tint: grandfathered ? kGlassSunBg : kGlassLeafBg,
          foreground: grandfathered ? kGlassAttnText : kGlassGreenText,
          title: l10n.subscriptionManageTitle,
        ),
        children: [
          // The early member has no billing to explain, so their sheet says so
          // instead of showing an empty renewal row.
          if (grandfathered)
            _SheetRow(
              label: l10n.subPillEarlyMember,
              value: l10n.subGrantedEarlyMember,
            )
          else ...[
            _SheetRow(
              label: l10n.subscriptionPlanLabel,
              value: l10n.subPillPremium,
            ),
            if (info.expiresAt != null)
              _SheetRow(
                label: l10n.subscriptionNextChargeLabel,
                value: botanlyDate(sheetContext, info.expiresAt!),
              ),
            _SheetRow(
              label: l10n.subscriptionAutoRenewLabel,
              value: info.autoRenewEnabled
                  ? l10n.subscriptionAutoRenewOn
                  : l10n.subscriptionAutoRenewOff,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.subscriptionManageInStore,
              style: glassFont(fontSize: 13, height: 1.5, color: kGlassMut),
            ),
          ],
        ],
      ),
    );
  }

  // ── leaving ───────────────────────────────────────────────────────────────

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

  /// Two steps: what disappears, then the word. The button stays dead until the
  /// word matches exactly — this is the one place in the app where a stray tap
  /// must not be able to finish the job.
  Future<void> _deleteAccount() async {
    final ready = await showBotanlySheet<bool>(
      context: context,
      builder: (_) => BotanlySheet(
        header: BotanlySheetHeader(
          glyph: BotanlySvg.trash,
          tint: kGlassWarmBg,
          foreground: kGlassAlert,
          title: l10n.deleteAccountTitle,
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
                label: l10n.deleteAccountContinue,
                kind: BotanlyButtonKind.destructive,
                onTap: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
        children: [
          Text(
            l10n.deleteAccountConfirmBody,
            style: glassFont(fontSize: 15, height: 1.6, color: kGlassInk2),
          ),
        ],
      ),
    );

    if (ready != true || !mounted) return;

    final keyword = l10n.deleteAccountKeyword;
    final confirmed = await showBotanlySheet<bool>(
      context: context,
      builder: (_) => _DeleteConfirmSheet(keyword: keyword),
    );

    if (confirmed != true || !mounted) return;
    await _performDelete();
  }

  Future<void> _performDelete() async {
    setState(() => _saving = true);
    try {
      await NotificationService().removeFCMToken();
      await FirebaseFunctions.instance.httpsCallable('deleteAccount').call();
      await AuthService.signOut();
      if (mounted) context.go('/welcome');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showBotanlyToast(
        context,
        l10n.errorDeletingAccount(e.toString()),
        success: false,
      );
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final email = _profile?.email ?? FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      backgroundColor: const Color(0xFFEDF0EC),
      body: Stack(
        children: [
          const Positioned.fill(child: BotanlyBackground()),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: kGlassAccent),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      children: [
                        _header(email),
                        const SizedBox(height: 16),
                        StreamBuilder<SubscriptionInfo>(
                          stream: SubscriptionService().stream,
                          initialData: SubscriptionService().currentInfo,
                          builder: (context, snap) {
                            final info = snap.data;
                            // A card that disappears while its stream warms up
                            // reads as "you have no subscription", which is the
                            // one thing it must never say by accident.
                            if (info == null) {
                              return GlassSurface(
                                padding: const EdgeInsets.all(16),
                                child: SizedBox(
                                  height: 96,
                                  child: Center(
                                    child: Text(
                                      l10n.subscriptionLoading,
                                      style: glassFont(
                                        fontSize: 13,
                                        color: kGlassMut,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return BotanlySubscriptionCard(
                              info: info,
                              onPrimary: () => _openSubscription(info),
                            );
                          },
                        ),
                        BotanlySectionLabel(l10n.profileInformation),
                        _profileCard(),
                        BotanlySectionLabel(l10n.profileCityLabel),
                        _locationCard(),
                        BotanlySectionLabel(l10n.accountInfo),
                        _accountCard(email),
                        const SizedBox(height: 18),
                        BotanlyListRow(
                          glyph: BotanlySvg.close,
                          glyphBg: kGlassWarmBg,
                          glyphColor: kGlassAlert,
                          title: l10n.signOut,
                          onTap: _signOut,
                        ),
                        const SizedBox(height: 9),
                        BotanlyListRow(
                          glyph: BotanlySvg.trash,
                          glyphBg: kGlassWarmBg,
                          glyphColor: kGlassAlert,
                          title: l10n.deleteAccountTitle,
                          subtitle: l10n.deleteAccountSubtitle,
                          onTap: _deleteAccount,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// City and units.
  ///
  /// The only place in the app that explains where the city came from — hence
  /// the "detected from network" line rather than a tooltip somewhere else.
  /// Editing it pins `source: manual`, after which no IP lookup overwrites it.
  Widget _locationCard() {
    final l10n = AppLocalizations.of(context)!;
    final reading = WeatherService().current;
    final city = reading?.location?.city;

    return GlassSurface(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          BotanlyListRow(
            glyph: BotanlySvg.pin,
            title: l10n.profileCityLabel,
            subtitle: city == null
                ? l10n.profileCityHint
                // Two facts, one line: what it is and where it came from.
                : '$city · ${reading!.location!.isManual ? l10n.profileCityHint : l10n.weatherDetectedByNetwork}',
            onTap: _editCity,
          ),
        ],
      ),
    );
  }

  Future<void> _editCity() async {
    final chosen = await showCityPicker(context);
    if (chosen == null || !mounted) return;

    // The suggestion brought its own coordinates, so this is a real move: the
    // weather is re-read for the new place rather than relabelled.
    await WeatherService().setManualCity(chosen.toLocation());
    if (!mounted) return;
    setState(() {});
    showBotanlyToast(context, AppLocalizations.of(context)!.cityUpdated);
  }

  Widget _header(String? email) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: kGlassLeafBg,
              shape: BoxShape.circle,
            ),
            child: Text(
              _initials(_profile?.name ?? email ?? '?'),
              style: glassFont(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: kGlassGreenText,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile?.name.isNotEmpty == true
                      ? _profile!.name
                      : l10n.profileInformation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: glassFont(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 24 * -0.03,
                    color: kGlassInk,
                  ),
                ),
                if (email != null) ...[
                  const SizedBox(height: 3),
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
        ],
      ),
    );
  }

  static String _initials(String source) {
    final parts = source.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  Widget _profileCard() {
    return GlassSurface(
      padding: const EdgeInsets.all(16),
      child: _editing ? _editForm() : _profileView(),
    );
  }

  Widget _profileView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.profileInformation,
                style: glassFont(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 15.5 * -0.02,
                  color: kGlassInk,
                ),
              ),
            ),
            BotanlyPress(
              onTap: () => setState(() => _editing = true),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BotanlyGlyph(
                    BotanlySvg.edit,
                    size: 15,
                    color: kGlassGreenText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.edit,
                    style: glassFont(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kGlassGreenText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Field(label: l10n.name, value: _profile?.name ?? '—'),
        // No location row: the city has its own card right below, where it can
        // carry coordinates and drive the weather. Two fields for one fact left
        // the user editing the one that changed nothing.
        _Field(label: l10n.bio, value: _emptyDash(_profile?.bio), last: true),
      ],
    );
  }

  static String _emptyDash(String? value) =>
      (value == null || value.trim().isEmpty) ? '—' : value;

  Widget _editForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.profileInformation,
          style: glassFont(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 15.5 * -0.02,
            color: kGlassInk,
          ),
        ),
        const SizedBox(height: 14),
        BotanlyField(
          controller: _name,
          hint: l10n.name,
          glyph: BotanlySvg.profile,
          errorText: _nameError,
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
        ),
        const SizedBox(height: 10),
        BotanlyField(
          controller: _bio,
          hint: l10n.bio,
          glyph: BotanlySvg.edit,
          maxLines: 3,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: BotanlyButton(
                label: l10n.cancel,
                kind: BotanlyButtonKind.ghost,
                onTap: _saving
                    ? null
                    : () {
                        setState(() {
                          _editing = false;
                          _nameError = null;
                          _name.text = _profile?.name ?? '';
                          _bio.text = _profile?.bio ?? '';
                        });
                      },
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: BotanlyButton(
                label: l10n.save,
                loading: _saving,
                onTap: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _accountCard(String? email) {
    final created = _profile?.createdAt;

    return GlassSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Field(
            label: l10n.memberSince,
            value: created == null ? '—' : botanlyDate(context, created),
          ),
          // No "last login": it is always the moment you opened the screen, so
          // it never says anything you did not already know.
          _Field(label: l10n.email, value: email ?? '—', last: true),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _Field({required this.label, required this.value, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 4),
        Text(
          value,
          style: glassFont(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: kGlassInk,
          ),
        ),
        if (!last) ...[
          const SizedBox(height: 12),
          const Divider(height: 0.5, thickness: 0.5, color: Color(0x14141E0F)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SheetRow extends StatelessWidget {
  final String label;
  final String value;

  const _SheetRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: glassFont(fontSize: 14, color: kGlassMut),
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: glassFont(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kGlassInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step two of deletion: the button only wakes up on an exact match.
class _DeleteConfirmSheet extends StatefulWidget {
  final String keyword;

  const _DeleteConfirmSheet({required this.keyword});

  @override
  State<_DeleteConfirmSheet> createState() => _DeleteConfirmSheetState();
}

class _DeleteConfirmSheetState extends State<_DeleteConfirmSheet> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final matches = _input.text.trim().toUpperCase() == widget.keyword;

    return BotanlySheet(
      header: BotanlySheetHeader(
        glyph: BotanlySvg.warningTriangle,
        tint: kGlassWarmBg,
        foreground: kGlassAlert,
        title: l10n.deleteAccountAreYouSure,
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
              label: l10n.deleteAccountConfirmBtn,
              kind: BotanlyButtonKind.destructive,
              onTap: matches ? () => Navigator.of(context).pop(true) : null,
            ),
          ),
        ],
      ),
      children: [
        Text(
          l10n.deleteAccountTypeWord(widget.keyword),
          style: glassFont(fontSize: 15, height: 1.6, color: kGlassInk2),
        ),
        const SizedBox(height: 12),
        BotanlyField(
          controller: _input,
          hint: widget.keyword,
          glyph: BotanlySvg.trash,
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}
