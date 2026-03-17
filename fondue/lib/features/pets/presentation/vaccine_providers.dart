import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/vaccine_schedule.dart';
import 'pet_profile_providers.dart';

/// Provider that computes the vaccine schedule for a given pet profile
final vaccineScheduleProvider = FutureProvider.family<VaccineScheduleResult, String>(
  (ref, petProfileId) async {
    final profile = await ref.watch(petProfileProvider(petProfileId).future);
    final records = await ref.watch(medicalRecordsProvider(petProfileId).future);

    if (profile == null) {
      return VaccineScheduleResult(
        coreVaccines: [],
        optionalVaccines: [],
        shieldScore: 0,
      );
    }

    return computeVaccineSchedule(
      species: profile.species,
      birthday: profile.birthday,
      records: records,
    );
  },
);
