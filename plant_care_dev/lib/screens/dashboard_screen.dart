import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/models/user_model.dart';
import 'package:plant_care/services/plant_service.dart';
import 'package:plant_care/services/user_service.dart';
import 'package:plant_care/screens/add_plant_screen.dart';
import 'package:plant_care/screens/plant_details_screen.dart';
import 'package:plant_care/screens/tips_screen.dart';
import 'package:plant_care/theme/botanly_theme.dart';
import 'package:plant_care/widgets/botanly_plant_tile.dart';
import 'package:plant_care/widgets/botanly_shimmer.dart';
import 'package:plant_care/l10n/app_localizations.dart';

/// Dashboard / Home — UI from `Botanly /screens/dashboard_screen.html`.
/// Logic is kept identical to the production version: cleanup on init,
/// load user profile, plants stream, watering action, navigation to add /
/// details. Visual blocks (header, stats row, banner carousel, plant list)
/// match the HTML prototype 1:1.
class DashboardScreen extends StatefulWidget {
  final User? user;
  final Function(int)? onTabChange;

  const DashboardScreen({super.key, this.user, this.onTabChange});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserModel? _userProfile;
  bool _isLoading = false;
  bool _hasRunCleanup = false;

  @override
  void initState() {
    super.initState();
    _runInitialCleanup();
  }

