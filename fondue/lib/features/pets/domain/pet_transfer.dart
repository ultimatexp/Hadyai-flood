class PetTransfer {
  final String id;
  final String petId;
  final String claimId;
  final String ownerUserId;
  final String claimantUserId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? confirmedAt;

  const PetTransfer({
    required this.id,
    required this.petId,
    required this.claimId,
    required this.ownerUserId,
    required this.claimantUserId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.confirmedAt,
  });

  factory PetTransfer.fromJson(Map<String, dynamic> json) {
    return PetTransfer(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      claimId: json['claim_id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      claimantUserId: json['claimant_user_id'] as String,
      status: json['status'] as String? ?? 'pending_claimant_confirmation',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.tryParse(json['confirmed_at'] as String)
          : null,
    );
  }
}
