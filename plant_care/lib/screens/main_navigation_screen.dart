import 'package:flutter/material.dart';
import 'package:plant_care/screens/dashboard_screen.dart';
import 'package:plant_care/screens/plant_list_screen.dart';
import 'package:plant_care/screens/add_plant_screen.dart';
import 'package:plant_care/screens/profile_screen.dart';
import 'package:plant_care/screens/settings_screen.dart';
import 'package:plant_care/services/navigation_service.dart';
import 'package:plant_care/services/plant_service.dart';
import 'package:plant_care/utils/app_theme.dart';
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
      const PlantListScreen(),
      const AddPlantScreen(), // ⚠️ IMPORTANT: This screen has automatic navigation feature
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
                onPressed: () {
                  // Navigate back to auth screen
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/auth',
                    (route) => false,
                  );
                },
                child: Text(l10n.goToLogin),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.grey.shade100,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, l10n.home),
                _buildNavItem(1, Icons.eco_outlined, l10n.myPlants),
                _buildNavItem(2, Icons.add_circle_outlined, l10n.addPlant),
                _buildNavItem(3, Icons.person_outlined, l10n.profile),
                _buildNavItem(4, Icons.settings_outlined, l10n.settings),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final greenLight = const Color(0xFF7BC67E);
    final greenDark = const Color(0xFF5AB85D);

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [greenLight, greenDark],
                    )
                  : null,
              color: isSelected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: greenDark.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? AppTheme.white : Colors.grey.shade600,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppTheme.greenDark : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
} 