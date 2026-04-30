import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/botanly_theme.dart';
import '../models/plant.dart';
import '../services/plant_service.dart';
import 'plant_details_screen.dart';
import 'add_plant_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  const DashboardScreen({super.key, this.onTabChange});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: BotanlyColors.cabinetBg,
      child: StreamBuilder<List<Plant>>(
        stream: PlantService().getPlants(),
        builder: (context, snapshot) {
          final plants = snapshot.data ?? [];
          final needWater = plants
              .where((p) =>
                  p.shouldWaterNow ||
                  p.nextWatering.isBefore(DateTime.now()))
              .length;
          final healthy = plants
              .where((p) =>
                  !p.shouldWaterNow &&
                  p.nextWatering
                      .isAfter(DateTime.now().add(const Duration(days: 1))))
              .length;

          return ListView(
            padding: const EdgeInsets.only(bottom: 90),
            children: [
              const _GardenHeader(),
              _StatsRow(
                  total: plants.length,
                  healthy: healthy,
                  needWater: needWater),
              const SizedBox(height: 6),
              const _DashboardBannerCarousel(),
              _SectionTitle(
                title: Text(
                  'My Plants',
                  style: GoogleFonts.fraunces(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: BotanlyColors.moss,
                    letterSpacing: -0.2,
                  ),
                ),
                trailing: _AddPlantPill(
                    onTap: () {
                      if (widget.onTabChange != null) {
                        widget.onTabChange!(2);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddPlantScreen()),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),
                if (snapshot.connectionState == ConnectionState.waiting &&
                    plants.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (plants.isEmpty)
                  _EmptyState(
                    onAddPlant: () {
                      if (widget.onTabChange != null) {
                        widget.onTabChange!(2);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddPlantScreen()),
                        );
                      }
                    },
                  )
                else
                  ...plants.map((p) => Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: _PlantCard(
                          plant: p,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlantDetailsScreen(plant: p),
                            ),
                          ),
                          onWater: () =>
                              PlantService().waterPlant(p.id),
                        ),
                      )),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}

// ───────────────────── header (`dashboard_screen.html` .header .title) ─────────────────────

class _GardenHeader extends StatelessWidget {
  const _GardenHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 0),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.fraunces(
            fontSize: 28,
            fontWeight: FontWeight.w400,
            color: BotanlyColors.moss,
            letterSpacing: -0.5,
            height: 1.1,
          ),
          children: [
            const TextSpan(text: 'My '),
            TextSpan(
              text: 'Garden',
              style: GoogleFonts.fraunces(
                fontSize: 28,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: BotanlyColors.sage,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────── stats row ─────────────────────

class _StatsRow extends StatelessWidget {
  final int total;
  final int healthy;
  final int needWater;
  const _StatsRow(
      {required this.total,
      required this.healthy,
      required this.needWater});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: _DashboardStatCard(
              emoji: '🌱',
              emojiBg: BotanlyColors.sagePale,
              value: total.toString(),
              valueColor: BotanlyColors.sage,
              label: 'Total Plants',
              highlight: false,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DashboardStatCard(
              emoji: '💧',
              emojiBg: BotanlyColors.amberPale,
              value: needWater.toString(),
              valueColor: BotanlyColors.amber,
              label: 'Need Water',
              highlight: false,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DashboardStatCard(
              emoji: '✓',
              emojiBg: BotanlyColors.sagePale,
              value: healthy.toString(),
              valueColor: BotanlyColors.sageLight,
              label: 'Healthy',
              highlight: true,
              emojiIsGlyph: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  final String emoji;
  final Color emojiBg;
  final String value;
  final Color valueColor;
  final String label;
  final bool highlight;
  final bool emojiIsGlyph;

  const _DashboardStatCard({
    required this.emoji,
    required this.emojiBg,
    required this.value,
    required this.valueColor,
    required this.label,
    required this.highlight,
    this.emojiIsGlyph = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: highlight
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEAF4E6), Color(0xFFD8EDCF)],
              )
            : null,
        color: highlight ? null : BotanlyColors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight ? BotanlyColors.sagePale : BotanlyColors.sand,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: emojiBg,
              shape: BoxShape.circle,
            ),
            child: emojiIsGlyph
                ? Text(
                    emoji,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: BotanlyColors.sage,
                      height: 1,
                    ),
                  )
                : Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: valueColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
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

/// Banner strip from `dashboard_screen.html` (carousel + dots).
class _DashboardBannerCarousel extends StatefulWidget {
  const _DashboardBannerCarousel();

  @override
  State<_DashboardBannerCarousel> createState() =>
      _DashboardBannerCarouselState();
}

class _DashboardBannerCarouselState extends State<_DashboardBannerCarousel> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 86,
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _index = i),
                  children: const [
                    _BannerSlide(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A3A5A), Color(0xFF2A5A8A)],
                      ),
                      icon: '🌸',
                      title: 'Plant of 2026 — Delphinium',
                      subtitle:
                          '1-800-Flowers names it Flower of the Year · symbol of ambition',
                    ),
                    _BannerSlide(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF5A4A1A), Color(0xFF896C14)],
                      ),
                      icon: '🌿',
                      title: 'Iris needs water tomorrow',
                      subtitle: 'Schedule a reminder or water now',
                    ),
                    _BannerSlide(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2D3D2A), Color(0xFF3A5436)],
                      ),
                      icon: '☀️',
                      title: 'Tip: Rotate your plants',
                      subtitle: 'Turn pots every few days for even growth',
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final active = i == _index;
              return GestureDetector(
                onTap: () {
                  _controller.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: active ? 14 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: active ? BotanlyColors.sage : BotanlyColors.sand,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _BannerSlide extends StatelessWidget {
  final Gradient gradient;
  final String icon;
  final String title;
  final String subtitle;

  const _BannerSlide({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fraunces(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.35,
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
      ),
    );
  }
}

// ───────────────────── section header ─────────────────────

class _SectionTitle extends StatelessWidget {
  final Widget title;
  final Widget? trailing;
  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
      child: Row(
        children: [
          Expanded(child: title),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ───────────────────── add plant pill ─────────────────────

class _AddPlantPill extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPlantPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: BotanlyColors.sage,
          borderRadius: BorderRadius.circular(20),
          boxShadow: BotanlyShadows.primaryGlow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text('Add Plant',
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                )),
          ],
        ),
      ),
    );
  }
}

