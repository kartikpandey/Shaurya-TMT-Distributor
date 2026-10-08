import 'package:distributor/config/constants/app_constants.dart';
import 'package:distributor/models/order_target.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderingRole.fromUserType', () {
    test('maps the three ordering user types', () {
      expect(
        OrderingRole.fromUserType(AppConstants.distributorUserType),
        OrderingRole.distributor,
      );
      expect(
        OrderingRole.fromUserType(AppConstants.dealerUserType),
        OrderingRole.dealer,
      );
      expect(
        OrderingRole.fromUserType(AppConstants.contractorUserType),
        OrderingRole.subDealer,
      );
    });

    test('returns null for roles that do not place orders', () {
      expect(OrderingRole.fromUserType(AppConstants.salesmanUserType), isNull);
      expect(OrderingRole.fromUserType(null), isNull);
    });
  });

  group('OrderTarget.resolve', () {
    Map<String, dynamic> resolve(
      OrderingRole role,
      int selfId, {
      int? childId,
    }) =>
        OrderTarget.resolve(
          role: role,
          selfId: selfId,
          childId: childId,
          label: 'x',
        ).toRequestJson();

    test('sub-dealer orders for self; backend fills in parents', () {
      expect(resolve(OrderingRole.subDealer, 15), {
        'distributor_id': null,
        'dealer_id': null,
        'customer_id': 15,
      });
    });

    test('sub-dealer cannot order for someone else', () {
      expect(
        () => resolve(OrderingRole.subDealer, 15, childId: 16),
        throwsA(isA<OrderTargetException>()),
      );
    });

    test('dealer ordering for self is also the customer', () {
      expect(resolve(OrderingRole.dealer, 77), {
        'distributor_id': null,
        'dealer_id': 77,
        'customer_id': 77,
      });
    });

    test('dealer ordering for a sub-dealer', () {
      expect(resolve(OrderingRole.dealer, 77, childId: 15), {
        'distributor_id': null,
        'dealer_id': 77,
        'customer_id': 15,
      });
    });

    test('distributor ordering for self is also the customer', () {
      expect(resolve(OrderingRole.distributor, 42), {
        'distributor_id': 42,
        'dealer_id': null,
        'customer_id': 42,
      });
    });

    test('distributor ordering for a dealer', () {
      expect(resolve(OrderingRole.distributor, 42, childId: 77), {
        'distributor_id': 42,
        'dealer_id': 77,
        'customer_id': 77,
      });
    });
  });
}
