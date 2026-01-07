class ShopItemModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final double price;
  final double? discountPrice;
  final String category; // 'bat', 'ball', 'gloves', 'helmet', etc.
  final String? brand;
  final int stock;
  final double? rating;
  final int? reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShopItemModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.price,
    this.discountPrice,
    required this.category,
    this.brand,
    required this.stock,
    this.rating,
    this.reviewCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShopItemModel.fromJson(Map<String, dynamic> json) {
    return ShopItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      price: (json['price'] as num).toDouble(),
      discountPrice: json['discount_price'] != null
          ? (json['discount_price'] as num).toDouble()
          : null,
      category: json['category'] as String,
      brand: json['brand'] as String?,
      stock: json['stock'] as int,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      reviewCount: json['review_count'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'price': price,
      'discount_price': discountPrice,
      'category': category,
      'brand': brand,
      'stock': stock,
      'rating': rating,
      'review_count': reviewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

