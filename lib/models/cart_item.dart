/// One line of an order being built: a product variant and how many tonnes.
class CartItem {
  final int productVariantId;
  final String productName;
  final String size;
  final String grade;
  final double quantity; // tonnes, may be fractional
  final double unitPrice; // per tonne

  const CartItem({
    required this.productVariantId,
    required this.productName,
    required this.size,
    required this.grade,
    required this.quantity,
    required this.unitPrice,
  });

  double get lineTotal => quantity * unitPrice;

  // Item entry of the create-order payload
  Map<String, dynamic> toRequestJson() => {
    'product_variant_id': productVariantId,
    'quantity': quantity,
    'unit_price': unitPrice,
  };

  // Copy with
  CartItem copyWith({double? quantity, double? unitPrice}) => CartItem(
    productVariantId: productVariantId,
    productName: productName,
    size: size,
    grade: grade,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
  );
}
