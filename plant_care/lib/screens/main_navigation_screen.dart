import 'package:flutter/material.dart';
import 'package:plant_care/screens/dashboard_screen.dart';
import 'package:plant_care/screens/plant_list_screen.dart';
import 'package:plant_care/screens/add_plant_screen.dart';
import 'package:plant_care/screens/profile_screen.dart';
import 'package:plant_care/screens/settings_screen.dart';
import 'package:plant_care/screens/plant_details_screen.dart';
import 'package:plant_care/services/navigation_service.dart';
import 'package:plant_care/services/plant_service.dart';
import 'package:plant_care/utils/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainNavigationScreen extends StatefulWidget {
  final User? user;

  const MainNavigationScreen({Key? key, this.user}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  List<Widget> _screens = [];
  
  @override
  void initState() {
    super.initState();
    
    // Check if user is null before initializing screens
    if (widget.user == null) {
      print('❌ MainNavigationScreen: User is null, cannot initialize screens');
      return;
    }
    
    _screens = [
      DashboardScreen(user: widget.user),
      const PlantListScreen(),
      const AddPlantScreen(),
      const ProfileScreen(),
      SettingsScreen(user: widget.user!),
    ];
    
    // Check if user should return to a specific plant details page
    _checkNavigationState();
  }
  
  Future<void> _checkNavigationState() async {
    print('🌱 MainNavigationScreen: Checking navigation state...');
    
    // On app reload, always clear navigation state and start with home page
    // This ensures the app opens to the dashboard instead of trying to return to plant details
    await NavigationService.clearNavigationState();
    print('🌱 MainNavigationScreen: Navigation state cleared, starting with home page');
    
    // Set current index to 0 (Home/Dashboard) to ensure home page is shown
    setState(() {
      _currentIndex = 0;
    });
  }
  
  @override
  Widget build(BuildContext context) {
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
                'Authentication Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please log in again to continue',
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
                child: const Text('Go to Login'),
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
          color: AppTheme.white,
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowGrey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.list_alt_rounded, 'My Plants'),
                _buildNavItem(2, Icons.add_circle_outline_rounded, 'Add Plant'),
                _buildNavItem(3, Icons.person_outline_rounded, 'Profile'),
                _buildNavItem(4, Icons.settings_outlined, 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.accentGreen.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? AppTheme.accentGreen : AppTheme.darkGrey,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppTheme.accentGreen : AppTheme.darkGrey,
            ),
          ),
        ],
      ),
    );
  }
} 