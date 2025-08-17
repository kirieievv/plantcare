import 'package:flutter/material.dart';
import 'package:plant_care/screens/dashboard_screen.dart';
import 'package:plant_care/screens/plant_list_screen.dart';
import 'package:plant_care/screens/add_plant_screen.dart';
import 'package:plant_care/screens/profile_screen.dart';
import 'package:plant_care/screens/settings_screen.dart';
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
  
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(user: widget.user),
      const PlantListScreen(),
      const AddPlantScreen(),
      const ProfileScreen(),
      SettingsScreen(user: widget.user!),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
              color: isSelected ? AppTheme.lightBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.darkGrey,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.darkGrey,
            ),
          ),
        ],
      ),
    );
  }
} 