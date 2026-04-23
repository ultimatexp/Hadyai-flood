class PetClaim {
  final String id;
  final String petId;
  final String ownerUserId;
  final String claimantUserId;
  final String? note;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PetClaim({
    required this.id,
    required this.petId,
    required this.ownerUserId,
    required this.claimantUserId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.note,
  });

  factory PetClaim.fromJson(Map<String, dynamic> json) {
    return PetClaim(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      claimantUserId: json['claimant_user_id'] as String,
      note: json['note'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
