/// What the assistant knows about one plant.
///
/// This screen is part of the memory being correct, not a view onto it. Facts
/// are extracted by a language model from what the owner said; occasionally it
/// will extract something the owner did not mean. Such a fact is then repeated
/// in every answer, quietly, and there is no other place it can be seen or
/// removed. A memory nobody can inspect is a memory nobody can trust.
///
/// It reads as a history rather than a settings list on purpose. "Moved to the
/// east window in July, back in September" says something neither entry says
/// alone, and the same is true of a symptom that keeps returning.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/models/plant_fact.dart';
import 'package:plant_care/theme/botanly_theme.dart';

class PlantMemoryScreen extends StatelessWidget {
  final Plant plant;

  const PlantMemoryScreen({super.key, required this.plant});

  Query<Map<String, dynamic>> get _facts => FirebaseFirestore.instance
      .collection('plants')
      .doc(plant.id)
      .collection('facts')
      .orderBy('statedAt', descending: true)
      .limit(200);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAF5),
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.memoryTitle,
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: BotanlyColors.ink,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _facts.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _Message(text: l10n.memoryLoadFailed);
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          final facts = snapshot.data!.docs
              .map((d) => PlantFact.fromDoc(d.id, d.data()))
              .whereType<PlantFact>()
              .toList();

          if (facts.isEmpty) {
            // Not an error state. A plant nobody has told the assistant
            // anything about genuinely has nothing here, and saying so beats an
            // empty list that looks broken.
            return _Message(text: l10n.memoryEmpty(plant.name));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: facts.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    l10n.memoryExplainer,
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      height: 1.4,
                      color: BotanlyColors.inkMute,
                    ),
                  ),
                );
              }
              return _FactTile(fact: facts[index - 1], plantId: plant.id);
            },
          );
        },
      ),
    );
  }
}

class _FactTile extends StatelessWidget {
  final PlantFact fact;
  final String plantId;

  const _FactTile({required this.fact, required this.plantId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = fact.isCurrent;

    return Opacity(
      // Superseded facts stay legible but plainly past — they are why the
      // history reads as a history, and hiding them would take the pattern with
      // them.
      opacity: current ? 1 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x14000000)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fact.text,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      height: 1.35,
                      color: BotanlyColors.ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    [
                      _kindLabel(l10n, fact.kind),
                      DateFormat.yMMMd().format(fact.statedAt),
                      if (!current) l10n.memorySuperseded,
                    ].join(' · '),
                    style: GoogleFonts.dmSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: BotanlyColors.inkMute,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _confirmDelete(context, l10n),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 17, color: Color(0xFF9AA79D)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    HapticFeedback.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.memoryForgetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.memoryForgetAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // A real delete, not another supersede. The owner asking to forget
    // something is a different act from the assistant learning a newer value,
    // and half-forgetting would leave it still shaping the answers.
    await FirebaseFirestore.instance
        .collection('plants')
        .doc(plantId)
        .collection('facts')
        .doc(fact.id)
        .delete();
  }

  String _kindLabel(AppLocalizations l10n, String kind) => switch (kind) {
    'placement' => l10n.memoryKindPlacement,
    'container' => l10n.memoryKindContainer,
    'watering_habit' => l10n.memoryKindWateringHabit,
    'species_correction' => l10n.memoryKindSpecies,
    'environment' => l10n.memoryKindEnvironment,
    'intervention' => l10n.memoryKindIntervention,
    'symptom' => l10n.memoryKindSymptom,
    'constraint' => l10n.memoryKindConstraint,
    'goal' => l10n.memoryKindGoal,
    'preference' => l10n.memoryKindPreference,
    _ => kind,
  };
}

class _Message extends StatelessWidget {
  final String text;
  const _Message({required this.text});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          height: 1.45,
          color: BotanlyColors.inkMute,
        ),
      ),
    ),
  );
}
