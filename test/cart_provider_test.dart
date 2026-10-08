import 'package:distributor/models/order_target.dart';
import 'package:distributor/models/product_model.dart';
import 'package:distributor/providers/cart_provider.dart';
import 'package:flutter_test/flutter_test.dart';

ProductModel _product(int variantId, double unitPrice) => ProductModel(
  variantId: variantId,
  name: 'ShauryaTMT ${variantId}mm',
  size: '${variantId}mm',
  grade: 'Grade A',
  quantity: 100,
  unitPrice: unitPrice,
  totalPrice: 0,
);

const _target = OrderTarget(
  distributorId: 42,
  dealerId: 77,
  customerId: 15,
  label: 'Site contractor',
);

void main() {
  late CartProvider cart;

  setUp(() => cart = CartProvider());

  test('adding the same variant twice merges into one line', () {
    cart.add(_product(1, 120), 2.5);
    cart.add(_product(1, 120), 1.25);

    expect(cart.itemCount, 1);
    expect(cart.items.single.quantity, 3.75);
    expect(cart.totalAmount, 450);
  });

  test('totals span every line and fractional tonnes stay exact', () {
    cart.add(_product(1, 120), 0.1);
    cart.add(_product(1, 120), 0.2);
    cart.add(_product(2, 245), 5);

    expect(cart.items.first.quantity, 0.3);
    expect(cart.totalTonnes, 5.3);
    expect(cart.totalAmount, closeTo(0.3 * 120 + 5 * 245, 1e-9));
  });

  test('setting quantity to zero removes the line', () {
    cart.add(_product(1, 120), 2);
    cart.setQuantity(1, 0);

    expect(cart.isEmpty, isTrue);
  });

  test('products without a variant id cannot be added', () {
    final noVariant = ProductModel(
      name: 'ShauryaTMT 8mm',
      size: '8mm',
      grade: 'Grade A',
      quantity: 1,
      unitPrice: 1,
      totalPrice: 1,
    );

    expect(() => cart.add(noVariant, 1), throwsArgumentError);
  });

  test('validation requires items and a target', () {
    expect(cart.canSubmit, isFalse);

    cart.add(_product(1, 120), 1);
    expect(cart.validationError, 'Choose who this order is for.');

    cart.setTarget(_target);
    expect(cart.canSubmit, isTrue);
  });

  test('builds the create-order payload', () {
    cart.add(_product(1, 120), 12);
    cart.add(_product(2, 245), 5.5);
    cart.setTarget(_target);
    cart.setNote('  Urgent delivery for site work ');

    expect(cart.buildOrderPayload(createdById: 101), {
      'created_by_id': 101,
      'distributor_id': 42,
      'dealer_id': 77,
      'customer_id': 15,
      'note': 'Urgent delivery for site work',
      'items': [
        {'product_variant_id': 1, 'quantity': 12.0, 'unit_price': 120.0},
        {'product_variant_id': 2, 'quantity': 5.5, 'unit_price': 245.0},
      ],
    });
  });

  test('blank note is sent as null and incomplete carts refuse to build', () {
    expect(() => cart.buildOrderPayload(createdById: 101), throwsStateError);

    cart.add(_product(1, 120), 1);
    cart.setTarget(_target);
    cart.setNote('   ');
    expect(cart.buildOrderPayload(createdById: 101)['note'], isNull);
  });

  test('clear resets items, target and note', () {
    cart.add(_product(1, 120), 1);
    cart.setTarget(_target);
    cart.setNote('x');
    cart.clear();

    expect(cart.isEmpty, isTrue);
    expect(cart.target, isNull);
    expect(cart.note, isEmpty);
  });

  test('builds the edit-order payload without needing a target', () {
    cart.add(_product(1, 350), 8);
    cart.setNote(' Updated delivery note ');

    expect(cart.buildEditPayload(orderId: 'ORD-20260915010101'), {
      'order_id': 'ORD-20260915010101',
      'note': 'Updated delivery note',
      'items': [
        {'product_variant_id': 1, 'quantity': 8.0, 'unit_price': 350.0},
      ],
    });
  });

  test('an edit must keep at least one product', () {
    expect(
      () => cart.buildEditPayload(orderId: 'ORD-1'),
      throwsStateError,
    );
  });
}
