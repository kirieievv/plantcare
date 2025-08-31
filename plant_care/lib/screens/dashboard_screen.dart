import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/models/user_model.dart';
import 'package:plant_care/services/plant_service.dart';
import 'package:plant_care/services/user_service.dart';
import 'package:plant_care/utils/app_theme.dart';
import 'package:plant_care/widgets/plant_card.dart';
import 'package:plant_care/screens/add_plant_screen.dart';
import 'package:plant_care/screens/plant_details_screen.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// KRV 2
class DashboardScreen extends StatefulWidget {
  final User? user;
  final Function(int)? onTabChange;

  const DashboardScreen({Key? key, this.user, this.onTabChange}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserModel? _userProfile;
  bool _isLoading = false;
  bool _hasRunCleanup = false;

  @override
  void initState() {
    super.initState();
    _runInitialCleanup();
  }

  Future<void> _runInitialCleanup() async {
    if (_hasRunCleanup) return;
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Run cleanup in background to fix corrupted data
      await PlantService().cleanupCorruptedPlants();
      
      // Load user profile after cleanup
      await _loadUserProfile();
      
      setState(() {
        _isLoading = false;
        _hasRunCleanup = true;
      });
    } catch (e) {
      print('❌ Dashboard: Error during initial cleanup: $e');
      
      // Still try to load user profile even if cleanup fails
      await _loadUserProfile();
      
      setState(() {
        _isLoading = false;
        _hasRunCleanup = true;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await UserService.getCurrentUserProfile();
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      body: _isLoading
          ? _buildShimmerLoading()
          : CustomScrollView(
              slivers: [
                // Header removed - clean interface
                
                // Temporary delete Foxglove button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final success = await PlantService().deletePlantByName('Foxglove');
                          if (success) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Foxglove plant deleted successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              setState(() {}); // Refresh the screen
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Foxglove plant not found or could not be deleted'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error deleting Foxglove plant: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                      label: const Text('Delete Foxglove Plant', style: TextStyle(color: Colors.white, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Your Garden Overview Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Garden Overview',
                          style: AppTheme.headingMedium.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ).animate().fadeIn(
                          duration: 600.ms,
                          delay: 200.ms,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Enhanced Garden Stats Cards
                        StreamBuilder<List<Plant>>(
                          stream: PlantService().getPlants(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return _buildShimmerStats();
                            }
                            
                            final plants = snapshot.data ?? [];
                            final plantsNeedingWater = plants.where((p) => 
                              p.nextWatering.isBefore(DateTime.now())
                            ).length;
                            final healthyPlants = plants.where((p) => 
                              p.nextWatering.isAfter(DateTime.now().add(const Duration(days: 1)))
                            ).length;
                            
                            return Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Total Plants',
                                    '${plants.length}',
                                    Icons.eco,
                                    AppTheme.accentGreen,
                                    0.ms,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatCard(
                                    'Need Water',
                                    '$plantsNeedingWater',
                                    Icons.water_drop,
                                    Colors.orange,
                                    200.ms,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatCard(
                                    'Healthy',
                                    '$healthyPlants',
                                    Icons.check_circle,
                                    AppTheme.accentGreen,
                                    400.ms,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Your Plants Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Plants',
                              style: AppTheme.headingMedium.copyWith(
                                color: AppTheme.textPrimary,
                              ),
                            ).animate().fadeIn(
                              duration: 600.ms,
                              delay: 600.ms,
                            ),
                            
                            // Enhanced Add Plant Button
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.accentGreen,
                                    AppTheme.accentGreen.withOpacity(0.8),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accentGreen.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  // Use the callback to switch to Add Plant tab (index 2)
                                  if (widget.onTabChange != null) {
                                    widget.onTabChange!(2);
                                  } else {
                                    // Fallback: navigate to AddPlantScreen if callback not available
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AddPlantScreen(),
                                      ),
                                    );
                                    
                                    // Check if plant was created successfully
                                    if (result != null && result['success'] == true) {
                                      final plantId = result['plantId'];
                                      print('🌱 Dashboard: Plant created successfully with ID: $plantId');
                                      
                                      // Refresh the plants list to show the new plant
                                      setState(() {});
                                      
                                      // Show success message
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Plant created successfully! 🌱'),
                                            backgroundColor: Colors.green,
                                            duration: Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: const Text(
                                  'Add Plant',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ).animate().scale(
                              duration: 400.ms,
                              delay: 800.ms,
                              curve: Curves.elasticOut,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Test button removed - clean interface
                      ],
                    ),
                  ),
                ),
                
                // Plants List with Enhanced Cards
                StreamBuilder<List<Plant>>(
                  stream: PlantService().getPlants(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SliverToBoxAdapter(
                        child: _buildShimmerPlants(),
                      );
                    }

                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text('Error: ${snapshot.error}'),
                            ],
                          ),
                        ),
                      );
                    }

                    final plants = snapshot.data ?? [];

                    if (plants.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _buildEmptyState(),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final plant = plants[index];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                            child: PlantCard(
                              plant: plant,
                              onWater: () => PlantService().waterPlant(plant.id),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlantDetailsScreen(plant: plant),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: plants.length,
                      ),
                    );
                  },
                ),
                
                const SliverToBoxAdapter(
                  child: SizedBox(height: 32),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, Duration delay) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 160,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.2),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ).animate().scale(
              duration: 400.ms,
              delay: delay,
              curve: Curves.elasticOut,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTheme.headingLarge.copyWith(
                color: color,
                fontSize: 28,
              ),
            ).animate().fadeIn(
              duration: 400.ms,
              delay: delay + 200.ms,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                title,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ).animate().fadeIn(
                duration: 400.ms,
                delay: delay + 400.ms,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: AppTheme.lightGrey,
      highlightColor: AppTheme.white,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildShimmerStats()),
          SliverToBoxAdapter(child: _buildShimmerPlants()),
        ],
      ),
    );
  }

  Widget _buildShimmerStats() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: List.generate(3, (index) => Expanded(
          child: Container(
            height: 160,
            margin: EdgeInsets.only(right: index < 2 ? 16 : 0),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildShimmerPlants() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: List.generate(3, (index) => Container(
          height: 140,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(20),
          ),
        )),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 200,
        borderRadius: 20,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.5),
            Colors.white.withOpacity(0.2),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_florist,
              size: 64,
              color: AppTheme.mediumGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'No plants yet!',
              style: AppTheme.headingMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first plant to get started',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 