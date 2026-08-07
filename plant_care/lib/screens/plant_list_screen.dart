import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/services/plant_service.dart';
import 'package:plant_care/services/subscription_service.dart';
import 'package:plant_care/screens/add_plant_screen.dart';
import 'package:plant_care/screens/plant_details_screen.dart';
import 'package:plant_care/theme/botanly_theme.dart';
import 'package:plant_care/widgets/botanly_plant_tile.dart';
import 'package:plant_care/widgets/botanly_shimmer.dart';
import 'package:plant_care/widgets/subscription_banner.dart';

/// My Plants — UI from `Botanly /screens/plant_list_screen.html`.
///
/// Logic preserved: streams plants from [PlantService], waters via
/// `waterPlant`, opens [PlantDetailsScreen] on tap. Adds purely client-side
/// search + filter chips on top of the existing data — does not change the
/// underlying data model.
class PlantListScreen extends StatefulWidget {
  final VoidCallback? onAddPlant;
  const PlantListScreen({super.key, this.onAddPlant});

  @override
  State<PlantListScreen> createState() => _PlantListScreenState();
}

enum _PlantFilter { all, ok, warn, overdue }

class _PlantListScreenState extends State<PlantListScreen> {
  bool _searchOpen = false;
  String _query = '';
  _PlantFilter _filter = _PlantFilter.all;
  late final TextEditingController _searchCtrl;
  late final FocusNode _searchFocus;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _searchFocus = FocusNode();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  _PlantFilter _statusOf(Plant p) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(p.nextWatering.year, p.nextWatering.month,
        p.nextWatering.day);
    final days = due.difference(today).inDays;
    if (days < 0) return _PlantFilter.overdue;
    if (days <= 1) return _PlantFilter.warn;
    return _PlantFilter.ok;
  }

  List<Plant> _applyFilters(List<Plant> plants) {
    final q = _query.toLowerCase().trim();
    return plants.where((p) {
      final matchText = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.species.toLowerCase().contains(q);
      final matchFilter =
          _filter == _PlantFilter.all || _statusOf(p) == _filter;
      return matchText && matchFilter;
    }).toList();
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

            return StreamBuilder<List<Plant>>(
              stream: PlantService().getPlants(),
              builder: (context, snapshot) {
                final plants = snapshot.data ?? const <Plant>[];
                final filtered = _applyFilters(plants);

                final limitReached = subInfo != null &&
                    plants.length >= subInfo.plantLimit &&
                    !subInfo.isActive;

                return Stack(
                  children: [
                    Column(
                      children: [
                        _Header(
                          searchOpen: _searchOpen,
                          onToggleSearch: () {
                            setState(() {
                              _searchOpen = !_searchOpen;
                              if (!_searchOpen) {
                                _query = '';
                                _searchCtrl.clear();
                              }
                            });
                            if (_searchOpen) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _searchFocus.requestFocus();
                              });
                            }
                          },
                        ),
                        if (_searchOpen)
                          _SearchBar(
                            controller: _searchCtrl,
                            focusNode: _searchFocus,
                            onChanged: (v) => setState(() => _query = v),
                          ),
                        _FilterChips(
                          active: _filter,
                          onSelect: (f) => setState(() => _filter = f),
                        ),
                        Expanded(
                          child: _buildBody(
                              snapshot, filtered, plants.length, l10n,
                              bottomPadding: limitReached ? 100.0 : 0.0,
                              onAddPlant: widget.onAddPlant),
                        ),
                      ],
                    ),
                    // Limit banner floats at the bottom
                    if (limitReached && subInfo != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: PlantLimitBanner(info: subInfo),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(AsyncSnapshot<List<Plant>> snapshot,
      List<Plant> filtered, int totalCount, AppLocalizations l10n,
      {double bottomPadding = 0.0, VoidCallback? onAddPlant}) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return BotanlyShimmer(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, __) => const ShimmerPlantTile(),
        ),
      );
    }
    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('${l10n.errorLabel}: ${snapshot.error}'),
        ),
      );
    }
    if (filtered.isEmpty) {
      return _EmptyState(
        l10n: l10n,
        forSearch: totalCount > 0,
        onAddPlant: onAddPlant,
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 32 + bottomPadding),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final plant = filtered[i];
        return StaggeredFadeUp(
          index: i,
          show: true,
          child: BotanlyPlantTile(
            plant: plant,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlantDetailsScreen(plant: plant),
              ),
            ),
            onWater: () => PlantService().waterPlant(plant.id),
          ),
        );
      },
    );
  }
}

