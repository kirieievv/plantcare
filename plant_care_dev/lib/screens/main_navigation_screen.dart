import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plant_care/screens/dashboard_screen.dart';
import 'package:plant_care/screens/plant_list_screen.dart';
import 'package:plant_care/screens/add_plant_screen.dart';
import 'package:plant_care/screens/profile_screen.dart';
import 'package:plant_care/screens/settings_screen.dart';
import 'package:plant_care/services/navigation_service.dart';
import 'package:plant_care/services/plant_service.dart';
import 'package:plant_care/theme/botanly_theme.dart';
import 'package:plant_care/widgets/botanly_nav_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plant_care/l10n/app_localizations.dart';

class MainNavigationScreen extends StatefulWidget {
  final User? user;
  final int initialIndex;

  const MainNavigationScreen({Key? key, this.user, this.initialIndex = 0}) : super(key: key);

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
      DashboardScreen(user: widget.user, onTabChange: changeTab),
      PlantListScreen(onAddPlant: () => setState(() => _currentIndex = 2)),
      AddPlantScreen(onPlantAdded: () => setState(() => _currentIndex = 1)), // switch to My Plants on success
      const ProfileScreen(),
      SettingsScreen(user: widget.user!),
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
  }
  
  Future<void> _checkNavigationState() async {
    print('🌱 MainNavigationScreen: Checking navigation state...');
    
    // On app reload, always clear navigation state and start with home page
    // This ensures the app opens to the dashboard instead of trying to return to plant details
    await NavigationService.clearNavigationState();
    print('🌱 MainNavigationScreen: Navigation state cleared, starting with home page');
    
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
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
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
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
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
    
    // Bottom nav: visual layer from `Botanly /screens/dashboard_screen.html`.
    // Logic preserved from production main_navigation_screen.
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : BotanlyColors.navBarBg,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : BotanlyColors.sand,
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, l10n.home),
                _buildNavItem(1, l10n.myPlants),
                _buildNavItem(2, l10n.addPlant),
                _buildNavItem(3, l10n.profile),
                _buildNavItem(4, l10n.settings),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label) {
    final isSelected = _currentIndex == index;
    final stroke =
        isSelected ? Colors.white : BotanlyColors.navIconMuted;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
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
                  color: isSelected
                      ? BotanlyColors.navActiveFill
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? BotanlyShadows.navActiveIconDrop
                      : null,
                ),
                child: BotanlyNavGlyph(
                  tabIndex: index,
                  stroke: stroke,
                  size: 22,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10.5,
                  fontWeight:
                      isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: isSelected
                      ? BotanlyColors.sage
                      : BotanlyColors.navLabelMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 