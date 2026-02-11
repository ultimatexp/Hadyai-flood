import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier for the dashboard's current tab index
class DashboardTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

/// Provider for the dashboard's current tab index
final dashboardTabIndexProvider = NotifierProvider<DashboardTabNotifier, int>(DashboardTabNotifier.new);
