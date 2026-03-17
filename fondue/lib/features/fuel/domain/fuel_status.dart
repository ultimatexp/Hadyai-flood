import 'dart:ui';

class FuelStatus {
  final String consensusStatus;
  final int voteCount;
  final DateTime lastVotedAt;
  final double confidence;

  const FuelStatus({
    required this.consensusStatus,
    required this.voteCount,
    required this.lastVotedAt,
    required this.confidence,
  });

  factory FuelStatus.fromJson(Map<String, dynamic> json) {
    return FuelStatus(
      consensusStatus: json['consensus_status'] as String? ?? 'unknown',
      voteCount: json['vote_count'] as int? ?? 0,
      lastVotedAt: DateTime.tryParse(json['last_voted_at']?.toString() ?? '') ?? DateTime.now(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DecisiveStatus {
  final String label;
  final Color color;
  final int bars;
  final bool needsVerify;

  const DecisiveStatus({
    required this.label,
    required this.color,
    required this.bars,
    required this.needsVerify,
  });
}

DecisiveStatus getDecisiveStatus(FuelStatus? status) {
  if (status == null) {
    return const DecisiveStatus(
      label: 'ยังไม่มีรายงาน',
      color: Color(0xFF94A3B8),
      bars: 0,
      needsVerify: true,
    );
  }

  final now = DateTime.now();
  final diffHours = now.difference(status.lastVotedAt).inMinutes / 60.0;

  final isAvailable = status.consensusStatus == 'available' ||
      status.consensusStatus == 'refilled';
  final isOut = status.consensusStatus == 'out_of_stock';

  if (diffHours > 24) {
    return const DecisiveStatus(
      label: 'ข้อมูลเก่า · รอยืนยัน',
      color: Color(0xFF94A3B8),
      bars: 0,
      needsVerify: true,
    );
  }

  if (isAvailable) {
    if (diffHours < 6 && (status.confidence > 80 || status.voteCount >= 5)) {
      return const DecisiveStatus(
        label: 'มีน้ำมันแน่นอน',
        color: Color(0xFF22C55E),
        bars: 3,
        needsVerify: false,
      );
    }
    return const DecisiveStatus(
      label: 'แจ้งว่ามี · รอยืนยัน',
      color: Color(0xFFF59E0B),
      bars: 2,
      needsVerify: true,
    );
  }

  if (isOut) {
    if (diffHours < 12 && status.confidence > 80) {
      return const DecisiveStatus(
        label: 'หมดแล้วแน่นอน',
        color: Color(0xFFEF4444),
        bars: 3,
        needsVerify: false,
      );
    }
    return const DecisiveStatus(
      label: 'แจ้งว่าหมด · รอยืนยัน',
      color: Color(0xFFEF4444),
      bars: 2,
      needsVerify: true,
    );
  }

  return const DecisiveStatus(
    label: 'รอยืนยัน',
    color: Color(0xFFF59E0B),
    bars: 1,
    needsVerify: true,
  );
}
