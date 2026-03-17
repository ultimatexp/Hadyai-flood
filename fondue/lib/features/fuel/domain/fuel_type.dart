class FuelType {
  final String id;
  final String nameTh;
  final String nameEn;
  final String color;
  final int sortOrder;

  const FuelType({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.color,
    required this.sortOrder,
  });

  factory FuelType.fromJson(Map<String, dynamic> json) {
    return FuelType(
      id: json['id'] as String,
      nameTh: json['name_th'] as String,
      nameEn: json['name_en'] as String,
      color: json['color'] as String? ?? '#64748b',
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}
