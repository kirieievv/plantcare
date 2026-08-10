import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plant_care/screens/home_screen.dart';
import 'package:plant_care/screens/my_plants_screen.dart';
import 'package:plant_care/screens/add_plant_screen_v4.dart';
import 'package:plant_care/screens/profile_v4_screen.dart';
import 'package:plant_care/screens/settings_v4_screen.dart';
import 'package:plant_care/services/navigation_service.dart';
import 'package:plant_care/theme/botanly_glass.dart';
import 'package:plant_care/widgets/botanly_nav_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plant_care/l10n/app_localizations.dart';

/// Where the "Add plant" tab sits in the shell.
///
/// Named because three different places send the user here — the paywall CTA,
/// the empty plant list and the limit screen — and a bare `2` scattered across
/// them quietly breaks the day someone reorders the menu.
const int kAddPlantTabIndex = 2;

/// Where the plant list sits. Same reason.
const int kMyPlantsTabIndex = 1;

class MainNavigationScreen extends StatefulWidget {
  final User? user;
  final int initialIndex;

  /// Cross-screen request to show a given tab.
  ///
  /// A pushed screen (plant details, for instance) cannot reach this widget's
  /// state through the tree, and go_router reuses the existing instance for
  /// `/home`, so re-navigating there does not re-run initState and the tab
  /// stays where it was. Bumping this notifier is the one reliable way in.
  static final ValueNotifier<int> tabRequest = ValueNotifier<int>(0);

  /// Asks the shell to show [index].
  ///
  /// Goes through -1 first because a `ValueNotifier` stays silent when the value
  /// does not change — and "take me Home" is usually issued while the notifier
  /// already holds 0, which is precisely when the shell needs to be told. The
  /// listener ignores the out-of-range value.
  static void requestTab(int index) {
    tabRequest.value = -1;
    tabRequest.value = index;
  }

  const MainNavigationScreen({Key? key, this.user, this.initialIndex = 0})
    : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  List<Widget> _screens = [];

  // Method to change the current tab index
  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();

    // Check if user is null before initializing screens
    if (widget.user == null) {
      print('❌ MainNavigationScreen: User is null, cannot initialize screens');
      return;
    }

    _screens = [
      HomeScreen(user: widget.user, onTabChange: changeTab),
      MyPlantsScreen(
        onAddPlant: () => setState(() => _currentIndex = kAddPlantTabIndex),
      ),
      // v4 redesign; the pre-v4 screen stays in the tree as
      // add_plant_screen.dart until the new flow has been through QA.
      AddPlantScreenV4(
        onPlantAdded: () => setState(() => _currentIndex = kMyPlantsTabIndex),
        onOpenPlants: () => setState(() => _currentIndex = kMyPlantsTabIndex),
      ),
      const ProfileV4Screen(),
      SettingsV4Screen(user: widget.user!),
    ];

    // ⚠️ IMPORTANT: AUTOMATIC NAVIGATION FEATURE ⚠️
    // The AddPlantScreen automatically redirects users to their newly created plant's details page
    // after successful plant creation. This provides a better user experience.
    //
    // User flow: Add Plant Tab → AddPlantScreen → Create Plant → Automatically redirected to PlantDetailsScreen
    //
    // If you need to modify this behavior:
    // 1. Check the AddPlantScreen navigation logic first
    // 2. Ensure the change works from all entry points (Dashboard, Bottom Navigation)
    // 3. Test thoroughly to ensure user experience is maintained or improved
    //
    // Related files: add_plant_screen.dart, plant_details_screen.dart, plant_service.dart

    // Check if user should return to a specific plant details page
    _checkNavigationState();

    // Set the initial index from the parameter
    setState(() {
      _currentIndex = widget.initialIndex;
    });

