import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/botanly_theme.dart';
import '../models/plant.dart';
import '../services/plant_service.dart';
import 'plant_details_screen.dart';

class PlantListScreen extends StatefulWidget {
  const PlantListScreen({super.key});

  @override
  State<PlantListScreen> createState() => _PlantListScreenState();
}

class _PlantListScreenState extends State<PlantListScreen> {
  bool _searchOpen = false;
  String _query = '';
  String _filter = 'All';

  static const _filters = ['All', 'Healthy', 'Needs water', 'Overdue'];

  Iterable<Plant> _filtered(List<Plant> plants) => plants.where((p) {
        final matchesSearch = _query.isEmpty ||
            p.name.toLowerCase().contains(_query.toLowerCase()) ||
            p.species.toLowerCase().contains(_query.toLowerCase());
        if (!matchesSearch) return false;
        switch (_filter) {
          case 'Healthy':
            return !p.shouldWaterNow &&
                p.nextWatering
                    .isAfter(DateTime.now().add(const Duration(days: 1)));
          case 'Needs water':
            return p.notificationState == 'due' || p.shouldWaterNow;
          case 'Overdue':
            return p.notificationState == 'overdue';
          default:
            return true;
        }
      });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Plant>>(
          stream: PlantService().getPlants(),
          builder: (context, snapshot) {
            final plants = snapshot.data ?? [];
            final filtered = _filtered(plants).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _topBar(),
                if (_searchOpen) _searchField(),
                _filterChips(),
                const SizedBox(height: 8),
                Expanded(
                  child: snapshot.connectionState ==
                              ConnectionState.waiting &&
                          plants.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                          ? _emptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 0, 16, 32),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final p = filtered[i];
                                return _PlantTile(
                                  plant: p,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PlantDetailsScreen(plant: p),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.fraunces(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: BotanlyColors.moss,
                  letterSpacing: -.4,
                ),
                children: const [
                  TextSpan(text: 'My '),
                  TextSpan(
                    text: 'Plants',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: BotanlyColors.sage,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(_searchOpen ? Icons.close : Icons.search,
                color: BotanlyColors.moss),
            onPressed: () => setState(() {
              _searchOpen = !_searchOpen;
              if (!_searchOpen) _query = '';
            }),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: BotanlyColors.paper,
          border: Border.all(color: BotanlyColors.sand),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          style: GoogleFonts.dmSans(fontSize: 14, color: BotanlyColors.ink),
          decoration: InputDecoration(
            hintText: 'Search plants…',
            hintStyle: GoogleFonts.dmSans(
              color: BotanlyColors.inkMute,
              fontWeight: FontWeight.w300,
              fontSize: 14,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            icon: const Icon(Icons.search,
                color: BotanlyColors.inkMute, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _filterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: _filters
            .map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _filter == f
                            ? BotanlyColors.sage
                            : Colors.white,
                        border: Border.all(
                          color: _filter == f
                              ? BotanlyColors.sage
                              : BotanlyColors.sand,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        f,
                        style: GoogleFonts.dmSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: _filter == f
                              ? Colors.white
                              : BotanlyColors.inkSoft,
                        ),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_outlined,
              size: 56, color: BotanlyColors.sage.withOpacity(.4)),
          const SizedBox(height: 12),
          Text('No plants match your filter',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: BotanlyColors.inkMute,
              )),
        ],
      ),
    );
  }
}

class _PlantTile extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;
  const _PlantTile({required this.plant, required this.onTap});

  Color get _accent {
    if (plant.notificationState == 'overdue') return BotanlyColors.red;
    if (plant.notificationState == 'due' || plant.shouldWaterNow) {
      return BotanlyColors.amber;
    }
    return BotanlyColors.sage;
  }

  String get _nextWaterLabel {
    final diff = plant.nextWatering.difference(DateTime.now()).inDays;
    if (diff <= 0) return 'Today';
    return 'in ${diff}d';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: BotanlyColors.paper,
          border: Border.all(color: BotanlyColors.sand),
          borderRadius: BorderRadius.circular(20),
          boxShadow: BotanlyShadows.card,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: plant.imageUrl != null
                  ? Image.network(
                      plant.imageUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _PlantPlaceholder(),
                    )
                  : _PlantPlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plant.name,
                      style: GoogleFonts.fraunces(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: BotanlyColors.moss,
                      )),
                  Text(plant.species,
                      style: GoogleFonts.fraunces(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: BotanlyColors.inkMute,
                      )),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: _accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Next watering ${_nextWaterLabel}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: BotanlyColors.inkMute,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: BotanlyColors.inkMute),
          ],
        ),
      ),
    );
  }
}

class _PlantPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA7C59E), Color(0xFF5E7B58)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
