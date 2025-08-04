import 'package:equatable/equatable.dart';

enum ProductCategory {
  animalFeed,
  organicFertilizer,
  seeds,
  tools,
  fertilizer,
  pesticides,
  equipment,
  other,
}

extension ProductCategoryExtension on ProductCategory {
  String get displayName {
    switch (this) {
      case ProductCategory.animalFeed:
        return 'Animal Feed';
      case ProductCategory.organicFertilizer:
        return 'Organic Fertilizer';
      case ProductCategory.seeds:
        return 'Seeds';
      case ProductCategory.tools:
        return 'Tools';
      case ProductCategory.fertilizer:
        return 'Fertilizer';
      case ProductCategory.pesticides:
        return 'Pesticides';
      case ProductCategory.equipment:
        return 'Equipment';
      case ProductCategory.other:
        return 'Other';
    }
  }

  static ProductCategory fromString(String categoryString) {
    switch (categoryString.toLowerCase()) {
      case 'animal feed':
      case 'animalfeed':
        return ProductCategory.animalFeed;
      case 'organic fertilizer':
      case 'organicfertilizer':
        return ProductCategory.organicFertilizer;
      case 'seeds':
        return ProductCategory.seeds;
      case 'tools':
        return ProductCategory.tools;
      case 'fertilizer':
        return ProductCategory.fertilizer;
      case 'pesticides':
        return ProductCategory.pesticides;
      case 'equipment':
        return ProductCategory.equipment;
      default:
        return ProductCategory.other;
    }
  }
}

class ProductModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final ProductCategory category;
  final List<String> imageUrls;
  final int stockQuantity;
  final String unit; // kg, pieces, liters, etc.
  final bool isAvailable;
  final double? discountPercentage;
  final Map<String, dynamic>? specifications;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrls = const [],
    required this.stockQuantity,
    required this.unit,
    this.isAvailable = true,
    this.discountPercentage,
    this.specifications,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  double get discountedPrice {
    if (discountPercentage != null && discountPercentage! > 0) {
      return price * (1 - (discountPercentage! / 100));
    }
    return price;
  }

  bool get hasDiscount => discountPercentage != null && discountPercentage! > 0;

  String get mainImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: ProductCategoryExtension.fromString(map['category'] ?? ''),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      stockQuantity: map['stockQuantity'] ?? 0,
      unit: map['unit'] ?? 'pieces',
      isAvailable: map['isAvailable'] ?? true,
      discountPercentage: map['discountPercentage']?.toDouble(),
      specifications: map['specifications'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category.name,
      'imageUrls': imageUrls,
      'stockQuantity': stockQuantity,
      'unit': unit,
      'isAvailable': isAvailable,
      'discountPercentage': discountPercentage,
      'specifications': specifications,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    ProductCategory? category,
    List<String>? imageUrls,
    int? stockQuantity,
    String? unit,
    bool? isAvailable,
    double? discountPercentage,
    Map<String, dynamic>? specifications,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      unit: unit ?? this.unit,
      isAvailable: isAvailable ?? this.isAvailable,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      specifications: specifications ?? this.specifications,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        category,
        imageUrls,
        stockQuantity,
        unit,
        isAvailable,
        discountPercentage,
        specifications,
        rating,
        reviewCount,
        createdAt,
        updatedAt,
      ];
} 