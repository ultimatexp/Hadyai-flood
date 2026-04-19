import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../dashboard/data/dashboard_providers.dart';

/// One-shot image to start a search on the home tab (e.g. after reporting a pet).
class PendingSemanticSearchPayload {
  final XFile initialImage;
  const PendingSemanticSearchPayload({required this.initialImage});
}

class _PendingSearchNotifier extends Notifier<PendingSemanticSearchPayload?> {
  @override
  PendingSemanticSearchPayload? build() => null;
}

final pendingSemanticSearchProvider =
    NotifierProvider<_PendingSearchNotifier, PendingSemanticSearchPayload?>(
        _PendingSearchNotifier.new);

/// Switches to dashboard pet-search tab and clears any full-screen routes stacked above it.
void switchToHomePetSearch(
  WidgetRef ref,
  BuildContext context, {
  XFile? initialImage,
}) {
  ref.read(dashboardTabIndexProvider.notifier).setTab(0);
  if (initialImage != null) {
    ref.read(pendingSemanticSearchProvider.notifier).state =
        PendingSemanticSearchPayload(initialImage: initialImage);
  }
  Navigator.of(context).popUntil((route) => route.isFirst);
}
