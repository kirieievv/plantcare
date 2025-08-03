import 'package:flutter/material.dart';
import '../models/plant.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onWater;
  final VoidCallback onTap;

  const PlantCard({
    super.key,
    required this.plant,
    required this.onWater,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final needsWater = now.isAfter(plant.nextWatering);
    final daysUntilWatering = plant.nextWatering.difference(now).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Plant Image or Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: needsWater ? Colors.orange.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: (needsWater ? Colors.orange : Colors.green).withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: plant.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.network(
                          plant.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.local_florist, size: 30, color: needsWater ? Colors.orange.shade600 : Colors.green.shade600),
                        ),
                      )
                    : Icon(
                        Icons.local_florist,
                        size: 30,
                        color: needsWater ? Colors.orange.shade600 : Colors.green.shade600,
                      ),
              ),
              const SizedBox(width: 16),
              
              // Plant Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plant.species,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.water_drop,
                          size: 16,
                          color: needsWater ? Colors.orange : Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          needsWater
                              ? 'Needs watering!'
                              : 'Water in $daysUntilWatering days',
                          style: TextStyle(
                            fontSize: 12,
                            color: needsWater ? Colors.orange : Colors.grey[600],
                            fontWeight: needsWater ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Water Button
              if (needsWater)
                ElevatedButton.icon(
                  onPressed: onWater,
                  icon: const Icon(Icons.water_drop, size: 16),
                  label: const Text('Water'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 