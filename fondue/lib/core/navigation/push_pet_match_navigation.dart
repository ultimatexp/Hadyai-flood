import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'push_chat_navigation.dart';
import '../../features/pets/data/pet_repository.dart';
import '../../features/pets/presentation/pet_detail_screen.dart';

/// Must match Edge Function `push-pet-match` FCM `data.type`.
const String kPushPetMatchType = 'PET_MATCH';

bool isPetMatchPushPayload(Map<String, dynamic> data) {
  final type = data['type']?.toString();
  final foundId = data['found_pet_id']?.toString();
  return type == kPushPetMatchType && foundId != null && foundId.isNotEmpty;
}

/// Opens the found pet from a potential-match push (`found_pet_id` in FCM data).
Future<void> openPetMatchFromPushData(Map<String, dynamic> data) async {
  if (!isPetMatchPushPayload(data)) return;

  final foundPetId = data['found_pet_id']!.toString();
  final repo = PetRepository(Supabase.instance.client);
  final pet = await repo.fetchPetById(foundPetId);
  if (pet == null) return;

  final nav = fondueNavigatorKey.currentState;
  if (nav == null || !nav.mounted) return;

  await nav.push<void>(
    MaterialPageRoute<void>(
      builder: (_) => PetDetailScreen(pet: pet),
    ),
  );
}
