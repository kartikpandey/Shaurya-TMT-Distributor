import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/order_target.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  // Keyed by product_variant_id so adding the same variant twice merges lines
  final Map<int, CartItem> _items = {};
  OrderTarget? _target;
  String _note = '';

  // Getters
  List<CartItem> get items => _items.values.toList();
  OrderTarget? get target => _target;
  String get note => _note;
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.length;
  double get totalTonnes =>
      _roundTonnes(_items.values.fold(0.0, (sum, i) => sum + i.quantity));
  double get totalAmount =>
      _items.values.fold(0.0, (sum, i) => sum + i.lineTotal);

  /// Why the order cannot be submitted yet, or null when it is ready
  String? get validationError {
    if (_items.isEmpty) return 'Add at least one product to the order.';
    if (_target == null) return 'Choose who this order is for.';
    return null;
  }

  bool get canSubmit => validationError == null;

  // Add tonnes of a product, merging into an existing line for that variant
  void add(ProductModel product, double quantity) {
    final variantId = product.variantId;
    if (variantId == null) {
      throw ArgumentError('Product ${product.name} has no variant id');
    }
    if (quantity <= 0) return;

    final existing = _items[variantId];
    _items[variantId] =
        existing != null
            ? existing.copyWith(
              quantity: _roundTonnes(existing.quantity + quantity),
            )
            : CartItem(
              productVariantId: variantId,
              productName: product.name,
              size: product.size,
              grade: product.grade,
              quantity: _roundTonnes(quantity),
              unitPrice: product.unitPrice,
            );
    notifyListeners();
  }

  // Set a line's quantity; zero or less removes the line
  void setQuantity(int productVariantId, double quantity) {
    final existing = _items[productVariantId];
    if (existing == null) return;

    if (quantity <= 0) {
      _items.remove(productVariantId);
    } else {
      _items[productVariantId] = existing.copyWith(
        quantity: _roundTonnes(quantity),
      );
    }
    notifyListeners();
  }

  void remove(int productVariantId) {
    if (_items.remove(productVariantId) != null) notifyListeners();
  }

  void setTarget(OrderTarget? target) {
    _target = target;
    notifyListeners();
  }

  // Note is typed live, so no rebuild is needed
  void setNote(String note) {
    _note = note;
  }

  // Empty the cart after a successful order or when starting over
  void clear() {
    _items.clear();
    _target = null;
    _note = '';
    notifyListeners();
  }

  /// Build the create-order request body
  Map<String, dynamic> buildOrderPayload({required int createdById}) {
    final error = validationError;
    if (error != null) throw StateError(error);

    final trimmedNote = _note.trim();
    return {
      'created_by_id': createdById,
      ..._target!.toRequestJson(),
      'note': trimmedNote.isEmpty ? null : trimmedNote,
      'items': _items.values.map((i) => i.toRequestJson()).toList(),
    };
  }

  /// Build the edit-order request body; editing replaces the order's note
  /// and product lines, and needs no target
  Map<String, dynamic> buildEditPayload({required String orderId}) {
    if (_items.isEmpty) {
      throw StateError('Add at least one product to the order.');
    }

    final trimmedNote = _note.trim();
    return {
      'order_id': orderId,
      'note': trimmedNote.isEmpty ? null : trimmedNote,
      'items': _items.values.map((i) => i.toRequestJson()).toList(),
    };
  }

  // Keep tonnage to kilogram precision so float noise never reaches the API
  static double _roundTonnes(double value) =>
      double.parse(value.toStringAsFixed(3));
}
