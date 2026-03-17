import '../data/vaccine_schedule_data.dart';
import 'medical_record.dart';

/// Status of a single vaccine for a pet
enum VaccinationState {
  upToDate,   // ✅ ฉีดครบตามกำหนด
  dueSoon,    // 🟡 ใกล้ถึงกำหนด (ภายใน 14 วัน)
  overdue,    // 🔴 เกินกำหนด
  notStarted, // ⬜ ยังไม่เคยฉีด
  notApplicable, // ⏳ ยังไม่ถึงอายุ
}

class VaccineStatus {
  final VaccineInfo vaccineInfo;
  final List<MedicalRecord> administeredDoses;
  final VaccinationState state;
  final DateTime? nextDueDate;
  final int dosesCompleted;
  final int dosesRequired;

  VaccineStatus({
    required this.vaccineInfo,
    required this.administeredDoses,
    required this.state,
    this.nextDueDate,
    required this.dosesCompleted,
    required this.dosesRequired,
  });

  /// Completion progress 0.0 to 1.0 for this vaccine
  double get progress {
    if (dosesRequired == 0) return 1.0;
    return (dosesCompleted / dosesRequired).clamp(0.0, 1.0);
  }

  String get stateLabel {
    switch (state) {
      case VaccinationState.upToDate:
        return 'ฉีดครบ';
      case VaccinationState.dueSoon:
        return 'ใกล้กำหนด';
      case VaccinationState.overdue:
        return 'เกินกำหนด!';
      case VaccinationState.notStarted:
        return 'ยังไม่เริ่ม';
      case VaccinationState.notApplicable:
        return 'ยังไม่ถึงอายุ';
    }
  }
}

/// Compute the overall shield score and per-vaccine status
class VaccineScheduleResult {
  final List<VaccineStatus> coreVaccines;
  final List<VaccineStatus> optionalVaccines;
  final double shieldScore; // 0.0 to 1.0

  VaccineScheduleResult({
    required this.coreVaccines,
    required this.optionalVaccines,
    required this.shieldScore,
  });

  int get overdueCount => [...coreVaccines, ...optionalVaccines]
      .where((v) => v.state == VaccinationState.overdue)
      .length;

  int get dueSoonCount => [...coreVaccines, ...optionalVaccines]
      .where((v) => v.state == VaccinationState.dueSoon)
      .length;

  int get upToDateCount => [...coreVaccines, ...optionalVaccines]
      .where((v) => v.state == VaccinationState.upToDate)
      .length;
}

/// Compute vaccine statuses for a pet
VaccineScheduleResult computeVaccineSchedule({
  required String species,
  required DateTime? birthday,
  required List<MedicalRecord> records,
}) {
  final vaccines = getVaccinesForSpecies(species);
  final vaccineRecords = records
      .where((r) => r.recordType == 'vaccination')
      .toList();

  final now = DateTime.now();
  final ageWeeks = birthday != null
      ? now.difference(birthday).inDays ~/ 7
      : 999; // if no birthday, assume adult

  final List<VaccineStatus> statuses = [];

  for (final vaccine in vaccines) {
    // Find matching records by checking title similarity
    final matchingDoses = vaccineRecords.where((r) {
      final titleLower = r.title.toLowerCase();
      final nameThLower = vaccine.nameTh.toLowerCase();
      final nameEnLower = vaccine.nameEn.toLowerCase();
      final idLower = vaccine.id.replaceAll('_', ' ');

      return titleLower.contains(nameThLower) ||
          nameThLower.contains(titleLower) ||
          titleLower.contains(nameEnLower) ||
          nameEnLower.contains(titleLower) ||
          titleLower.contains(idLower) ||
          // Also match by vaccine ID stored in metadata
          (r.metadata['vaccine_id'] == vaccine.id);
    }).toList();

    matchingDoses.sort((a, b) => b.date.compareTo(a.date)); // newest first

    final dosesCompleted = matchingDoses.length;
    final dosesRequired = vaccine.doses;

    // Determine state
    VaccinationState state;
    DateTime? nextDue;

    if (ageWeeks < vaccine.initialAgeWeeks) {
      // Pet is too young for this vaccine
      state = VaccinationState.notApplicable;
      nextDue = birthday?.add(Duration(days: vaccine.initialAgeWeeks * 7));
    } else if (dosesCompleted == 0) {
      // Never vaccinated
      state = VaccinationState.notStarted;
    } else {
      // Has been vaccinated — check if booster is needed
      final lastDose = matchingDoses.first;

      if (dosesCompleted < dosesRequired && vaccine.boosterWeeks != null) {
        // Still in primary series
        nextDue = lastDose.date.add(Duration(days: vaccine.boosterWeeks! * 7));
      } else {
        // Primary series complete, check annual booster
        nextDue = lastDose.date.add(Duration(days: vaccine.annualBoosterDays));
      }

      // Use the explicit nextDueDate from the record if available
      if (lastDose.nextDueDate != null) {
        nextDue = lastDose.nextDueDate;
      }

      if (nextDue != null && now.isAfter(nextDue)) {
        state = VaccinationState.overdue;
      } else if (nextDue != null && nextDue.difference(now).inDays <= 14) {
        state = VaccinationState.dueSoon;
      } else {
        state = VaccinationState.upToDate;
      }
    }

    statuses.add(VaccineStatus(
      vaccineInfo: vaccine,
      administeredDoses: matchingDoses,
      state: state,
      nextDueDate: nextDue,
      dosesCompleted: dosesCompleted,
      dosesRequired: dosesRequired,
    ));
  }

  final core = statuses.where((s) => s.vaccineInfo.isCore).toList();
  final optional = statuses.where((s) => !s.vaccineInfo.isCore).toList();

  // Shield score = % of core vaccines that are up-to-date
  final coreApplicable = core.where((s) => s.state != VaccinationState.notApplicable).toList();
  final coreUpToDate = coreApplicable.where((s) => s.state == VaccinationState.upToDate).length;
  final shieldScore = coreApplicable.isEmpty ? 1.0 : coreUpToDate / coreApplicable.length;

  return VaccineScheduleResult(
    coreVaccines: core,
    optionalVaccines: optional,
    shieldScore: shieldScore,
  );
}
