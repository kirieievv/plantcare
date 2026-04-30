import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/botanly_theme.dart';
import '../models/plant.dart';
import '../services/plant_service.dart';
import 'plant_chat_screen.dart';
import 'edit_plant_screen.dart';

class PlantDetailsScreen extends StatefulWidget {
  final Plant plant;
  const PlantDetailsScreen({super.key, required this.plant});

  @override
  State<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends State<PlantDetailsScreen> {
  late Plant _plant;
  int _heroIndex = 0;
  bool _accordionOpen = true;
  
  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
  }

  String get _nextWaterLabel {
    final diff = _plant.nextWatering.difference(DateTime.now()).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return DateFormat('MMM d').format(_plant.nextWatering);
  }

  String get _nextWaterSub {
    final diff = _plant.nextWatering.difference(DateTime.now()).inDays;
    if (diff <= 0) return 'water now';
    return 'in $diff day${diff == 1 ? '' : 's'}';
  }

  bool get _canWaterNow =>
      _plant.shouldWaterNow ||
      _plant.notificationState == 'due' ||
      _plant.notificationState == 'overdue';

  String get _statusLabel {
    final state = _plant.notificationState;
    if (state == 'overdue') return 'Overdue';
    if (state == 'due' || _plant.shouldWaterNow) return 'Needs water';
    return 'Healthy';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      floatingActionButton: _buildFab(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHero()),
          SliverToBoxAdapter(child: _buildInfoCard()),
          SliverToBoxAdapter(child: _buildAiCareCard()),
          SliverToBoxAdapter(child: _buildAccordion()),
          if (_plant.aiSpecificIssues != null &&
              _plant.aiSpecificIssues!.isNotEmpty)
            SliverToBoxAdapter(child: _buildIssuesCard()),
          SliverToBoxAdapter(child: _buildDeleteButton()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ──────────────── Hero ────────────────

  Widget _buildHero() {
    return Stack(
              children: [
        _plant.imageUrl != null
            ? Image.network(
                _plant.imageUrl!,
                height: 360,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _heroGradient(),
              )
            : _heroGradient(),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(.35),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(.35),
                  ],
                  stops: const [0.0, .3, .65, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.9),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
              ),
            ],
          ),
                child: const Icon(Icons.chevron_left,
                    color: BotanlyColors.moss, size: 22),
              ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _heroGradient() {
    return Container(
      height: 360,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFBCD4B5),
            Color(0xFF8FB186),
            Color(0xFF5E7B58),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  // ──────────────── Info card ────────────────

  Widget _buildInfoCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: BotanlyColors.line),
          borderRadius: BorderRadius.circular(20),
          boxShadow: BotanlyShadows.cardElevated,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_plant.name, style: BotanlyText.plantName()),
                      const SizedBox(height: 6),
                      Text(_plant.species,
                          style: BotanlyText.latin()),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: _canWaterNow
                              ? BotanlyColors.amberPale
                              : BotanlyColors.sagePale2,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                              _canWaterNow
                                  ? Icons.water_drop_outlined
                                  : Icons.check,
                              color: _canWaterNow
                                  ? BotanlyColors.amber
                                  : BotanlyColors.sageDark,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(_statusLabel,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                                  color: _canWaterNow
                                      ? BotanlyColors.amber
                                      : BotanlyColors.sageDark,
                                )),
                          ],
                  ),
                ),
              ],
            ),
                ),
                if (_plant.aiName != null)
                  Container(
      decoration: BoxDecoration(
                      color: BotanlyColors.sagePale2,
                      border: Border.all(color: BotanlyColors.sagePale),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Text('AI Agent',
                          style: GoogleFonts.dmSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: BotanlyColors.sageDark,
                          )),
                    ),
          ),
        ],
      ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                    child: _careCard(
                  icon: Icons.water_drop_outlined,
                  iconColor: BotanlyColors.sage,
                  bg: BotanlyColors.sageSoft,
                  border: BotanlyColors.sagePale,
                  label: 'Watering',
                  value: _nextWaterLabel,
                  sub: _nextWaterSub,
                  extra: _plant.wateringAmountMl != null
                      ? _mlPill(_plant.wateringAmountMl!)
                            : null,
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: _careCard(
                  icon: Icons.wb_sunny_outlined,
                  iconColor: BotanlyColors.amber,
                  bg: BotanlyColors.amberPale,
                  border: const Color(0xFFEBD9B8),
                  label: 'Light',
                  value: _plant.aiLight ?? '—',
                  sub: 'per day',
                  valueColor: BotanlyColors.amber,
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: _careCard(
                  icon: Icons.opacity,
                  iconColor: BotanlyColors.sage,
                  bg: BotanlyColors.sageSoft,
                  border: BotanlyColors.sagePale,
                  label: 'Soil',
                  value: _plant.aiMoistureLevel ?? 'Moist',
                  sub: 'ideal',
                )),
              ],
            ),
            const SizedBox(height: 18),
            Row(
      children: [
                Expanded(child: _waterButton()),
                const SizedBox(width: 10),
                Expanded(child: _editButton()),
              ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _careCard({
    required IconData icon,
    required Color iconColor,
    required Color bg,
    required Color border,
    required String label,
    required String value,
    required String sub,
    Widget? extra,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 4),
          Text(label,
            textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
              fontSize: 11,
                fontWeight: FontWeight.w500,
                color: BotanlyColors.inkMute,
              )),
          const SizedBox(height: 2),
          Text(value,
            textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? BotanlyColors.sageDark,
              )),
          const SizedBox(height: 2),
          Text(sub,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w300,
                color: BotanlyColors.inkMute,
              )),
          if (extra != null) ...[const SizedBox(height: 4), extra],
        ],
      ),
    );
  }

  Widget _mlPill(int ml) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: BotanlyColors.bluePale,
        border: Border.all(color: const Color(0xFFCADFEE)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text('$ml ml',
          style: GoogleFonts.dmSans(
              fontSize: 11,
            fontWeight: FontWeight.w400,
            color: BotanlyColors.blue,
          )),
    );
  }

  Widget _waterButton() {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: _canWaterNow
            ? () async {
                await PlantService().waterPlant(_plant.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${_plant.name} watered!',
                          style: GoogleFonts.dmSans(fontSize: 13)),
                      backgroundColor: BotanlyColors.moss,
                    ),
                  );
                }
              }
            : null,
        icon: const Icon(Icons.water_drop_outlined, size: 16),
        label: Text(
          _canWaterNow ? 'Water now' : 'Next in $_nextWaterSub',
          style: GoogleFonts.dmSans(
            fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                              style: ElevatedButton.styleFrom(
          backgroundColor:
              _canWaterNow ? BotanlyColors.sage : Colors.white,
          foregroundColor:
              _canWaterNow ? Colors.white : BotanlyColors.inkMute,
          disabledBackgroundColor: Colors.white,
          disabledForegroundColor: BotanlyColors.inkMute,
          side: _canWaterNow
              ? null
              : const BorderSide(color: BotanlyColors.line),
                                shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: _canWaterNow ? 2 : 0,
        ),
      ),
    );
  }

  Widget _editButton() {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditPlantScreen(plant: _plant),
            ),
          );
        },
        icon: const Icon(Icons.edit_outlined, size: 16,
            color: BotanlyColors.sage),
        label: Text('Edit plant',
            style: GoogleFonts.dmSans(
              fontSize: 13,
                                  fontWeight: FontWeight.w600,
              color: BotanlyColors.sage,
            )),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: BotanlyColors.sagePale),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
                  ),
    );
  }

  // ──────────────── AI care card ────────────────

  Widget _buildAiCareCard() {
    if (_plant.healthMessage == null && _plant.aiGeneralDescription == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: BotanlyColors.sageSoft,
          border: Border.all(color: BotanlyColors.sagePale),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
                const Icon(Icons.eco_outlined,
                    size: 17, color: BotanlyColors.sage),
              const SizedBox(width: 8),
                Text('Plant Care Assistant',
                    style: BotanlyText.smallHeading(
                        color: BotanlyColors.sageDark)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: BotanlyColors.sagePale2,
                border: Border.all(color: BotanlyColors.sagePale),
              borderRadius: BorderRadius.circular(8),
              ),
                child: Text(
                _plant.healthMessage ??
                    _plant.aiGeneralDescription ??
                    '',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: BotanlyColors.sageDark,
                  height: 1.45,
                ),
                ),
              ),
            ],
          ),
      ),
    );
  }

  // ──────────────── Care Recommendations accordion ────────────────

  Widget _buildAccordion() {
    final hasContent = _plant.aiCareTips != null ||
        _plant.aiGeneralDescription != null ||
        _plant.aiMoistureLevel != null ||
        _plant.interestingFacts != null;
    if (!hasContent) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: BotanlyColors.sagePale),
        borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
            InkWell(
              onTap: () =>
                  setState(() => _accordionOpen = !_accordionOpen),
                child: Container(
                color: BotanlyColors.sageSoft,
                padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: BotanlyColors.sagePale,
                          shape: BoxShape.circle,
                        ),
                      child: const Icon(Icons.lightbulb_outline,
                          size: 18, color: BotanlyColors.sage),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                      child: Text('Care Recommendations',
                          style: BotanlyText.sectionTitle()),
                    ),
                    AnimatedRotation(
                      turns: _accordionOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down,
                          color: BotanlyColors.sage, size: 22),
            ),
          ],
        ),
                ),
              ),
            if (_accordionOpen)
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    if (_plant.aiGeneralDescription != null)
                      _CareSection(
                        icon: Icons.info_outline,
                        title: 'General Description',
                        body: _plant.aiGeneralDescription!,
                      ),
                    if (_plant.aiMoistureLevel != null)
                      _CareSection(
                        icon: Icons.opacity,
                        title: 'Ideal Soil Moisture',
                        body: _plant.aiMoistureLevel!,
                      ),
                    if (_plant.aiLight != null)
                      _CareSection(
                        icon: Icons.wb_sunny_outlined,
                        title: 'Light',
                        body: _plant.aiLight!,
                      ),
                    if (_plant.aiCareTips != null)
                      _CareSection(
                        icon: Icons.info_outline,
                        title: 'Care Tips',
                        body: _plant.aiCareTips!,
                      ),
                    if (_plant.interestingFacts != null &&
                        _plant.interestingFacts!.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _InterestingFacts(facts: _plant.interestingFacts!),
                    ],
                  ],
              ),
            ),
            ],
          ),
        ),
      );
    }
    
  // ──────────────── Specific Issues ────────────────

  Widget _buildIssuesCard() {
    final issues = _plant.aiSpecificIssues!
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (issues.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: BotanlyColors.yellowPale,
          border: Border.all(color: BotanlyColors.yellowBorder),
          borderRadius: BorderRadius.circular(16),
          boxShadow: BotanlyShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
                const Icon(Icons.info_outline,
                    color: BotanlyColors.yellowText, size: 18),
              const SizedBox(width: 8),
                Text('Specific issues',
                    style: BotanlyText.smallHeading(
                        color: BotanlyColors.yellowText)),
              ],
            ),
            const SizedBox(height: 8),
            ...issues.map((line) => Padding(
                  padding:
                      const EdgeInsets.only(left: 12, top: 2, bottom: 2),
                  child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                      Text('• ',
                          style: GoogleFonts.dmSans(
                            color: BotanlyColors.yellowText,
                          )),
                      Expanded(
                        child: Text(line,
                            style: GoogleFonts.dmSans(
            fontSize: 13,
                              fontWeight: FontWeight.w300,
                              color: BotanlyColors.yellowBody,
            height: 1.5,
                            )),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ──────────────── Delete ────────────────

  Widget _buildDeleteButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: TextButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Delete this plant?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete',
                          style:
                              TextStyle(color: BotanlyColors.red))),
                ],
              ),
            );
            if (confirm == true && mounted) {
              await PlantService().deletePlant(_plant.id);
              if (mounted) Navigator.maybePop(context);
            }
          },
          icon: const Icon(Icons.delete_outline,
              size: 12, color: BotanlyColors.red),
          label: Text('Delete plant',
              style: GoogleFonts.dmSans(
                fontSize: 11.5,
            fontWeight: FontWeight.w600,
                color: BotanlyColors.red,
              )),
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: BotanlyColors.red),
                    borderRadius: BorderRadius.circular(999),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          ),
        ),
      ),
    );
  }

  // ──────────────── FAB ────────────────

  Widget _buildFab() {
                return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [BotanlyColors.sage, BotanlyColors.sageDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
                    shape: BoxShape.circle,
        boxShadow: BotanlyShadows.fab,
            ),
            child: IconButton(
        iconSize: 22,
        onPressed: () => Navigator.push(
          context,
                  MaterialPageRoute(
            builder: (_) =>
                PlantChatScreen(plantName: _plant.name),
          ),
        ),
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }
}

