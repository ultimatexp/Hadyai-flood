import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pet_providers.dart';
import 'widgets/pet_card.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myReportsAsync = ref.watch(myReportsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Consistent background
      appBar: AppBar(
        title: const Text('My Reports'),
        backgroundColor: const Color(0xFFFF9800), // Orange theme
        foregroundColor: Colors.white,
      ),
      body: myReportsAsync.when(
        data: (pets) {
          if (pets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No reports yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reports you submit will appear here.',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              return ref.refresh(myReportsProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pets.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final pet = pets[index];
                return PetCard(pet: pet);
              },
            ),
          );
        },
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
