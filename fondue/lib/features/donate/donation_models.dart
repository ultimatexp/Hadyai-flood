import 'donation_mock_avatars.dart';

class Donation {
  final String id;
  final int amountSatang;
  final String? displayName;
  final DateTime createdAt;
  /// Bundled mock photo for seed rows; null for real donations.
  final String? avatarAssetPath;

  const Donation({
    required this.id,
    required this.amountSatang,
    this.displayName,
    required this.createdAt,
    this.avatarAssetPath,
  });

  String get label {
    final n = displayName?.trim();
    if (n == null || n.isEmpty) return 'นิรนาม';
    return n;
  }

  String get amountThbText {
    final thb = amountSatang / 100;
    if (thb == thb.roundToDouble()) {
      return '฿${thb.toInt()}';
    }
    return '฿${thb.toStringAsFixed(0)}';
  }

  factory Donation.fromMap(Map<String, dynamic> m) {
    final session = m['stripe_checkout_session_id'] as String?;
    return Donation(
      id: m['id'] as String,
      amountSatang: (m['amount_satang'] as num).toInt(),
      displayName: m['display_name'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
      avatarAssetPath: mockAvatarAssetForStripeSession(session),
    );
  }
}

class TopDonor {
  final String displayName;
  final int totalSatang;
  final int donationCount;
  final String? avatarAssetPath;

  const TopDonor({
    required this.displayName,
    required this.totalSatang,
    required this.donationCount,
    this.avatarAssetPath,
  });

  String get totalThbText => '฿${(totalSatang / 100).round()}';

  factory TopDonor.fromMap(Map<String, dynamic> m) {
    final name = m['display_name'] as String;
    return TopDonor(
      displayName: name,
      totalSatang: (m['total_satang'] as num).toInt(),
      donationCount: (m['donation_count'] as num).toInt(),
      avatarAssetPath: mockAvatarAssetForDisplayName(name),
    );
  }
}

String donationInitial(String name) {
  final t = name.trim();
  if (t.isEmpty) return '?';
  return String.fromCharCode(t.runes.first).toUpperCase();
}