    MainNavigationScreen.tabRequest.addListener(_onTabRequested);
  }

  @override
  void dispose() {
    MainNavigationScreen.tabRequest.removeListener(_onTabRequested);
    super.dispose();
  }

  void _onTabRequested() {
    final index = MainNavigationScreen.tabRequest.value;
    if (!mounted || index < 0 || index >= _screens.length) return;
    setState(() => _currentIndex = index);
  }

  Future<void> _checkNavigationState() async {
    print('🌱 MainNavigationScreen: Checking navigation state...');

    // On app reload, always clear navigation state and start with home page
    // This ensures the app opens to the dashboard instead of trying to return to plant details
    await NavigationService.clearNavigationState();
    print(
      '🌱 MainNavigationScreen: Navigation state cleared, starting with home page',
    );

    // Only set current index to 0 if no initialIndex was specified
    // This allows other screens to specify which tab should be selected
    if (widget.initialIndex == 0) {
      setState(() {
        _currentIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Check if screens are initialized
    if (_screens.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                l10n.authenticationError,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.pleaseLoginAgain,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/welcome'),
                child: Text(l10n.goToLogin),
              ),
            ],
          ),
        ),
      );
    }

    // Floating glass tab bar (v3 handoff): 14 px insets, radius 28,
    // rgba(255,255,255,.66) over blur(30px). It sits *over* the content rather
    // than pushing it up — that is what makes the screen read as one surface.
    return Scaffold(
      extendBody: true,
      // The design's base tone rather than transparent: every tab paints its own
      // background, and this is only ever seen for a frame during a switch.
      backgroundColor: isDark ? const Color(0xFF0D1117) : kGlassBase,
      body: _screens[_currentIndex],
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          14,
          0,
          14,
          14 + MediaQuery.of(context).padding.bottom,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // blur(30px)
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xE6161B22)
                    : const Color(0xA8FFFFFF), // rgba(255,255,255,.66)
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xBFFFFFFF),
                  width: 0.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4D142010),
                    blurRadius: 34,
                    spreadRadius: -10,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                // Its own layer: inside the backdrop filter the web renderer
                // kept showing the previously selected tile for a beat.
                child: RepaintBoundary(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final labels = [
                        l10n.tabHome,
                        l10n.tabPlants,
                        l10n.tabAdd,
                        l10n.tabProfile,
                        l10n.tabSettings,
                      ];
                      final size = _labelSize(
                        context,
                        labels,
                        constraints.maxWidth,
                      );
                      return Row(
                        children: [
                          for (var i = 0; i < labels.length; i++)
                            _buildNavItem(i, labels[i], size),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Base size of a tab label, and the floor it never goes under.
  static const _labelBase = 11.0;

  /// How far a label may follow the system size before the cell runs out.
  static const _labelMaxScale = 1.15;

  /// One size for all five labels, chosen by the longest of them.
  ///
  /// Per-label sizing was the other option and it looks broken: five words at
  /// five different sizes read as a rendering fault, not as a considered
  /// layout. So the widest word sets the size and the rest follow it.
  ///
  /// The floor is the base size, never below: a label that does not fit at
  /// 11 px is a translation problem, and the fix is a shorter word rather than
  /// smaller type. That is why "Мои растения" is now "Растения" — it never fit,
  /// even before Dynamic Type existed.
  double _labelSize(
    BuildContext context,
    List<String> labels,
    double barWidth,
  ) {
    // The cell as the Row actually divides it, minus this item's own padding —
    // measured rather than assumed, so a 320 pt SE and a 430 pt Pro Max each
    // get their real budget.
    final budget = barWidth / labels.length - 2 * 2;
    if (budget <= 0) return _labelBase;

    final wanted = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: _labelMaxScale).scale(_labelBase);

    var widest = 0.0;
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: glassFont(fontSize: _labelBase, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.size.width);
    }

    // Glyph advances scale with the type size, so the ratio is the largest size
    // the widest word still fits at.
    final fits = widest > 0 ? _labelBase * budget / widest : wanted;
    return math.min(wanted, fits).clamp(_labelBase, wanted);
  }

  Widget _buildNavItem(int index, String label, double labelSize) {
    final isSelected = _currentIndex == index;
    final stroke = isSelected ? Colors.white : kGlassMut;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 44,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? kGlassAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: kGlassAccent.withAlpha(204),
                            blurRadius: 16,
                            spreadRadius: -8,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: BotanlyNavGlyph(
                  tabIndex: index,
                  stroke: stroke,
                  size: 21,
                ),
              ),
              const SizedBox(height: 5),
              // Sized above against the real cell width, so scaling it again
              // here would double-count the system setting. The icon keeps its
              // 21 px either way — growing it is what pushes the bar taller.
              MediaQuery.withNoTextScaling(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: glassFont(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? kGlassGreenText : kGlassMut,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
