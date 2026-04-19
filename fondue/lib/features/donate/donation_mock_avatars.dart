// Mock donor photos: assets/images/donator_mock/, keyed by Stripe seed session ids and seed display_name.

const List<String> kDonationMockStripeSessions = [
  'cs_test_mock_seed_001',
  'cs_test_mock_seed_002',
  'cs_test_mock_seed_003',
  'cs_test_mock_seed_004',
  'cs_test_mock_seed_005',
];

const List<String> kDonationMockAvatarAssets = [
  'assets/images/donator_mock/491831334_23986495150951953_477815985111971891_n.jpg',
  'assets/images/donator_mock/496946321_24200261156242017_8533186764981034510_n.jpg',
  'assets/images/donator_mock/613951458_26282532198014892_5043793969763835720_n.jpg',
  'assets/images/donator_mock/614599598_26282531788014933_5340925473299261495_n.jpg',
  'assets/images/donator_mock/81132143_3058874444140662_5181893178088751104_n.jpg',
];

String? mockAvatarAssetForStripeSession(String? sessionId) {
  if (sessionId == null) return null;
  final i = kDonationMockStripeSessions.indexOf(sessionId);
  if (i < 0) return null;
  return kDonationMockAvatarAssets[i];
}

/// Matches seed [display_name] values (with or without `คุณ` prefix).
String? mockAvatarAssetForDisplayName(String displayName) {
  const indexByName = <String, int>{
    'แอน': 0,
    'บีม': 1,
    'ซีโน': 2,
    'ดีน': 3,
    'อีฟ': 4,
  };
  final t = displayName.trim();
  var i = indexByName[t];
  i ??= indexByName[t.replaceFirst(RegExp(r'^คุณ'), '')];
  if (i == null) return null;
  return kDonationMockAvatarAssets[i];
}