// ─────────────────────── Header ───────────────────────

class _Header extends StatelessWidget {
  final bool searchOpen;
  final VoidCallback onToggleSearch;
  const _Header({required this.searchOpen, required this.onToggleSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 14),
      child: Row(
        children: [
          // Title "My Plants" with italic accent.
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'My ',
                    style: GoogleFonts.fraunces(
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.64,
                      height: 1,
                      color: BotanlyColors.moss,
                    ),
                  ),
                  TextSpan(
                    text: 'Plants',
                    style: GoogleFonts.fraunces(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.64,
                      height: 1,
                      color: BotanlyColors.sage,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _SearchButton(
            active: searchOpen,
            onPressed: onToggleSearch,
          ),
        ],
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  final bool active;
  final VoidCallback onPressed;
  const _SearchButton({required this.active, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? BotanlyColors.sagePale
                : Colors.white.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(
                color: BotanlyColors.moss.withValues(alpha: 0.1)),
          ),
          child: Icon(
            active ? Icons.close : Icons.search,
            size: 18,
            color: BotanlyColors.moss,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── Search bar ───────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          border: Border.all(
              color: BotanlyColors.moss.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.search,
                size: 16, color: BotanlyColors.moss.withValues(alpha: 0.5)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: BotanlyColors.moss,
                ),
                cursorColor: BotanlyColors.sage,
                decoration: InputDecoration(
                  isCollapsed: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  hintText: l10n.searchPlantsHint,
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: BotanlyColors.moss.withValues(alpha: 0.45),
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

// ─────────────────────── Filter chips ───────────────────────

class _FilterChips extends StatelessWidget {
  final _PlantFilter active;
  final ValueChanged<_PlantFilter> onSelect;
  const _FilterChips({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = <(_PlantFilter, String)>[
      (_PlantFilter.all, l10n.filterAll),
      (_PlantFilter.ok, l10n.healthy),
      (_PlantFilter.warn, l10n.needWater),
      (_PlantFilter.overdue, l10n.filterOverdue),
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (value, label) = entries[i];
          final isActive = value == active;
          return _FilterChip(
            label: label,
            active: isActive,
            onTap: () => onSelect(value),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? BotanlyColors.moss
                : Colors.white.withValues(alpha: 0.55),
            border: Border.all(
              color: active
                  ? BotanlyColors.moss
                  : BotanlyColors.moss.withValues(alpha: 0.12),
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: active ? Colors.white : BotanlyColors.moss,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── Empty state ───────────────────────

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  final bool forSearch;
  final VoidCallback? onAddPlant;
  const _EmptyState({
    required this.l10n,
    required this.forSearch,
    this.onAddPlant,
  });

  void _handleAddPlant(BuildContext context) {
    if (onAddPlant != null) {
      onAddPlant!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddPlantScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Search empty state — minimal, no card/button
    if (forSearch) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 48, color: BotanlyColors.inkMute),
              const SizedBox(height: 12),
              Text(
                l10n.noResultsTitle,
                style: GoogleFonts.fraunces(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: BotanlyColors.moss,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.noResultsSub,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  height: 1.55,
                  color: BotanlyColors.inkMute,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // No plants at all — card with shadow + button
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
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
            // Illustration — leaf grid pattern to differ from dashboard
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    BotanlyColors.sagePale,
                    BotanlyColors.sageSoft,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🪴', style: TextStyle(fontSize: 44)),
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
                onPressed: () => _handleAddPlant(context),
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
