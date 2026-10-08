import 'package:distributor/models/order_target.dart';
import 'package:distributor/models/product_model.dart';
import 'package:distributor/providers/auth_provider.dart';
import 'package:distributor/providers/cart_provider.dart';
import 'package:distributor/providers/dashboard_provider.dart';
import 'package:distributor/providers/order_provider.dart';
import 'package:distributor/screens/orders/create_order/order_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _wrap(CartProvider cart) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => DashboardProvider()),
    ChangeNotifierProvider(create: (_) => OrderProvider()),
    ChangeNotifierProvider.value(value: cart),
  ],
  child: const MaterialApp(home: OrderReviewScreen()),
);

ElevatedButton _placeOrderButton(WidgetTester tester) => tester.widget(
  find.ancestor(
    of: find.text('Place Order'),
    matching: find.byType(ElevatedButton),
  ),
);

void main() {
  late CartProvider cart;

  setUp(() {
    cart = CartProvider()
      ..add(
        ProductModel(
          variantId: 1,
          name: 'ShauryaTMT 12mm',
          size: '12mm',
          grade: 'Grade A',
          quantity: 100,
          unitPrice: 100,
          totalPrice: 0,
        ),
        2.5,
      );
  });

  testWidgets('blocks submission until a target is chosen', (tester) async {
    await tester.pumpWidget(_wrap(cart));

    expect(find.text('ShauryaTMT 12mm'), findsOneWidget);
    expect(find.text('Tap to choose'), findsOneWidget);
    expect(find.text('Choose who this order is for.'), findsOneWidget);
    expect(_placeOrderButton(tester).onPressed, isNull);

    cart.setTarget(
      const OrderTarget(
        distributorId: 42,
        dealerId: 77,
        customerId: 77,
        label: 'Rahul Traders',
      ),
    );
    await tester.pump();

    expect(find.text('Rahul Traders'), findsOneWidget);
    expect(_placeOrderButton(tester).onPressed, isNotNull);
  });

  testWidgets('stepping quantity updates the line and totals', (tester) async {
    await tester.pumpWidget(_wrap(cart));

    await tester.tap(find.byTooltip('Increase'));
    await tester.pump();

    expect(cart.items.single.quantity, 3);
    expect(find.text('1 items · 3 t'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove'));
    await tester.pump();

    expect(find.text('Your order is empty'), findsOneWidget);
  });
}
