import 'package:uuid/uuid.dart';

class ProductModel {
  final String id;
  final int? variantId; // backend product_variant_id, used when ordering
  final String name; // e.g., "ShauryaTMT 6mm"
  final String size; // e.g., "6mm", "8mm", "10mm"
  final String grade; // "Grade A" or "Grade B"
  final double quantity; // in units or tonnes
  final double unitPrice;
  final double totalPrice;
  final String unit; // "units", "tonnes", "kg"
  final DateTime? addedDate;

  ProductModel({
    String? id,
    this.variantId,
    required this.name,
    required this.size,
    required this.grade,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.unit = 'tonnes',
    this.addedDate,
  }) : id = id ?? const Uuid().v4();

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'variantId': variantId,
    'name': name,
    'size': size,
    'grade': grade,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'totalPrice': totalPrice,
    'unit': unit,
    'addedDate': addedDate?.toIso8601String(),
  };

  // Create from JSON
  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json['id'] as String?,
    variantId: (json['variantId'] as num?)?.toInt(),
    name: json['name'] as String,
    size: json['size'] as String,
    grade: json['grade'] as String,
    quantity: (json['quantity'] as num).toDouble(),
    unitPrice: (json['unitPrice'] as num).toDouble(),
    totalPrice: (json['totalPrice'] as num).toDouble(),
    unit: json['unit'] as String? ?? 'tonnes',
    addedDate:
        json['addedDate'] != null
            ? DateTime.parse(json['addedDate'] as String)
            : null,
  );

  // Copy with
  ProductModel copyWith({
    String? id,
    int? variantId,
    String? name,
    String? size,
    String? grade,
    double? quantity,
    double? unitPrice,
    double? totalPrice,
    String? unit,
    DateTime? addedDate,
  }) => ProductModel(
    id: id ?? this.id,
    variantId: variantId ?? this.variantId,
    name: name ?? this.name,
    size: size ?? this.size,
    grade: grade ?? this.grade,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    totalPrice: totalPrice ?? this.totalPrice,
    unit: unit ?? this.unit,
    addedDate: addedDate ?? this.addedDate,
  );
}
