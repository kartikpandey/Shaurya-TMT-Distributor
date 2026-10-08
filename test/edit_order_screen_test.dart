import 'package:distributor/models/distribution_order.dart';
import 'package:distributor/providers/auth_provider.dart';
import 'package:distributor/providers/order_provider.dart';
import 'package:distributor/screens/orders/edit_order_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _wrap(DistributionOrder order) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => OrderProvider()),
  ],
  child: MaterialApp(home: EditOrderScreen(order: order)),
);

ElevatedButton _saveButton(WidgetTester tester) => tester.widget(
  find.ancestor(
    of: find.text('Save Changes'),
    matching: find.byType(ElevatedButton),
  ),
);

void main() {
  testWidgets('pre-fills the order lines and note', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const DistributionOrder(
          orderId: 'ORD-20260915010101',
          status: 'PLACED',
          dealerName: 'Sudama Brothers',
          totalAmount: 2800,
          note: 'Urgent',
          lines: [
            DistributionOrderLine(
              productVariantId: 1,
              quantity: 8,
              unitPrice: 350,
            ),
          ],
        ),
      ),
    );

    expect(find.text('ShauryaTMT 6mm'), findsOneWidget);
    expect(find.text('Urgent'), findsOneWidget);
    expect(find.text('1 items · 8 t'), findsOneWidget);
    expect(find.textContaining("couldn't be loaded"), findsNothing);
    expect(_saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('warns when lines are missing and blocks saving an empty order', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const DistributionOrder(
          orderId: 'ORD-1',
          status: 'PLACED',
          dealerName: 'Sudama Brothers',
          totalAmount: 0,
        ),
      ),
    );

    expect(find.textContaining("couldn't be loaded"), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNull);
  });
}
