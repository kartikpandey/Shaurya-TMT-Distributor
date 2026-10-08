import 'package:distributor/models/distribution_order.dart';
import 'package:distributor/models/reward_ledger.dart';
import 'package:distributor/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DistributionOrder', () {
    test('parses a live order-list item', () {
      final order =
          DistributionOrder.tryParse({
            'id': 'ORD-20260930120114',
            'status': 'PLACED',
            'dealer': 'Sudama  Brothers',
            'total_amount': 31000.0,
            'date': '2026-09-30',
          })!;

      expect(order.orderId, 'ORD-20260930120114');
      expect(order.dealerName, 'Sudama  Brothers');
      expect(order.totalAmount, 31000);
      expect(order.date, DateTime(2026, 9, 30));
      expect(order.isAwaitingApproval, isTrue);
    });

    test('approved orders no longer await approval', () {
      final order =
          DistributionOrder.tryParse({'id': 'ORD-1', 'status': 'approved'})!;
      expect(order.status, 'APPROVED');
      expect(order.isAwaitingApproval, isFalse);
    });

    test('reads note and product lines when the API sends them', () {
      final order =
          DistributionOrder.tryParse({
            'id': 'ORD-20260915010101',
            'status': 'PLACED',
            'note': 'Urgent',
            'items': [
              {'product_variant_id': 1, 'quantity': 8, 'unit_price': 350},
              {'quantity': 2},
            ],
          })!;

      expect(order.note, 'Urgent');
      expect(order.lines, hasLength(1));
      expect(order.lines.single.productVariantId, 1);
      expect(order.lines.single.quantity, 8);
      expect(order.lines.single.unitPrice, 350);
      expect(order.isEditable, isTrue);
    });

    test('approved orders cannot be edited', () {
      expect(
        DistributionOrder.tryParse({
          'id': 'ORD-1',
          'status': 'APPROVED',
        })!.isEditable,
        isFalse,
      );
    });

    test('skips items without an id', () {
      expect(DistributionOrder.tryParse({'status': 'PLACED'}), isNull);
    });

    test('sorts newest first, breaking same-day ties by order id', () {
      DistributionOrder make(String id, String date) =>
          DistributionOrder.tryParse({'id': id, 'date': date})!;

      final orders = [
        make('ORD-20260929100000', '2026-09-29'),
        make('ORD-20260930115859', '2026-09-30'),
        make('ORD-20260930141823', '2026-09-30'),
      ]..sort(DistributionOrder.newestFirst);

      expect(orders.map((o) => o.orderId), [
        'ORD-20260930141823',
        'ORD-20260930115859',
        'ORD-20260929100000',
      ]);
    });
  });

  group('RewardLedger', () {
    final response = {
      'total_coins': 150,
      'data': [
        {
          'msg': 'Super coins credited',
          'coins': 200,
          'created_at': '01/09/2026, 10:15 AM',
        },
        {
          'msg': 'Super coins debited',
          'coins': 50,
          'created_at': '15/09/2026, 04:30 PM',
        },
      ],
    };

    test('parses entries newest first with direction from the message', () {
      final ledger = RewardLedger.fromResponse(response);

      expect(ledger.entries, hasLength(2));
      expect(ledger.entries.first.description, 'Super coins debited');
      expect(ledger.entries.first.isCredit, isFalse);
      expect(ledger.entries.first.date, DateTime(2026, 9, 15, 16, 30));
      expect(ledger.entries.last.isCredit, isTrue);
    });

    test(
      'uses the API total as current points, with totals and running balance',
      () {
        final ledger = RewardLedger.fromResponse(response);

        expect(ledger.balance, 150);
        expect(ledger.totalEarned, 200);
        expect(ledger.totalRedeemed, 50);
        // Newest (debit) leaves 150; before it the balance was 200
        expect(ledger.balanceAfter(0), 150);
        expect(ledger.balanceAfter(1), 200);
      },
    );

    test('falls back to the ledger sum when no total is sent', () {
      final ledger = RewardLedger.fromResponse({
        'data': [
          {'msg': 'Order reward', 'coins': 120},
          {'msg': 'Redeemed voucher', 'coins': 20},
        ],
      });
      expect(ledger.balance, 100);
    });

    test('reads the items list used by distribution APIs', () {
      final ledger = RewardLedger.fromResponse({
        'message': 'Reward ledger',
        'items': [
          {'msg': 'Order reward', 'coins': 40},
        ],
        'response_code': 200,
      });
      expect(ledger.entries, hasLength(1));
      expect(ledger.balance, 40);
    });

    test('reads the live reward-ledger response shape', () {
      final ledger = RewardLedger.fromResponse({
        'message': 'Reward ledger',
        'total_points': 1000,
        'items': [
          {
            'order_id': 'ORD-20260930173613',
            'points': 1000,
            'quantity': 0.0,
            'created_at': '2026-09-30T23:06:13.873107',
          },
        ],
        'response_code': 200,
      });

      final entry = ledger.entries.single;
      expect(ledger.balance, 1000);
      expect(entry.coins, 1000);
      expect(entry.isCredit, isTrue);
      expect(entry.orderId, 'ORD-20260930173613');
      expect(entry.description, 'Order reward');
      expect(entry.date, DateTime(2026, 9, 30, 23, 6, 13, 873, 107));
    });

    test('an empty response has zero points', () {
      final ledger = RewardLedger.fromResponse({'total_coins': 0});
      expect(ledger.entries, isEmpty);
      expect(ledger.balance, 0);
    });
  });

  group('IST', () {
    test('timestamps without an offset are already IST', () {
      expect(
        AppFormatters.parseIst('2026-09-30T23:06:13'),
        DateTime(2026, 9, 30, 23, 6, 13),
      );
    });

    test('UTC timestamps are converted to IST', () {
      expect(
        AppFormatters.parseIst('2026-09-30T17:36:13Z'),
        DateTime(2026, 9, 30, 23, 6, 13),
      );
      expect(
        AppFormatters.parseIst('2026-09-30T20:00:00+00:00'),
        DateTime(2026, 10, 1, 1, 30),
      );
    });

    test('now is IST wall-clock time', () {
      final expected = DateTime.now().toUtc().add(AppFormatters.istOffset);
      final now = AppFormatters.nowIst();
      expect(now.isUtc, isFalse);
      expect(now.hour, expected.hour);
      expect(now.minute, expected.minute);
    });
  });
}
