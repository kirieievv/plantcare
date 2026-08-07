/// My plants — the whole garden as a list (handoff v4, ORDER stage 4).
///
/// Navigation only: the watering button that used to live on each row is gone,
/// because watering belongs to the plant's own screen and a one-tap action in a
/// list is too easy to hit by accident (CHANGELOG v4).
library;

import 'package:flutter/material.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/models/plant_health.dart';
import 'package:plant_care/models/task.dart';
import 'package:plant_care/screens/plant_details_screen.dart';
import 'package:plant_care/services/plant_service.dart';
import 'package:plant_care/services/task_service.dart';
import 'package:plant_care/theme/botanly_glass.dart';
import 'package:plant_care/widgets/botanly_kit.dart';

/// The five buckets, rebuilt around meaning (CHANGELOG v4):
/// production's "Healthy" counted watering dates, which said nothing about
/// health once the score model arrived.
enum PlantFilter { all, overdue, today, tomorrow, needsCare }

class MyPlantsScreen extends StatefulWidget {
  final VoidCallback? onAddPlant;

  const MyPlantsScreen({super.key, this.onAddPlant});

  @override
  State<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends State<MyPlantsScreen> {
  final _search = TextEditingController();
  final _chipsScroll = ScrollController();

  PlantFilter _filter = PlantFilter.all;
  bool _searchOpen = false;
  String _query = '';

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void dispose() {
    _search.dispose();
    _chipsScroll.dispose();
    super.dispose();
  }

  /// Whole days until watering: negative is overdue, 0 is today.
  static int _daysUntilWatering(Plant plant, DateTime now) {
    final due = plant.nextDueAt ?? plant.nextWatering;
    return DateTime(
      due.year,
      due.month,
      due.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  bool _matches(Plant plant, int score, PlantFilter filter, DateTime now) {
    if (filter == PlantFilter.all) return true;
    // "Needs care" is about the score, and it is the only filter that is —
    // which is exactly why it is not called "healthy" any more.
    if (filter == PlantFilter.needsCare) return plantNeedsAttention(score);

    final days = _daysUntilWatering(plant, now);
    return switch (filter) {
      PlantFilter.overdue => days < 0,
      // Strictly today: the old filter also swept up tomorrow, which then
      // contradicted the "watering tomorrow" line on the card itself.
      PlantFilter.today => days == 0,
      PlantFilter.tomorrow => days == 1,
      _ => true,
    };
  }

  String _filterLabel(PlantFilter filter) => switch (filter) {
    PlantFilter.all => l10n.filterAll,
    PlantFilter.overdue => l10n.filterOverdue,
    PlantFilter.today => l10n.needWater,
    PlantFilter.tomorrow => l10n.filterTomorrow,
    PlantFilter.needsCare => l10n.filterNeedsCare,
  };

  void _open(Plant plant) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PlantDetailsScreen(plant: plant)));
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
              child: StreamBuilder<List<Plant>>(
                stream: PlantService().getPlants(),
                builder: (context, plantSnap) {
                  final plants = plantSnap.data ?? const <Plant>[];
                  final loading =
                      plantSnap.connectionState == ConnectionState.waiting &&
                      !plantSnap.hasData;

                  return StreamBuilder<List<CareTask>>(
                    stream: TaskService().watchOpenTasks(),
                    builder: (context, taskSnap) {
                      final tasks = taskSnap.data ?? const <CareTask>[];
                      final now = DateTime.now();

                      // One score per plant, computed once and shared by the
                      // filter counts and the rows, so a plant can never be
                      // counted in "needs care" and shown as green.
                      final scores = {
                        for (final p in plants)
                          p.id: livePlantScore(
                            p,
                            tasks.where((t) => t.plantId == p.id),
                            now: now,
                          ),
                      };

                      final query = _query.trim().toLowerCase();
                      final visible = plants.where((p) {
                        if (!_matches(p, scores[p.id]!, _filter, now)) {
                          return false;
                        }
                        if (query.isEmpty) return true;
                        return p.name.toLowerCase().contains(query) ||
                            p.species.toLowerCase().contains(query) ||
                            (p.aiName ?? '').toLowerCase().contains(query);
                      }).toList();

                      return ListView(
                        // Room for the floating tab bar, measured rather than guessed:
                        // the hand-counted 120 fell short of the 125 the bar occupies on a
                        // phone with a home indicator, clipping the last row.
                        padding: EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          16 + MediaQuery.of(context).padding.bottom,
                        ),
                        children: [
                          _header(plants.length),
                          if (_searchOpen) ...[
                            const SizedBox(height: 12),
                            BotanlyField(
                              controller: _search,
                              hint: l10n.searchPlantsHint,
                              glyph: BotanlySvg.scan,
                              autofocus: true,
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          ],
                          const SizedBox(height: 14),
                          _chips(plants, scores, now),
                          const SizedBox(height: 4),
                          if (loading)
                            const _LoadingRows()
                          else if (plants.isEmpty)
                            _EmptyGarden(onAdd: widget.onAddPlant)
                          else if (visible.isEmpty)
                            _EmptyResult(
                              searching: query.isNotEmpty,
                              title: query.isNotEmpty
                                  ? l10n.myPlantsNothingFound
                                  : l10n.myPlantsAllClearTitle,
                              subtitle: query.isNotEmpty
                                  ? l10n.myPlantsNothingFoundHint
                                  : l10n.myPlantsAllClearHint,
                            )
                          else
                            for (final plant in visible) ...[
                              _PlantCard(
                                plant: plant,
                                score: scores[plant.id]!,
                                days: _daysUntilWatering(plant, now),
                                onTap: () => _open(plant),
                              ),
                              const SizedBox(height: 9),
                            ],
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 0
                      ? l10n.myPlantsEmptyLabel.toUpperCase()
                      : l10n.myPlantsCount(count).toUpperCase(),
                  style: glassFont(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 11.5 * 0.09,
                    color: kGlassMut,
                  ),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    style: glassFont(
                      fontSize: 27,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 27 * -0.035,
                      color: kGlassInk,
                    ),
                    children: [
                      TextSpan(text: '${l10n.myPlantsTitleLead} '),
                      TextSpan(
                        text: l10n.myPlantsTitleAccent,
                        style: const TextStyle(color: kGlassAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          BotanlyPress(
            onTap: () {
              setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) {
                  _search.clear();
                  _query = '';
                }
              });
            },
            child: GlassSurface(
              blur: 18,
              shape: BoxShape.circle,
              child: SizedBox(
                width: 42,
                height: 42,
                child: Center(
                  child: BotanlyGlyph(
                    _searchOpen ? BotanlySvg.close : BotanlySvg.scan,
                    size: 18,
                    color: kGlassInk2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chips(List<Plant> plants, Map<String, int> scores, DateTime now) {
    return SizedBox(
      height: 44,
      child: ListView(
        controller: _chipsScroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        children: [
          for (final filter in PlantFilter.values) ...[
            if (filter != PlantFilter.values.first) const SizedBox(width: 7),
            BotanlyChip(
              label: _filterLabel(filter),
              // "All" carries no counter — it is the list length, which is
              // already in the header.
              count: filter == PlantFilter.all
                  ? null
                  : plants
                        .where((p) => _matches(p, scores[p.id]!, filter, now))
                        .length,
              selected: _filter == filter,
              onTap: () => setState(() => _filter = filter),
            ),
          ],
        ],
      ),
    );
  }
}

/// Row: photo, name, latin name, watering line, score, chevron.
class _PlantCard extends StatelessWidget {
  final Plant plant;
  final int score;
  final int days;
  final VoidCallback onTap;

  const _PlantCard({
    required this.plant,
    required this.score,
    required this.days,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final warn = plantNeedsAttention(score);

    // Wording comes from the production keys, so the card cannot contradict the
    // filter chip above it.
    final (String water, Color tone) = days < 0
        ? (l10n.wateringOverdueNDays(days.abs()), kGlassAlert)
        : days == 0
        ? (l10n.wateringToday, kGlassAttnText)
        : days == 1
        ? (l10n.wateringTomorrow, kGlassAttnText)
        : (l10n.wateringInNDays(days), kGlassGreenText);

    final latin = (plant.aiName ?? plant.species).trim();

    return BotanlyPress(
      scale: 0.985,
      onTap: onTap,
      child: GlassSurface(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _Thumb(url: plant.imageUrl),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: glassFont(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 15.5 * -0.015,
                      color: kGlassInk,
                    ),
                  ),
                  if (latin.isNotEmpty && latin != plant.name) ...[
                    const SizedBox(height: 2),
                    Text(
                      latin,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: glassFont(
                        fontSize: 12.5,
                        letterSpacing: 0,
                        color: kGlassMut,
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: tone.withAlpha(33),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: BotanlyGlyph(
                          BotanlySvg.drop,
                          size: 12,
                          color: tone,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          water,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: glassFont(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: tone,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: warn ? kGlassAttnBg : kGlassLeafBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$score',
                style: glassFont(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: warn ? kGlassAttnText : kGlassGreenText,
                ),
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
  }
}

class _Thumb extends StatelessWidget {
  final String? url;

  const _Thumb({this.url});

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: kGlassLeafBg,
      child: Center(
        child: BotanlyGlyph(BotanlySvg.leaf, size: 23, color: kGlassAccent),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 48,
        height: 48,
        child: url == null || url!.isEmpty
            ? placeholder
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => placeholder,
              ),
      ),
    );
  }
}

/// Nothing in the garden at all — the one empty state with a call to action.
class _EmptyGarden extends StatelessWidget {
  final VoidCallback? onAdd;

  const _EmptyGarden({this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GlassSurface(
      padding: const EdgeInsets.fromLTRB(26, 30, 26, 26),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: kGlassLeafBg,
              shape: BoxShape.circle,
            ),
            child: const BotanlyGlyph(
              BotanlySvg.leaf,
              size: 30,
              color: kGlassAccent,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.noPlantsYet,
            textAlign: TextAlign.center,
            style: glassFont(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: kGlassInk,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.addFirstPlantHint,
            textAlign: TextAlign.center,
            style: glassFont(fontSize: 13, height: 1.45, color: kGlassMut),
          ),
          if (onAdd != null) ...[
            const SizedBox(height: 16),
            BotanlyButton(
              label: l10n.addPlant,
              glyph: BotanlySvg.plus,
              onTap: onAdd,
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty because of a search or a filter — no call to action, because there is
/// nothing wrong: the garden is simply elsewhere.
class _EmptyResult extends StatelessWidget {
  final bool searching;
  final String title;
  final String subtitle;

  const _EmptyResult({
    required this.searching,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 26),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: searching ? const Color(0x12141E0F) : kGlassLeafBg,
              shape: BoxShape.circle,
            ),
            child: BotanlyGlyph(
              searching ? BotanlySvg.scan : BotanlySvg.check,
              size: 24,
              color: searching ? kGlassMut : kGlassAccent,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: glassFont(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: searching ? kGlassInk : kGlassGreenText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: glassFont(fontSize: 13, height: 1.45, color: kGlassMut),
          ),
        ],
      ),
    );
  }
}

/// Placeholder rows while the garden loads.
///
/// Not the empty state: "no plants yet" next to a garden that is simply still
/// arriving is a lie, and it comes with a call to action the user does not need.
class _LoadingRows extends StatelessWidget {
  const _LoadingRows();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: 9),
          Opacity(
            opacity: 0.55 - i * 0.15,
            child: GlassSurface(
              radius: 22,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: kGlassLeafBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 13,
                          width: 120,
                          decoration: BoxDecoration(
                            color: const Color(0x14141E0F),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 11,
                          width: 80,
                          decoration: BoxDecoration(
                            color: const Color(0x0F141E0F),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
