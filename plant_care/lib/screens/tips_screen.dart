import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plant_care/theme/botanly_theme.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/widgets/botanly_shimmer.dart';

class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  String _weekKey() {
    final now = DateTime.now();
    final d = DateTime.utc(now.year, now.month, now.day);
    final adjusted =
        d.add(Duration(days: 4 - (d.weekday == 7 ? 7 : d.weekday)));
    final yearStart = DateTime.utc(adjusted.year, 1, 1);
    final week =
        ((adjusted.difference(yearStart).inDays + 1) / 7).ceil();
    return '${now.year}-W${week.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> _todayTips(Map<String, dynamic> data) {
    final tips = (data['tips'] as List<dynamic>?) ?? [];
    if (tips.isEmpty) return [];
    final dayOfWeek = DateTime.now().weekday - 1; // 0=Mon..6=Sun
    final start = dayOfWeek * 3;
    if (start >= tips.length) return [];
    final end = (start + 3).clamp(0, tips.length);
    return tips.sublist(start, end).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final weekKey = _weekKey();

    return Scaffold(
      backgroundColor: BotanlyColors.cabinetBg,
      body: SafeArea(
        child: Column(
          children: [
            _TipsAppBar(l10n: l10n),
            Expanded(
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('seasonal_tips')
                    .doc(weekKey)
                    .get(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return BotanlyShimmer(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        itemCount: 3,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, __) => const ShimmerTipCard(),
                      ),
                    );
                  }
                  if (!snap.hasData || !snap.data!.exists) {
                    return _EmptyTips(l10n: l10n);
                  }
                  final data = snap.data!.data() as Map<String, dynamic>;
                  final today = _todayTips(data);
                  if (today.isEmpty) return _EmptyTips(l10n: l10n);
                  final season = data['season'] as String? ?? 'spring';

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      for (int i = 0; i < today.length; i++) ...[
                        StaggeredFadeUp(
                          index: i,
                          show: true,
                          child: _TipCard(
                            tip: today[i],
                            locale: locale,
                            index: i,
                            season: season,
                            l10n: l10n,
                          ),
                        ),
                        if (i < today.length - 1) const SizedBox(height: 14),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipsAppBar extends StatelessWidget {
  final AppLocalizations l10n;
  const _TipsAppBar({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: BotanlyColors.moss,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tipsOfTheDay,
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.3,
                    color: BotanlyColors.moss,
                  ),
                ),
                Text(
                  l10n.tipsOfTheDaySub,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: BotanlyColors.inkMute,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final Map<String, dynamic> tip;
  final String locale;
  final int index;
  final String season;
  final AppLocalizations l10n;

  const _TipCard({
    required this.tip,
    required this.locale,
    required this.index,
    required this.season,
    required this.l10n,
  });

  static const _categoryIcons = <String, IconData>{
    'watering': Icons.water_drop_outlined,
    'light': Icons.wb_sunny_outlined,
    'pests': Icons.bug_report_outlined,
    'fertilizing': Icons.eco_outlined,
    'seasonal': Icons.calendar_month_outlined,
    'general': Icons.tips_and_updates_outlined,
  };

  static const _categoryColors = <String, Color>{
    'watering': BotanlyColors.blue,
    'light': BotanlyColors.amber,
    'pests': BotanlyColors.red,
    'fertilizing': BotanlyColors.sage,
    'seasonal': Color(0xFF8B6DAF),
    'general': BotanlyColors.inkSoft,
  };

  static const _categoryBg = <String, Color>{
    'watering': BotanlyColors.bluePale,
    'light': BotanlyColors.amberPale,
    'pests': BotanlyColors.redPale,
    'fertilizing': BotanlyColors.sagePale,
    'seasonal': Color(0xFFF0E8F8),
    'general': BotanlyColors.sageSoft,
  };

  static const _seasonEmoji = <String, String>{
    'spring': '🌱',
    'summer': '☀️',
    'autumn': '🍂',
    'winter': '❄️',
  };

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'watering':
        return l10n.tipCategoryWatering;
      case 'light':
        return l10n.tipCategoryLight;
      case 'pests':
        return l10n.tipCategoryPests;
      case 'fertilizing':
        return l10n.tipCategoryFertilizing;
      case 'seasonal':
        return l10n.tipCategorySeasonal;
      default:
        return l10n.tipCategoryGeneral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = (tip[locale] ?? tip['en'] ?? '') as String;
    final category = (tip['category'] ?? 'general') as String;
    final icon = _categoryIcons[category] ?? Icons.tips_and_updates_outlined;
    final color = _categoryColors[category] ?? BotanlyColors.inkSoft;
    final bg = _categoryBg[category] ?? BotanlyColors.sageSoft;
    final emoji = _seasonEmoji[season] ?? '🌱';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BotanlyColors.line, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: bg.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _categoryLabel(category),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(emoji, style: const TextStyle(fontSize: 22)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: BotanlyColors.moss,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTips extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyTips({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌿', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              l10n.noTipsYet,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: BotanlyColors.inkMute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
