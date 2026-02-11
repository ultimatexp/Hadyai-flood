import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage user points
class PointsService {
  static const String _pointsKey = 'user_points';
  
  /// Point rewards
  static const int reportFoundPetPoints = 100;
  static const int reportLostPetPoints = 50;
  static const int helpingPetPoints = 25;
  
  /// Get current points
  Future<int> getPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pointsKey) ?? 0;
  }
  
  /// Add points
  Future<int> addPoints(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_pointsKey) ?? 0;
    final newTotal = current + amount;
    await prefs.setInt(_pointsKey, newTotal);
    return newTotal;
  }
  
  /// Set points (for testing/reset)
  Future<void> setPoints(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pointsKey, amount);
  }
  
  /// Award points for reporting a found pet
  Future<int> awardFoundPetPoints() async {
    return addPoints(reportFoundPetPoints);
  }
  
  /// Award points for reporting a lost pet
  Future<int> awardLostPetPoints() async {
    return addPoints(reportLostPetPoints);
  }
  
  /// Award points for helping find a pet
  Future<int> awardHelpingPoints() async {
    return addPoints(helpingPetPoints);
  }
}

/// Provider for PointsService
final pointsServiceProvider = Provider<PointsService>((ref) => PointsService());

/// Notifier for managing points state
class PointsNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final service = ref.read(pointsServiceProvider);
    return service.getPoints();
  }
  
  /// Add points and update state
  Future<void> addPoints(int amount) async {
    final service = ref.read(pointsServiceProvider);
    final newTotal = await service.addPoints(amount);
    state = AsyncData(newTotal);
  }
  
  /// Award points for found pet report
  Future<void> awardFoundPetPoints() async {
    await addPoints(PointsService.reportFoundPetPoints);
  }
  
  /// Award points for lost pet report  
  Future<void> awardLostPetPoints() async {
    await addPoints(PointsService.reportLostPetPoints);
  }
  
  /// Refresh points from storage
  Future<void> refresh() async {
    state = const AsyncLoading();
    final service = ref.read(pointsServiceProvider);
    state = AsyncData(await service.getPoints());
  }
}

/// Provider for user points
final pointsProvider = AsyncNotifierProvider<PointsNotifier, int>(PointsNotifier.new);
