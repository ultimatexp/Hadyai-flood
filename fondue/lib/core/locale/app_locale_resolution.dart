import 'package:flutter/material.dart';

/// Uses the platform’s preferred locale list: Thai → [th], anything else → [en].
Locale? fondueLocaleListResolution(
  List<Locale>? preferredLocales,
  Iterable<Locale> _,
) {
  if (preferredLocales == null || preferredLocales.isEmpty) {
    return null;
  }
  for (final locale in preferredLocales) {
    if (locale.languageCode == 'th') {
      return const Locale('th');
    }
  }
  return const Locale('en');
}

/// Fallback when only a single device [locale] is available.
Locale fondueLocaleResolution(Locale? locale, Iterable<Locale> _) {
  if (locale != null && locale.languageCode == 'th') {
    return const Locale('th');
  }
  return const Locale('en');
}