  Future<void> _runInitialCleanup() async {
    if (_hasRunCleanup) return;
    try {
      setState(() => _isLoading = true);
      await PlantService().cleanupCorruptedPlants();
      await _loadUserProfile();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasRunCleanup = true;
        });
      }
    } catch (e) {
      print('❌ Dashboard: Error during initial cleanup: $e');
      await _loadUserProfile();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasRunCleanup = true;
        });
      }
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await UserService.getCurrentUserProfile();
      if (!mounted) return;
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onAddPlantPressed() async {
    if (widget.onTabChange != null) {
      widget.onTabChange!(2);
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPlantScreen()),
    );
    if (result is Map && result['success'] == true) {
      final plantId = result['plantId'];
      print('🌱 Dashboard: Plant created successfully with ID: $plantId');
      if (!mounted) return;
      setState(() {});
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.plantCreatedSuccessfully),
          backgroundColor: BotanlyColors.sage,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: BotanlyColors.cabinetBg,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const _DashboardLoading()
            : ListView(
                padding: const EdgeInsets.only(bottom: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Header — "My Garden"
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [const _GardenTitle()],
                    ),
                  ),

                  // Stats row (3 cards)
                  StreamBuilder<List<Plant>>(
                    stream: PlantService().getPlants(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                          child: BotanlyShimmer(
                            child: Row(
                              children: const [
                                Expanded(child: ShimmerStatCard()),
                                SizedBox(width: 10),
                                Expanded(child: ShimmerStatCard()),
                                SizedBox(width: 10),
                                Expanded(child: ShimmerStatCard()),
                              ],
                            ),
                          ),
                        );
                      }
                      final plants = snapshot.data ?? const <Plant>[];
                      final now = DateTime.now();
                      final needWater = plants
                          .where((p) => p.nextWatering.isBefore(now))
                          .length;
                      final healthy = plants
                          .where(
                            (p) => p.nextWatering.isAfter(
                              now.add(const Duration(days: 1)),
                            ),
                          )
                          .length;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: '🌱',
                                iconBg: BotanlyColors.sagePale,
                                value: plants.length.toString(),
                                valueColor: BotanlyColors.sage,
                                label: l10n.totalPlants,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                icon: '💧',
                                iconBg: BotanlyColors.amberPale,
                                value: needWater.toString(),
                                valueColor: BotanlyColors.amber,
                                label: l10n.needWater,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                icon: '✓',
                                iconBg: BotanlyColors.sagePale,
                                iconColor: BotanlyColors.sage,
                                iconWeight: FontWeight.w700,
                                value: healthy.toString(),
                                valueColor: BotanlyColors.sageLight,
                                label: l10n.healthy,
                                highlighted: true,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Banner carousel (data-driven)
                  StreamBuilder<List<Plant>>(
                    stream: PlantService().getPlants(),
                    builder: (context, snapshot) {
                      final plants = snapshot.data ?? const <Plant>[];
                      final loaded = snapshot.hasData;
                      return Padding(
                        padding: const EdgeInsets.only(top: 22),
                        child: _BannerCarousel(
                          plants: plants,
                          plantsLoaded: loaded,
                        ),
                      );
                    },
                  ),

                  // Section header — My Plants + Add
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.yourPlants,
                          style: GoogleFonts.fraunces(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.2,
                            color: BotanlyColors.moss,
                          ),
                        ),
                        _AddPlantPillButton(
                          onPressed: _onAddPlantPressed,
                          label: l10n.addPlant,
                        ),
                      ],
                    ),
                  ),

                  // Plants list
                  StreamBuilder<List<Plant>>(
                    stream: PlantService().getPlants(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const _PlantsListSkeleton();
                      }
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text('Error: ${snapshot.error}'),
                          ),
                        );
                      }
                      final plants = snapshot.data ?? const <Plant>[];
                      if (plants.isEmpty) {
                        return _EmptyPlantsState(
                          l10n: l10n,
                          onAddPlant: widget.onTabChange != null
                              ? () => widget.onTabChange!(2)
                              : null,
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Column(
                          children: [
                            for (int i = 0; i < plants.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: StaggeredFadeUp(
                                  index: i,
                                  show: true,
                                  child: BotanlyPlantTile(
                                    plant: plants[i],
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PlantDetailsScreen(
                                          plant: plants[i],
                                        ),
                                      ),
                                    ),
                                    onWater: () =>
                                        PlantService().waterPlant(plants[i].id),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────── Header ───────────────────────

class _GardenTitle extends StatelessWidget {
  const _GardenTitle();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final raw = l10n.yourGardenOverview;
    // HTML prototype: "My <em>Garden</em>". We keep the HTML look by italicising
    // the *second* token of the localised string in sage. If only one token —
    // italicise the whole string in sage.
    final parts = raw.trim().split(RegExp(r'\s+'));
    final hasMultiple = parts.length >= 2;
    final main = hasMultiple ? '${parts.first} ' : '';
    final accent = hasMultiple ? parts.sublist(1).join(' ') : raw.trim();

    return RichText(
      text: TextSpan(
        children: [
          if (main.isNotEmpty)
            TextSpan(
              text: main,
              style: GoogleFonts.fraunces(
                fontSize: 28,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.56,
                height: 1.1,
                color: BotanlyColors.moss,
              ),
            ),
          TextSpan(
            text: accent,
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.56,
              height: 1.1,
              color: BotanlyColors.sage,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Stats ───────────────────────

class _StatCard extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final Color? iconColor;
  final FontWeight? iconWeight;
  final String value;
  final Color valueColor;
  final String label;
  final bool highlighted;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    this.iconColor,
    this.iconWeight,
    required this.value,
    required this.valueColor,
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        gradient: highlighted
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEAF4E6), Color(0xFFD8EDCF)],
              )
            : null,
        color: highlighted ? null : BotanlyColors.paper,
        border: Border.all(
          color: highlighted ? BotanlyColors.sagePale : BotanlyColors.sand,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Text(
              icon,
              style: TextStyle(
                fontSize: iconWeight == null ? 18 : 20,
                color: iconColor,
                fontWeight: iconWeight,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              height: 1,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w300,
              color: BotanlyColors.inkMute,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Banner carousel ───────────────────────

// ─────────────────────── Banner Carousel ───────────────────────

class _BannerCarousel extends StatefulWidget {
  final List<Plant> plants;
  final bool plantsLoaded;
  const _BannerCarousel({required this.plants, required this.plantsLoaded});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _controller = PageController();
  int _index = 0;
  Timer? _timer;

  Map<String, dynamic>? _tipData;

  @override
  void initState() {
    super.initState();
    _loadTips();
  }

  Future<void> _loadTips() async {
    try {
      final weekKey = _getWeekKey();
      final doc = await FirebaseFirestore.instance
          .collection('seasonal_tips')
          .doc(weekKey)
          .get();
      if (!mounted) return;
      if (doc.exists && mounted) {
        setState(() => _tipData = doc.data());
      }
    } catch (_) {}
  }

  String _getWeekKey() {
    final now = DateTime.now();
    final d = DateTime.utc(now.year, now.month, now.day);
    final adjusted = d.add(
      Duration(days: 4 - (d.weekday == 7 ? 7 : d.weekday)),
    );
    final yearStart = DateTime.utc(adjusted.year, 1, 1);
    final week = ((adjusted.difference(yearStart).inDays + 1) / 7).ceil();
    return '${now.year}-W${week.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic>? _todayTip() {
    if (_tipData == null) return null;
    final tips = (_tipData!['tips'] as List<dynamic>?) ?? [];
    if (tips.isEmpty) return null;
    final dayOfWeek = DateTime.now().weekday - 1;
    final start = dayOfWeek * 3;
    if (start >= tips.length) return null;
    return tips[start] as Map<String, dynamic>;
  }

  List<_BannerData> _buildBanners(AppLocalizations l10n, String locale) {
    final banners = <_BannerData>[];
    final now = DateTime.now();

    // Watering banners — one plant per carousel cycle, round-robin
    final thirsty = widget.plants
        .where((p) => p.nextWatering.isBefore(now))
        .toList();
    if (thirsty.isNotEmpty) {
      final pick = thirsty[_index % thirsty.length];
      banners.add(
        _BannerData(
          gradient: const [Color(0xFF5A4A1A), Color(0xFF896C14)],
          icon: '💧',
          title: l10n.bannerWaterTitle(pick.name),
          subtitle: l10n.bannerWaterSubtitle,
          action: _BannerAction.water,
          plant: pick,
        ),
      );
    }

    // Seasonal tip banner
    final tip = _todayTip();
    if (tip != null) {
      final text = (tip[locale] ?? tip['en'] ?? '') as String;
      banners.add(
        _BannerData(
          gradient: const [BotanlyColors.moss, Color(0xFF3A5436)],
          icon: '🌿',
          title: l10n.bannerTipTitle,
          subtitle: text,
          action: _BannerAction.tips,
        ),
      );
    }

    return banners;
  }

  void _startTimer(int count) {
    _timer?.cancel();
    if (count <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      final next = (_index + 1) % count;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onBannerTap(_BannerData banner) {
    if (banner.action == _BannerAction.water && banner.plant != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlantDetailsScreen(plant: banner.plant!),
        ),
      );
    } else if (banner.action == _BannerAction.tips) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TipsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    if (!widget.plantsLoaded) return const SizedBox.shrink();

    final banners = _buildBanners(l10n, locale);

    if (banners.isEmpty) return const SizedBox.shrink();

    _startTimer(banners.length);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 78,
              child: PageView.builder(
                controller: _controller,
                itemCount: banners.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => _onBannerTap(banners[i]),
                  child: _BannerCard(banner: banners[i]),
                ),
              ),
            ),
          ),
        ),
        if (banners.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < banners.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: i == _index ? 14 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? BotanlyColors.sage
                          : BotanlyColors.sand,
                      borderRadius: BorderRadius.circular(
                        i == _index ? 3 : 999,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

enum _BannerAction { water, tips }

class _BannerData {
  final List<Color> gradient;
  final String icon;
  final String title;
  final String subtitle;
  final _BannerAction action;
  final Plant? plant;
  const _BannerData({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    this.plant,
  });
}

class _BannerCard extends StatelessWidget {
  final _BannerData banner;
  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: banner.gradient,
        ),
      ),
      child: Row(
        children: [
          Text(banner.icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  banner.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.fraunces(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  banner.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '›',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Add Plant pill ───────────────────────

class _AddPlantPillButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  const _AddPlantPillButton({this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: BotanlyColors.sage,
          borderRadius: BorderRadius.circular(20),
          boxShadow: BotanlyShadows.primaryGlow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── Empty + Loading states ───────────────────────

class _EmptyPlantsState extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback? onAddPlant;
  const _EmptyPlantsState({required this.l10n, this.onAddPlant});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: BotanlyColors.sage.withOpacity(0.10),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Illustration container
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: BotanlyColors.sageSoft,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('🌱', style: const TextStyle(fontSize: 44)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noPlantsYet,
              style: GoogleFonts.fraunces(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: BotanlyColors.moss,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addFirstPlantToGetStarted,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: BotanlyColors.inkMute,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onAddPlant,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  l10n.addYourFirstPlant,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BotanlyColors.sage,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlantsListSkeleton extends StatelessWidget {
  const _PlantsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: BotanlyShimmer(
        child: Column(
          children: List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: const ShimmerPlantTile(),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      children: const [_PlantsListSkeleton()],
    );
  }
}
