import 'package:flutter/material.dart';
import '../models/plant.dart';
import '../services/plant_service.dart';
import '../services/auth_service.dart';
import '../widgets/plant_card.dart';
import 'auth_screen.dart';
import 'add_plant_screen.dart';
import 'plant_details_screen.dart';

class PlantListScreen extends StatelessWidget {
  const PlantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plantService = PlantService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Plants'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'signout') {
                await AuthService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    const Icon(Icons.logout),
                    const SizedBox(width: 8),
                    Text('Sign Out (${AuthService.currentUser?.email ?? 'User'})'),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.account_circle),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Plant>>(
        stream: plantService.getPlants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final plants = snapshot.data ?? [];

          if (plants.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_florist, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No plants yet!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your first plant to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plants.length,
            itemBuilder: (context, index) {
              final plant = plants[index];
              return PlantCard(
                plant: plant,
                onWater: () => plantService.waterPlant(plant.id),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlantDetailsScreen(plant: plant),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddPlantScreen(),
            ),
          );
          // Refresh the list if a plant was added
          if (result == true) {
            // The stream will automatically update
          }
        },
        tooltip: 'Add Plant',
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
} 