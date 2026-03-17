import 'package:flutter/material.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import '../models/plant.dart';
import '../services/plant_service.dart';
import '../widgets/plant_card.dart';
import '../utils/app_theme.dart';
import 'plant_details_screen.dart';

class PlantListScreen extends StatelessWidget {
  const PlantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plantService = PlantService();

    return Scaffold(
      // Header removed - clean interface
      body: SafeArea(
        child: StreamBuilder<List<Plant>>(
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
                    Text('${l10n.errorLabel}: ${snapshot.error}'),
                  ],
                ),
              );
            }

            final plants = snapshot.data ?? [];

            if (plants.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_florist, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noPlantsYet,
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.addFirstPlantToGetStarted,
                      style: const TextStyle(color: Colors.grey),
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
      ),
    );
  }
} 