import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'donation_mock_avatars.dart';
import 'donation_models.dart';

List<TopDonor> aggregateTopDonorsFromRows(List<Map<String, dynamic>> rows) {
  final totals = <String, int>{};
  final counts = <String, int>{};
  for (final m in rows) {
    final raw = m['display_name'];
    final name = raw is String ? raw.trim() : '';
    if (name.isEmpty) continue;
    final sat = (m['amount_satang'] as num?)?.toInt() ?? 0;
    if (sat <= 0) continue;
    totals[name] = (totals[name] ?? 0) + sat;
    counts[name] = (counts[name] ?? 0) + 1;
  }
  final list = totals.entries
      .map(
        (e) => TopDonor(
          displayName: e.key,
          totalSatang: e.value,
          donationCount: counts[e.key] ?? 1,
          avatarAssetPath: mockAvatarAssetForDisplayName(e.key),
        ),
      )
      .toList();
  list.sort((a, b) {
    final byTotal = b.totalSatang.compareTo(a.totalSatang);
    if (byTotal != 0) return byTotal;
    return b.donationCount.compareTo(a.donationCount);
  });
  return list.take(10).toList();
}

final latestDonationsProvider = StreamProvider.autoDispose<List<Donation>>((ref) async* {
  Future<List<Donation>> fetch() async {
    final rows = await Supabase.instance.client
        .from('donations')
        .select('id, amount_satang, display_name, created_at, stripe_checkout_session_id')
        .order('created_at', ascending: false)
        .limit(10);
    final list = (rows as List<dynamic>).map((e) => Donation.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    return list;
  }

  try {
    yield await fetch();
  } catch (e) {
    assert(() {
      debugPrint('latestDonations: $e');
      return true;
    }());
    yield const [];
  }

  yield* Stream.periodic(const Duration(seconds: 35), (_) => {}).asyncMap((_) async {
    try {
      return await fetch();
    } catch (e) {
      assert(() {
        debugPrint('latestDonations poll: $e');
        return true;
      }());
      return const <Donation>[];
    }
  });
});

/// Leaderboard from `donations` rows (no RPC) so it works as soon as the table exists.
final topDonorsProvider = FutureProvider.autoDispose<List<TopDonor>>((ref) async {
  try {
    final rows = await Supabase.instance.client.from('donations').select('display_name, amount_satang');
    return aggregateTopDonorsFromRows((rows as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList());
  } catch (e) {
    assert(() {
      debugPrint('topDonors: $e');
      return true;
    }());
    return const [];
  }
});
