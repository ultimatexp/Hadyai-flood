import 'package:flutter/material.dart';
import '../../domain/pet.dart';
import '../pet_detail_screen.dart';
import '../../../../../core/theme/app_theme.dart';

class PetCard extends StatelessWidget {
  final Pet pet;

  const PetCard({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PetDetailScreen(pet: pet),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Reward Badge
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: pet.imageUrl != null
                      ? Image.network(
                          pet.imageUrl!, // In production this needs full URL processing if typically stored as relative
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.pets, size: 64, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.pets, size: 64, color: Colors.grey),
                        ),
                ),
                // Reward Badge
                if (pet.reward != null && pet.reward! > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '฿${_formatReward(pet.reward!)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            
            // Details Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        pet.status, 
                        style: TextStyle(
                          color: pet.status == 'LOST' ? Colors.red : AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (pet.createdAt != null)
                        Text(
                          // Simple date formatter (add intl package for real formatting)
                          "${pet.createdAt.day}/${pet.createdAt.month}/${pet.createdAt.year}",
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pet.species, // Or name if available
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pet.description ?? "No description",
                          style: TextStyle(color: Colors.grey[800]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatReward(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
