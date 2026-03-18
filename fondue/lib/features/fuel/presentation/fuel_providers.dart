import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/fuel_repository.dart';
import '../domain/fuel_type.dart';
import '../domain/gas_station.dart';

// Repository
final fuelRepositoryProvider = Provider<FuelRepository>((ref) {
  return FuelRepository(Supabase.instance.client);
});

// Fuel types
final fuelTypesProvider = FutureProvider<List<FuelType>>((ref) async {
  final repo = ref.watch(fuelRepositoryProvider);
  return repo.fetchFuelTypes();
});

// Selected radius
class SelectedRadiusNotifier extends Notifier<double> {
  @override
  double build() => 10;

  void set(double value) => state = value;
}

final selectedRadiusProvider =
    NotifierProvider<SelectedRadiusNotifier, double>(SelectedRadiusNotifier.new);

// User location
final userLocationProvider = FutureProvider<Position?>((ref) async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) {
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  } catch (e) {
    return null;
  }
});

// Stations
final stationsProvider = FutureProvider<List<GasStation>>((ref) async {
  final repo = ref.watch(fuelRepositoryProvider);
  final location = await ref.watch(userLocationProvider.future);
  final radius = ref.watch(selectedRadiusProvider);

  // Use user location if within Thailand, otherwise fallback to Hat Yai
  double lat = 7.0058;
  double lng = 100.4745;
  if (location != null &&
      location.latitude >= 5.5 && location.latitude <= 20.5 &&
      location.longitude >= 97.3 && location.longitude <= 105.7) {
    lat = location.latitude;
    lng = location.longitude;
  }

  return repo.fetchStations(lat: lat, lng: lng, radius: radius);
});

// Selected station
class SelectedStationNotifier extends Notifier<GasStation?> {
  @override
  GasStation? build() => null;

  void set(GasStation? station) => state = station;
}

final selectedStationProvider =
    NotifierProvider<SelectedStationNotifier, GasStation?>(SelectedStationNotifier.new);

// Fingerprint for anonymous voting
final fingerprintProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getString('fuel_fingerprint');
  if (existing != null) return existing;

  final fp = '${Random().nextInt(999999999).toRadixString(36)}'
      '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
  await prefs.setString('fuel_fingerprint', fp);
  return fp;
});

// Filter: selected fuel type
class SelectedFuelTypeNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final selectedFuelTypeProvider =
    NotifierProvider<SelectedFuelTypeNotifier, String>(SelectedFuelTypeNotifier.new);

// Filter: selected brand
class SelectedBrandNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final selectedBrandProvider =
    NotifierProvider<SelectedBrandNotifier, String>(SelectedBrandNotifier.new);

// Filtered stations
final filteredStationsProvider = Provider<AsyncValue<List<GasStation>>>((ref) {
  final stationsAsync = ref.watch(stationsProvider);
  final fuelType = ref.watch(selectedFuelTypeProvider);
  final brand = ref.watch(selectedBrandProvider);

  return stationsAsync.whenData((stations) {
    var result = stations;
    if (fuelType.isNotEmpty) {
      result = result.where((s) => s.fuelTypes.contains(fuelType)).toList();
    }
    if (brand.isNotEmpty) {
      result = result.where((s) => s.brand == brand).toList();
    }
    return result;
  });
});