// ───────────────────── empty state ─────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddPlant;
  const _EmptyState({required this.onAddPlant});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.eco_outlined,
            size: 64,
            color: BotanlyColors.sage.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No plants yet',
            style: GoogleFonts.fraunces(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: BotanlyColors.moss,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first plant to get started',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: BotanlyColors.inkMute,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddPlant,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add plant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: BotanlyColors.sage,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────── plant card ─────────────────────

class _PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;
  final VoidCallback onWater;
  const _PlantCard(
      {required this.plant,
      required this.onTap,
      required this.onWater});

  static const _thumb = 62.0;

  Color get _stripe {
    final state = plant.notificationState;
    if (state == 'overdue') return BotanlyColors.red;
    if (state == 'due' || plant.shouldWaterNow) return BotanlyColors.amber;
    return BotanlyColors.sageLight;
  }

  Color get _pillBg {
    final state = plant.notificationState;
    if (state == 'overdue') return const Color(0xFFFCE8E8);
    if (state == 'due' || plant.shouldWaterNow) return BotanlyColors.amberPale;
    return BotanlyColors.sagePale;
  }

  Color get _pillText {
    final state = plant.notificationState;
    if (state == 'overdue') return BotanlyColors.red;
    if (state == 'due' || plant.shouldWaterNow) return BotanlyColors.amber;
    return BotanlyColors.sage;
  }

  String _careLine() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final nw = DateTime(
      plant.nextWatering.year,
      plant.nextWatering.month,
      plant.nextWatering.day,
    );
    final d = nw.difference(start).inDays;
    if (plant.notificationState == 'overdue' || d < 0) {
      final o = d < 0 ? -d : 1;
      return 'Overdue ${o}d';
    }
    if (d == 0) return 'Watering today';
    if (d == 1) return 'Watering tomorrow';
    return 'Watering in ${d}d';
  }

  bool get _waterBtnActive =>
      plant.notificationState == 'overdue' || plant.shouldWaterNow;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: BotanlyColors.paper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BotanlyColors.sand),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 14,
              bottom: 14,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: _stripe,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(3),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 11),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: plant.imageUrl != null
                        ? Image.network(
                            plant.imageUrl!,
                            width: _thumb,
                            height: _thumb,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _PlantPlaceholder(),
                          )
                        : const _PlantPlaceholder(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.fraunces(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: BotanlyColors.moss,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.fromLTRB(6, 3, 9, 3),
                          decoration: BoxDecoration(
                            color: _pillBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _stripe,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _careLine(),
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: _pillText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onWater,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _waterBtnActive
                              ? BotanlyColors.sage
                              : Colors.transparent,
                          border: Border.all(
                            color: _waterBtnActive
                                ? BotanlyColors.sage
                                : BotanlyColors.sand,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '💧',
                          style: TextStyle(
                            fontSize: 17,
                            height: 1,
                            color: _waterBtnActive
                                ? Colors.white
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlantPlaceholder extends StatelessWidget {
  const _PlantPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _PlantCard._thumb,
      height: _PlantCard._thumb,
      color: BotanlyColors.sand,
    );
  }
}
