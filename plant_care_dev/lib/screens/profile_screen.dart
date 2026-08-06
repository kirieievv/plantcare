import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/user_model.dart';
import 'package:plant_care/services/auth_service.dart';
import 'package:plant_care/services/notification_service.dart';
import 'package:plant_care/services/user_service.dart';
import 'package:plant_care/screens/paywall_screen.dart';
import 'package:plant_care/services/subscription_service.dart';
import 'package:plant_care/theme/botanly_theme.dart';
import 'package:plant_care/widgets/botanly_cabinet_kit.dart';
import 'package:plant_care/widgets/botanly_shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

/// Profile screen — UI from `Botanly /screens/profile_screen.html`.
/// Logic preserved 1:1 from production: load profile, edit (name/bio/location),
/// save via `UserService.updateUserProfile`, sign out.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;

  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await UserService.getCurrentUserProfile();
      if (!mounted) return;
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });

      if (profile != null) {
        _nameController.text = profile.name;
        _bioController.text = profile.bio ?? '';
        _locationController.text = profile.location ?? '';
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.nameCannotBeEmpty)));
      return;
    }

    try {
      await UserService.updateUserProfile(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
      );

      await _loadUserProfile();
      if (!mounted) return;
      setState(() => _isEditing = false);

      // LEGACY SNACKBAR (disabled 2026-08-03) — success confirmation, not wanted.
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text(l10n.profileUpdatedSuccessfully)),
      // );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorUpdatingProfile(e.toString()))),
      );
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
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await NotificationService().removeFCMToken();
      await AuthService.signOut();
      if (mounted) context.go('/welcome');
    }
  }

  void _cancelEdit() {
    setState(() => _isEditing = false);
    _loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: BotanlyColors.cabinetBg,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<SubscriptionInfo>(
          stream: SubscriptionService().stream,
          initialData: SubscriptionService().currentInfo,
          builder: (context, subSnap) {
            final subInfo = subSnap.data;
            if (_isLoading) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 112),
                children: const [
                  BotanlyShimmer(
                    child: Column(
                      children: [
                        ShimmerProfileHeader(),
                        SizedBox(height: 14),
                        ShimmerInfoCard(rows: 3),
                        SizedBox(height: 14),
                        ShimmerInfoCard(rows: 2),
                      ],
                    ),
                  ),
                ],
              );
            }
            final name = _userProfile?.name ?? l10n.plantLover;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 112),
              children: [
                if (subInfo != null) ...[
                  StaggeredFadeUp(
                    index: 0,
                    show: true,
                    child: _SubscriptionCard(
                      info: subInfo,
                      userName: name,
                      onUpgrade: () => showPaywall(context),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                StaggeredFadeUp(
                  index: 1,
                  show: true,
                  child: _buildProfileInfoCard(l10n),
                ),
                const SizedBox(height: 14),
                StaggeredFadeUp(
                  index: 2,
                  show: true,
                  child: _buildAccountInfoCard(l10n),
                ),
                const SizedBox(height: 14),
                StaggeredFadeUp(
                  index: 3,
                  show: true,
                  child: _buildSignOutRow(l10n),
                ),
                const SizedBox(height: 14),
                StaggeredFadeUp(
                  index: 4,
                  show: true,
                  child: _buildDeleteAccountRow(l10n),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────── Header card ───────────────────────

  Widget _buildHeaderCard(AppLocalizations l10n) {
    final name = _userProfile?.name ?? l10n.plantLover;
    final email = _userProfile?.email ?? '';
    final loc = _userProfile?.location;
    return BotanlyCard(
      child: Row(
        children: [
          BotanlyAvatar(letter: name.isNotEmpty ? name[0] : 'U', size: 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.fraunces(
                    fontSize: 21,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.4,
                    height: 1.15,
                    color: BotanlyColors.moss,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: BotanlyColors.inkMute,
                    ),
                  ),
                ],
                if (loc != null && loc.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: BotanlyColors.inkMute,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          loc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: BotanlyColors.inkMute,
                          ),
                        ),
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

  // ─────────────────────── Profile info card ───────────────────────

  Widget _buildProfileInfoCard(AppLocalizations l10n) {
    return BotanlyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BotanlySectionHead(
            icon: Icons.person_outline,
            title: l10n.profileInformation,
            trailing: BotanlyEditLink(
              label: _isEditing ? l10n.cancel : l10n.edit,
              icon: _isEditing ? Icons.close : Icons.edit_outlined,
              onTap: () {
                if (_isEditing) {
                  _cancelEdit();
                } else {
                  setState(() => _isEditing = true);
                }
              },
            ),
          ),
          const SizedBox(height: 6),
          if (_isEditing) _buildEditForm(l10n) else _buildInfoView(l10n),
        ],
      ),
    );
  }

  Widget _buildInfoView(AppLocalizations l10n) {
    return Column(
      children: [
        BotanlyInfoRow(
          icon: Icons.person_outline,
          label: l10n.name,
          value: _userProfile?.name,
        ),
        BotanlyInfoRow(
          icon: Icons.description_outlined,
          label: l10n.bio,
          value: _userProfile?.bio,
        ),
        BotanlyInfoRow(
          icon: Icons.location_on_outlined,
          label: l10n.location,
          value: _userProfile?.location,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildEditForm(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BotanlyFieldLabel(l10n.fullName),
          BotanlyInputShell(
            icon: Icons.person_outline,
            child: TextField(
              controller: _nameController,
              style: _fieldStyle(),
              cursorColor: BotanlyColors.sage,
              decoration: botanlyShellInputDecoration(),
            ),
          ),
          const SizedBox(height: 12),
          BotanlyFieldLabel(l10n.bio),
          BotanlyInputShell(
            icon: Icons.description_outlined,
            area: true,
            child: TextField(
              controller: _bioController,
              style: _fieldStyle(),
              cursorColor: BotanlyColors.sage,
              minLines: 3,
              maxLines: 5,
              decoration: botanlyShellInputDecoration(
                hint: l10n.bioHint,
                hintStyle: _hintStyle(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          BotanlyFieldLabel(l10n.location),
          BotanlyInputShell(
            icon: Icons.location_on_outlined,
            child: TextField(
              controller: _locationController,
              style: _fieldStyle(),
              cursorColor: BotanlyColors.sage,
              decoration: botanlyShellInputDecoration(
                hint: l10n.locationHint,
                hintStyle: _hintStyle(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: BotanlyPrimaryButton(
                  label: l10n.save,
                  onPressed: _saveProfile,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BotanlySecondaryButton(
                  label: l10n.cancel,
                  onPressed: _cancelEdit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _fieldStyle() => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF1B2A18),
  );

  TextStyle _hintStyle() => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: BotanlyColors.inkMute,
  );

  // ─────────────────────── Account info card ───────────────────────

  Widget _buildAccountInfoCard(AppLocalizations l10n) {
    final memberSince = _userProfile?.createdAt != null
        ? DateFormat('MMM yyyy').format(_userProfile!.createdAt!)
        : l10n.notAvailable;
    final lastLogin = _userProfile?.lastLogin != null
        ? DateFormat('MMM dd, yyyy').format(_userProfile!.lastLogin!)
        : l10n.notAvailable;
    return BotanlyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BotanlySectionHead(
            icon: Icons.account_circle_outlined,
            title: l10n.accountInfo,
          ),
          const SizedBox(height: 6),
          BotanlyInfoRow(
            icon: Icons.calendar_today_outlined,
            label: l10n.memberSince,
            value: memberSince,
          ),
          BotanlyInfoRow(
            icon: Icons.access_time_rounded,
            label: l10n.lastLogin,
            value: lastLogin,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutRow(AppLocalizations l10n) {
    return BotanlyCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _signOut,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: BotanlyColors.redPale,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 14,
                    color: BotanlyColors.red,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.signOut,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: BotanlyColors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountRow(AppLocalizations l10n) {
    return BotanlyCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _deleteAccount,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BotanlyColors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    size: 14,
                    color: BotanlyColors.red,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.deleteAccountTitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: BotanlyColors.red,
                        ),
                      ),
                      Text(
                        l10n.deleteAccountSubtitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: BotanlyColors.inkMute,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: BotanlyColors.inkMute,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;

    // Step 1: first confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.deleteAccountTitle,
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Text(
          l10n.deleteAccountConfirmBody,
          style: GoogleFonts.dmSans(fontSize: 14, color: BotanlyColors.inkMute),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: GoogleFonts.dmSans()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: BotanlyColors.red),
            child: Text(
              l10n.delete,
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Step 2: second confirmation — type "DELETE"
    final controller = TextEditingController();
    final doubleConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            l10n.deleteAccountAreYouSure,
            style: GoogleFonts.fraunces(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.deleteAccountTypeConfirm,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: BotanlyColors.inkMute,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                onChanged: (_) => setS(() {}),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'DELETE',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel, style: GoogleFonts.dmSans()),
            ),
            TextButton(
              onPressed: controller.text.trim() == 'DELETE'
                  ? () => Navigator.pop(ctx, true)
                  : null,
              style: TextButton.styleFrom(foregroundColor: BotanlyColors.red),
              child: Text(
                l10n.deleteAccountConfirmBtn,
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
    controller.dispose();

    if (doubleConfirmed != true || !mounted) return;

    // Show full-screen loader — cannot be dismissed by user
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: ColoredBox(
          color: Colors.white,
          child: Center(
            child: CircularProgressIndicator(
              color: BotanlyColors.sage,
              strokeWidth: 2.5,
            ),
          ),
        ),
      ),
    );

    try {
      await NotificationService().removeFCMToken();
      final callable = FirebaseFunctions.instance.httpsCallable(
        'deleteAccount',
      );
      await callable.call();
      await AuthService.signOut();
      if (mounted) context.go('/welcome');
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorDeletingAccount(e.toString()),
            ),
          ),
        );
      }
    }
  }
}

// ─────────────────────── Subscription Card ───────────────────────

class _SubscriptionCard extends StatefulWidget {
  final SubscriptionInfo info;
  final String userName;
  final VoidCallback onUpgrade;

  const _SubscriptionCard({
    required this.info,
    required this.userName,
    required this.onUpgrade,
  });

  @override
  State<_SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<_SubscriptionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sparkle;

  @override
  void initState() {
    super.initState();
    _sparkle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    if (widget.info.status == SubscriptionStatus.active) _sparkle.repeat();
  }

  @override
  void dispose() {
    _sparkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final info = widget.info;
    final isTrial = info.status == SubscriptionStatus.trial;
    final isActive = info.status == SubscriptionStatus.active;
    final isExpired = info.status == SubscriptionStatus.expired;
    final isGrandfathered = info.status == SubscriptionStatus.grandfathered;

    final Color accentColor;
    final Color pillBg;
    final Color pillFg;
    final Color leafC1;
    final Color leafC2;
    final double topGradOpacity;

    if (isActive) {
      accentColor = BotanlyColors.sage;
      pillBg = BotanlyColors.sage;
      pillFg = Colors.white;
      leafC1 = const Color(0xFFCDEE9B);
      leafC2 = BotanlyColors.sage;
      topGradOpacity = 0.28;
    } else if (isGrandfathered) {
      accentColor = const Color(0xFFC08E3C);
      pillBg = const Color(0xFFF6ECD6);
      pillFg = const Color(0xFFC08E3C);
      leafC1 = const Color(0xFFF3DD9A);
      leafC2 = const Color(0xFFA47626);
      topGradOpacity = 0.18;
    } else if (isExpired) {
      accentColor = BotanlyColors.amber;
      pillBg = BotanlyColors.amberPale;
      pillFg = BotanlyColors.amber;
      leafC1 = const Color(0xFFF3C876);
      leafC2 = BotanlyColors.amber;
      topGradOpacity = 0.18;
    } else {
      accentColor = BotanlyColors.sageDark;
      pillBg = const Color(0xFFE3F1D6);
      pillFg = BotanlyColors.sageDark;
      leafC1 = const Color(0xFFCDEE9B);
      leafC2 = BotanlyColors.sage;
      topGradOpacity = 0.18;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F2D3D2A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTop(
            l10n,
            info,
            isTrial,
            isActive,
            isExpired,
            isGrandfathered,
            accentColor,
            pillBg,
            pillFg,
            leafC1,
            leafC2,
            topGradOpacity,
          ),
          _buildFoot(
            l10n,
            info,
            isTrial,
            isActive,
            isExpired,
            isGrandfathered,
            accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTop(
    AppLocalizations l10n,
    SubscriptionInfo info,
    bool isTrial,
    bool isActive,
    bool isExpired,
    bool isGrandfathered,
    Color accentColor,
    Color pillBg,
    Color pillFg,
    Color leafC1,
    Color leafC2,
    double topGradOpacity,
  ) {
    final String pillLabel;
    final IconData pillIcon;
    final String monoMeta;

    if (isActive) {
      pillLabel = l10n.subPillPremium;
      pillIcon = Icons.check_rounded;
      monoMeta = l10n.subMetaActivePlan;
    } else if (isGrandfathered) {
      pillLabel = l10n.subPillEarlyMember;
      pillIcon = Icons.star_rounded;
      monoMeta = l10n.subMetaForeverPremium;
    } else if (isExpired) {
      pillLabel = l10n.subPillFreePlan;
      pillIcon = Icons.lock_outline_rounded;
      monoMeta = l10n.subMetaTrialEnded;
    } else {
      pillLabel = l10n.subPillFreeTrial;
      pillIcon = Icons.schedule_rounded;
      monoMeta = l10n.subMetaNDayPreview(info.config.trialDays);
    }

    return Stack(
      children: [
        Container(color: Colors.white),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-1.4, -1.4),
                radius: 2.2,
                colors: [
                  accentColor.withValues(alpha: topGradOpacity),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        if (isActive)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.6, -1.4),
                  radius: 2.0,
                  colors: [
                    BotanlyColors.sageLight.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          top: -22,
          right: -18,
          child: Opacity(
            opacity: 0.35,
            child: CustomPaint(
              size: const Size(120, 120),
              painter: _LeafPainter(color1: leafC1, color2: leafC2),
            ),
          ),
        ),
        if (isActive) ...[
          Positioned(
            top: 14,
            right: 74,
            child: _buildSparkle(0, BotanlyColors.sage),
          ),
          Positioned(
            top: 46,
            right: 50,
            child: _buildSparkle(800, BotanlyColors.sageLight),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusPill(pillLabel, pillIcon, pillBg, pillFg),
                  const Spacer(),
                  Text(
                    monoMeta,
                    style: GoogleFonts.dmMono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: BotanlyColors.inkMute,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (isTrial || isExpired)
                _buildHeroBody(l10n, info, isTrial, accentColor)
              else
                _buildTextBody(
                  l10n,
                  info,
                  isActive,
                  isGrandfathered,
                  accentColor,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill(String label, IconData icon, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBody(
    AppLocalizations l10n,
    SubscriptionInfo info,
    bool isTrial,
    Color accentColor,
  ) {
    final int days = isTrial ? (info.trialDaysRemaining ?? 0) : 0;
    final DateTime? date = isTrial ? info.trialExpiresAt : info.expiresAt;
    final Color numColor = isTrial
        ? BotanlyColors.moss
        : const Color(0xFFA47626);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$days',
              style: GoogleFonts.fraunces(
                fontSize: 68,
                fontWeight: FontWeight.w500,
                letterSpacing: -2.5,
                height: 0.85,
                color: numColor,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                l10n.subDaysLeft,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: BotanlyColors.inkMute,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isTrial ? l10n.subUntilPreviewEnds : l10n.subTrialEnded,
              textAlign: TextAlign.right,
              style: GoogleFonts.fraunces(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: BotanlyColors.moss,
                letterSpacing: -0.2,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (date != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 11,
                    color: BotanlyColors.inkMute,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(date),
                    style: GoogleFonts.dmSans(
                      fontSize: 11.5,
                      color: BotanlyColors.inkMute,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTextBody(
    AppLocalizations l10n,
    SubscriptionInfo info,
    bool isActive,
    bool isGrandfathered,
    Color accentColor,
  ) {
    final String line2;
    final IconData line2Icon;

    if (isActive) {
      final daysLeft = info.expiresAt?.difference(DateTime.now()).inDays;
      final renewDate = info.expiresAt != null
          ? DateFormat('MMM d').format(info.expiresAt!)
          : null;
      if (daysLeft != null && renewDate != null) {
        line2 = info.autoRenewEnabled
            ? l10n.subRenewsInDays(daysLeft, renewDate)
            : l10n.subEndsInDays(daysLeft, renewDate);
      } else {
        line2 = l10n.subActiveSubscription;
      }
      line2Icon = Icons.schedule_rounded;
    } else {
      line2 = l10n.subGrantedEarlyMember;
      line2Icon = Icons.star_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              if (isActive)
                TextSpan(
                  text: l10n.subHeroYourePrefix,
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: BotanlyColors.moss,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
              TextSpan(
                text: isActive
                    ? l10n.subHeroGrowingWord
                    : l10n.subHeroForeverWord,
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: accentColor,
                  letterSpacing: -0.3,
                  height: 1.2,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (isGrandfathered)
                TextSpan(
                  text: l10n.subHeroPremiumSuffix,
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: BotanlyColors.moss,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(line2Icon, size: 11, color: BotanlyColors.inkMute),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                line2,
                style: GoogleFonts.dmSans(
                  fontSize: 11.5,
                  color: BotanlyColors.inkMute,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFoot(
    AppLocalizations l10n,
    SubscriptionInfo info,
    bool isTrial,
    bool isActive,
    bool isExpired,
    bool isGrandfathered,
    Color accentColor,
  ) {
    final String perks;
    final String ctaLabel;
    final Color ctaBg;
    final Color ctaFg;
    final bool isGhost;
    final VoidCallback? onCtaTap;

    if (isActive) {
      perks = info.autoRenewEnabled
          ? l10n.subAutoRenewOn
          : l10n.subAutoRenewOff;
      ctaLabel = l10n.subscriptionManage;
      ctaBg = Colors.transparent;
      ctaFg = BotanlyColors.sageDark;
      isGhost = true;
      onCtaTap = () => _showManageSheet(context, widget.info);
    } else if (isGrandfathered) {
      perks = l10n.subNoChargesEver;
      ctaLabel = l10n.subDetails;
      ctaBg = Colors.transparent;
      ctaFg = accentColor;
      isGhost = true;
      onCtaTap = () => _showManageSheet(context, widget.info);
    } else if (isExpired) {
      perks = l10n.subLimitedAccess;
      ctaLabel = l10n.subReactivate;
      ctaBg = BotanlyColors.moss;
      ctaFg = Colors.white;
      isGhost = false;
      onCtaTap = widget.onUpgrade;
    } else {
      perks = l10n.subUnlimitedAccess;
      ctaLabel = l10n.subscriptionUpgrade;
      ctaBg = BotanlyColors.sage;
      ctaFg = Colors.white;
      isGhost = false;
      onCtaTap = widget.onUpgrade;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4EBE1), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              perks,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: BotanlyColors.inkMute,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onCtaTap,
            child: isGhost
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ctaLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ctaFg,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 14, color: ctaFg),
                    ],
                  )
                : Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: ctaBg,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: ctaBg.withValues(alpha: 0.32),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ctaLabel,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ctaFg,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 12,
                          color: ctaFg,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSparkle(int delayMs, Color color) {
    return AnimatedBuilder(
      animation: _sparkle,
      builder: (_, __) {
        final t = (_sparkle.value + delayMs / 3200.0) % 1.0;
        final pulse = 0.5 - 0.5 * math.cos(t * 2 * math.pi);
        return Opacity(
          opacity: (0.3 + 0.7 * pulse).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.9 + 0.1 * pulse,
            child: Icon(Icons.lens_blur_rounded, size: 14, color: color),
          ),
        );
      },
    );
  }
}

// ─────────────────────── Manage Sheet ────────────────────────

void _showManageSheet(BuildContext context, SubscriptionInfo info) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ManageSubscriptionSheet(info: info),
  );
}

class _ManageSubscriptionSheet extends StatefulWidget {
  final SubscriptionInfo info;
  const _ManageSubscriptionSheet({required this.info});

  @override
  State<_ManageSubscriptionSheet> createState() =>
      _ManageSubscriptionSheetState();
}

class _ManageSubscriptionSheetState extends State<_ManageSubscriptionSheet> {
  bool _portalLoading = false;

  Future<void> _openAppStoreSubscriptions() async {
    const url = 'https://apps.apple.com/account/subscriptions';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openStripeBillingPortal() async {
    setState(() => _portalLoading = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'createPortalSession',
      );
      final result = await callable.call({
        'returnUrl': 'https://botanly.tech/home',
      });
      final url = result.data['url'] as String?;
      if (url == null) throw Exception('No portal URL returned');
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        if (kIsWeb) {
          await launchUrl(uri, webOnlyWindowName: '_self');
        } else {
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.errorOpeningBillingPortal(e.toString()),
            style: GoogleFonts.dmSans(fontSize: 13),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _portalLoading = false);
    }
  }

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@botanly.app',
      query: 'subject=Subscription Help',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await Clipboard.setData(const ClipboardData(text: 'support@botanly.app'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.emailCopied,
            style: GoogleFonts.dmSans(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final info = widget.info;
    final isGrandfathered = info.status == SubscriptionStatus.grandfathered;
    final renewalDate = info.expiresAt != null
        ? DateFormat('MMM d, yyyy').format(info.expiresAt!)
        : null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD8E4D3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isGrandfathered ? l10n.yourPlan : l10n.manageSubscription,
                    style: GoogleFonts.fraunces(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: BotanlyColors.ink,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F5F1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: BotanlyColors.inkMute,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF3EC)),

          // Plan info card
          _SheetSection(
            children: [
              _SheetInfoRow(
                icon: Icons.workspace_premium_rounded,
                iconColor: isGrandfathered
                    ? const Color(0xFFC08E3C)
                    : BotanlyColors.sage,
                label: l10n.labelPlan,
                value: isGrandfathered
                    ? l10n.labelGrandfathered
                    : l10n.labelPremium,
              ),
              if (renewalDate != null) ...[
                const _SheetDivider(),
                _SheetInfoRow(
                  icon: isGrandfathered
                      ? Icons.all_inclusive_rounded
                      : Icons.autorenew_rounded,
                  iconColor: isGrandfathered
                      ? const Color(0xFFC08E3C)
                      : BotanlyColors.sage,
                  label: isGrandfathered
                      ? l10n.labelExpires
                      : l10n.labelNextRenewal,
                  value: renewalDate,
                ),
              ],
              if (!isGrandfathered) ...[
                const _SheetDivider(),
                _SheetInfoRow(
                  icon: info.autoRenewEnabled
                      ? Icons.check_circle_outline_rounded
                      : Icons.cancel_outlined,
                  iconColor: info.autoRenewEnabled
                      ? BotanlyColors.sage
                      : BotanlyColors.amber,
                  label: l10n.labelAutoRenewal,
                  value: info.autoRenewEnabled ? l10n.labelOn : l10n.labelOff,
                  valueColor: info.autoRenewEnabled
                      ? BotanlyColors.sage
                      : BotanlyColors.amber,
                ),
              ],
            ],
          ),

          if (!isGrandfathered) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: GestureDetector(
                onTap: (kIsWeb || widget.info.stripeSubscriptionId != null)
                    ? (_portalLoading ? null : _openStripeBillingPortal)
                    : _openAppStoreSubscriptions,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: BotanlyColors.moss,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: BotanlyColors.moss.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _portalLoading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              (kIsWeb ||
                                      widget.info.stripeSubscriptionId != null)
                                  ? l10n.manageBillingWeb
                                  : l10n.manageInAppStore,
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.open_in_new_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          ],
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                kIsWeb
                    ? l10n.manageBillingSubtitleWeb
                    : (widget.info.stripeSubscriptionId != null
                          ? l10n.manageBillingSubtitleWeb
                          : l10n.manageBillingSubtitleAppStore),
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: BotanlyColors.inkMute,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Sheet helper widgets ──────────────────────────────────────

class _SheetSection extends StatelessWidget {
  final List<Widget> children;
  final double topPadding;
  const _SheetSection({required this.children, this.topPadding = 16});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAF6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4EBE1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _SheetDivider extends StatelessWidget {
  const _SheetDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 44, color: Color(0xFFE4EBE1));
}

class _SheetInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  const _SheetInfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: BotanlyColors.inkMute,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? BotanlyColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Leaf Painter ────────────────────────

class _LeafPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  const _LeafPainter({required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color1, color2],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final sx = size.width / 100;
    final sy = size.height / 100;

    final path = Path()
      ..moveTo(55 * sx, 90 * sy)
      ..quadraticBezierTo(20 * sx, 65 * sy, 50 * sx, 30 * sy)
      ..cubicTo(70 * sx, 25 * sy, 80 * sx, 22 * sy, 90 * sx, 10 * sy)
      ..relativeCubicTo(2 * sx, 22 * sy, 4 * sx, 38 * sy, -4 * sx, 52 * sy)
      ..relativeCubicTo(-7 * sx, 14 * sy, -22 * sx, 22 * sy, -31 * sx, 25 * sy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LeafPainter old) =>
      old.color1 != color1 || old.color2 != color2;
}
