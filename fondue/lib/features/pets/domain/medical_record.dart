class MedicalRecord {
  final String id;
  final String petProfileId;
  final String recordType; // 'vaccination', 'vet_visit', 'medication', 'weight_log', 'note'
  final String title;
  final String? description;
  final DateTime date;
  final DateTime? nextDueDate;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  MedicalRecord({
    required this.id,
    required this.petProfileId,
    required this.recordType,
    required this.title,
    this.description,
    required this.date,
    this.nextDueDate,
    this.metadata = const {},
    required this.createdAt,
  });

  bool get isOverdue {
    if (nextDueDate == null) return false;
    return DateTime.now().isAfter(nextDueDate!);
  }

  bool get isDueSoon {
    if (nextDueDate == null) return false;
    final daysUntilDue = nextDueDate!.difference(DateTime.now()).inDays;
    return daysUntilDue >= 0 && daysUntilDue <= 14;
  }

  String get recordTypeLabel {
    switch (recordType) {
      case 'vaccination':
        return 'Vaccination';
      case 'vet_visit':
        return 'Vet Visit';
      case 'medication':
        return 'Medication';
      case 'weight_log':
        return 'Weight Log';
      case 'note':
        return 'Note';
      default:
        return recordType;
    }
  }

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id'] as String,
      petProfileId: json['pet_profile_id'] as String,
      recordType: json['record_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      nextDueDate: json['next_due_date'] != null
          ? DateTime.tryParse(json['next_due_date'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pet_profile_id': petProfileId,
      'record_type': recordType,
      'title': title,
      'description': description,
      'date': date.toIso8601String().split('T').first,
      'next_due_date': nextDueDate?.toIso8601String().split('T').first,
      'metadata': metadata,
    };
  }
}
