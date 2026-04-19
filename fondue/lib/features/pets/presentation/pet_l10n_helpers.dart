import 'package:flutter/widgets.dart';
import 'package:fondue/l10n/app_localizations.dart';

String localizedPetStatus(BuildContext context, String status) {
  final l10n = AppLocalizations.of(context)!;
  return switch (status.toUpperCase()) {
    'LOST' => l10n.petStatusLost,
    'FOUND' => l10n.petStatusFound,
    'REUNITED' => l10n.petStatusReunited,
    _ => status,
  };
}

String localizedSex(BuildContext context, String sex) {
  final l10n = AppLocalizations.of(context)!;
  return switch (sex) {
    'Male' => l10n.petSexMale,
    'Female' => l10n.petSexFemale,
    'Unknown' => l10n.petSexUnknown,
    _ => sex,
  };
}

String mapViewFormatTimeAgo(BuildContext context, DateTime date) {
  final l10n = AppLocalizations.of(context)!;
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 30) {
    return l10n.mapViewTimeMonthsAgo((diff.inDays / 30).floor());
  }
  if (diff.inDays > 0) {
    return l10n.mapViewTimeDaysAgo(diff.inDays);
  }
  if (diff.inHours > 0) {
    return l10n.mapViewTimeHoursAgo(diff.inHours);
  }
  return l10n.mapViewTimeMinutesAgo(diff.inMinutes);
}
