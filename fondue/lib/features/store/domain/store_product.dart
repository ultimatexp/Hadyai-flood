enum ProductCategory {
  food,
  accessories,
  medicine,
  toys,
  other;

  String get thaiLabel {
    return switch (this) {
      ProductCategory.food => 'อาหาร',
      ProductCategory.accessories => 'อุปกรณ์',
      ProductCategory.medicine => 'ยา',
      ProductCategory.toys => 'ของเล่น',
      ProductCategory.other => 'อื่นๆ',
    };
  }

  String get emoji {
    return switch (this) {
      ProductCategory.food => '🍖',
      ProductCategory.accessories => '🎀',
      ProductCategory.medicine => '💊',
      ProductCategory.toys => '🧸',
      ProductCategory.other => '📦',
    };
  }
}

class StoreProduct {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final ProductCategory category;
  final bool inStock;
  final String? sellerId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  StoreProduct({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.category = ProductCategory.other,
    this.inStock = true,
    this.sellerId,
    this.metadata = const {},
    required this.createdAt,
  });

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    return StoreProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      category: ProductCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ProductCategory.other,
      ),
      inStock: json['in_stock'] as bool? ?? true,
      sellerId: json['seller_id'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