// ────────────────────────── helpers ──────────────────────────

class _CareSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool iconFilled;
  const _CareSection({
    required this.icon,
    required this.title,
    required this.body,
    this.iconFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
                      Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: BotanlyColors.sagePale,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    color: BotanlyColors.sage,
                    size: 14,
                    fill: iconFilled ? 1 : 0),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: GoogleFonts.fraunces(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF3A4A3A),
                      letterSpacing: -.2,
                      height: 1.2,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(body,
              style: GoogleFonts.dmSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF6A6A6A),
                height: 1.6,
              )),
        ],
      ),
    );
  }
}

class _InterestingFacts extends StatelessWidget {
  final List<String> facts;
  const _InterestingFacts({required this.facts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome,
                size: 16, color: BotanlyColors.sage),
            const SizedBox(width: 8),
            Text('Interesting facts',
                style:
                    BotanlyText.smallHeading(color: BotanlyColors.sage)),
          ],
        ),
        const SizedBox(height: 10),
        ...facts.asMap().entries.map((e) => _FactCard(
              text: e.value,
              funny: e.key == facts.length - 1,
            )),
      ],
    );
  }
}

class _FactCard extends StatelessWidget {
  final String text;
  final bool funny;
  const _FactCard({required this.text, required this.funny});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: funny ? const Color(0xFFFFFAF1) : Colors.white,
        border: Border.all(
          color: funny
              ? BotanlyColors.amber.withOpacity(.45)
              : BotanlyColors.sage.withOpacity(.4),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(funny ? '✦' : '•',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: funny ? BotanlyColors.amber : BotanlyColors.sage,
              )),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: BotanlyColors.inkSoft,
                  height: 1.45,
                )),
            ),
        ],
      ),
    );
  }
}
