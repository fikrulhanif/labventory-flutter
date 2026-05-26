import 'category.dart';

/// Mirrors `InventoryResource` on the backend (Requirements 7.1, 7.5,
/// 18.5, Property 44).
class Inventory {
  const Inventory({
    required this.id,
    required this.name,
    required this.code,
    required this.stock,
    required this.status,
    this.description,
    this.imageUrl,
    this.qrUrl,
    this.category,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String code;
  final int stock;

  /// One of "available" | "out_of_stock".
  final String status;

  final String? description;
  final String? imageUrl;
  final String? qrUrl;
  final Category? category;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAvailable => status == 'available' && stock > 0;

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      stock: (json['stock'] as num).toInt(),
      status: json['status'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      qrUrl: json['qr_url'] as String?,
      category: json['category'] is Map<String, dynamic>
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'stock': stock,
      'status': status,
      'description': description,
      'image_url': imageUrl,
      'qr_url': qrUrl,
      'category': category?.toJson(),
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }
}
