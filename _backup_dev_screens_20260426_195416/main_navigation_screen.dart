import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/botanly_theme.dart';
import '../widgets/botanly_nav_icons.dart';
import 'dashboard_screen.dart';
import 'plant_list_screen.dart';
import 'add_plant_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// Shell aligned with `Botanly /screens/dashboard_screen.html` (white app band,
/// bottom nav: white bar, 46×36 icon slots, stroke SVGs, green active chip).
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _idx = widget.initialIndex;

  void changeTab(int index) {
    setState(() => _idx = index);
  }

  static const _phoneMax = 420.0;

  static const _tabLabels = [
    'Home',
    'My Plants',
    'Add Plant',
    'Profile',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BotanlyColors.chromeBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final band = math.min(constraints.maxWidth, _phoneMax);
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: band,
                height: constraints.maxHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ColoredBox(
                        color: BotanlyColors.cabinetBg,
                        child: SizedBox.expand(
                          child: KeyedSubtree(
                            key: ValueKey<int>(_idx),
                            child: _pageForIndex(_idx),
                          ),
                        ),
                      ),
                    ),
                    _BottomNavBar(
                      labels: _tabLabels,
                      activeIndex: _idx,
                      onSelect: (i) => setState(() => _idx = i),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _pageForIndex(int i) {
    switch (i) {
      case 0:
        return DashboardScreen(onTabChange: changeTab);
      case 1:
        return const PlantListScreen();
      case 2:
        return const AddPlantScreen();
      case 3:
        return const ProfileScreen();
      case 4:
        return const SettingsScreen();
      default:
        return DashboardScreen(onTabChange: changeTab);
    }
  }
}

class _BottomNavBar extends StatelessWidget {
  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  const _BottomNavBar({
    required this.labels,
    required this.activeIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: BotanlyColors.navBarBg,
        border: Border(top: BorderSide(color: BotanlyColors.sand)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 22),
        child: Row(
          children: List.generate(labels.length, (i) {
            final active = activeIndex == i;
            final stroke =
                active ? Colors.white : BotanlyColors.navIconMuted;
            return Expanded(
              child: InkWell(
                onTap: () => onSelect(i),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 46,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active
                              ? BotanlyColors.navActiveFill
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow:
                              active ? BotanlyShadows.navActiveIconDrop : null,
                        ),
                        child: BotanlyNavGlyph(
                          tabIndex: i,
                          stroke: stroke,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        labels[i],
                        style: GoogleFonts.dmSans(
                          fontSize: 10.5,
                          fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                          color: active
                              ? BotanlyColors.sage
                              : BotanlyColors.navLabelMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
