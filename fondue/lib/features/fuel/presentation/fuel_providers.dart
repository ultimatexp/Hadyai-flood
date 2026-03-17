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

  if (location == null) return [];

  return repo.fetchStations(
    lat: location.latitude,
    lng: location.longitude,
    radius: radius,
  );
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
