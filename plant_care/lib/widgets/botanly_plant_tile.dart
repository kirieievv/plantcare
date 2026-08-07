import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/theme/botanly_theme.dart';

/// Plant list/dashboard tile styled per `dashboard_screen.html` /
/// `plant_list_screen.html`.
///
/// Visual: paper card 20-radius, sand border, small status accent bar at the
/// left, 62×62 thumb, name (Fraunces 17), status pill (sage/amber/red) and a
/// circular water button on the right. Tapping the card opens details (handled
/// by [onTap]); tapping the water button calls [onWater].
class BotanlyPlantTile extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;
  final VoidCallback onWater;

  const BotanlyPlantTile({
    super.key,
    required this.plant,
    required this.onTap,
    required this.onWater,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = plant.nextWatering;
    final dueDay = DateTime(due.year, due.month, due.day);
    final days = dueDay.difference(today).inDays;

    final waterNow =
        plant.shouldWaterNow &&
        plant.wateringMode != 'recheck_only' &&
        (plant.wateringAmountMl == null || plant.wateringAmountMl! > 0);
    final overdue = !waterNow && days < 0;
    final dueSoon = !waterNow && days >= 0 && days <= 1;
    final accent = waterNow
        ? BotanlyColors.sageLight
        : overdue
        ? BotanlyColors.red
        : dueSoon
        ? BotanlyColors.amber
        : BotanlyColors.sageLight;
    final accentBg = waterNow
        ? BotanlyColors.sagePale
        : overdue
        ? BotanlyColors.redPale
        : dueSoon
        ? BotanlyColors.amberPale
        : BotanlyColors.sagePale;

    final String statusLabel;
    if (waterNow) {
      statusLabel = l10n.nowLabel;
    } else if (overdue) {
      statusLabel = l10n.wateringOverdueNDays(days.abs());
    } else if (days == 0) {
      statusLabel = l10n.wateringToday;
    } else if (days == 1) {
      statusLabel = l10n.wateringTomorrow;
    } else {
      statusLabel = l10n.wateringInNDays(days);
    }

    return Material(
      color: BotanlyColors.paper,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
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
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: FractionallySizedBox(
                  heightFactor: 0.64,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(3),
                        bottomRight: Radius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    _Thumb(imageUrl: plant.imageUrl),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            plant.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.fraunces(
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              color: BotanlyColors.moss,
                              letterSpacing: -0.17,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.fromLTRB(6, 3, 9, 3),
                            decoration: BoxDecoration(
                              color: accentBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  statusLabel,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _WaterButton(
                      state: overdue
                          ? _WaterState.overdue
                          : (days == 0 ||
                                plant.shouldWaterNow ||
                                plant.notificationState == 'due')
                          ? _WaterState.needsWater
                          : _WaterState.inactive,
                      onTap: onWater,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? imageUrl;
  const _Thumb({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: BotanlyColors.sand,
        borderRadius: BorderRadius.circular(14),
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Text('🌱', style: TextStyle(fontSize: 26, height: 1)),
              ),
            )
          : const Center(
              child: Text('🌱', style: TextStyle(fontSize: 26, height: 1)),
            ),
    );
  }
}

enum _WaterState { overdue, needsWater, inactive }

class _WaterButton extends StatelessWidget {
  final _WaterState state;
  final VoidCallback onTap;
  const _WaterButton({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool clickable = state != _WaterState.inactive;
    final Color bg;
    final Color fg;
    switch (state) {
      case _WaterState.overdue:
        bg = BotanlyColors.red.withValues(alpha: 0.14);
        fg = BotanlyColors.red;
        break;
      case _WaterState.needsWater:
        bg = BotanlyColors.sage.withValues(alpha: 0.16);
        fg = BotanlyColors.sage;
        break;
      case _WaterState.inactive:
        bg = const Color(0xFFEDEFEA);
        fg = const Color(0xFFB6BEB1);
        break;
    }
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: clickable ? onTap : null,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(Icons.water_drop_rounded, size: 18, color: fg),
        ),
      ),
    );
  }
}
