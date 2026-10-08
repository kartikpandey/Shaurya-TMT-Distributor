import 'dart:convert';

import 'package:distributor/config/constants/app_constants.dart';
import 'package:distributor/models/dashboard_model.dart';
import 'package:distributor/models/network_member.dart';
import 'package:distributor/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

const String liveResponse =
    '{"message":"Distributor dashboard data","summary":{"open_orders":0,'
    '"approved_orders":0,"pending_dispatch":0,"returns":0,'
    '"stock_health":"critical"},"dealers":[],"response_code":200}';

void main() {
  group('dashboard auth', () {
    test('buildHeaders sends the login token as DRF Token auth', () {
      final headers = ApiService.buildHeaders(token: 'abc123');

      expect(headers[AppConstants.authHeaderKey], 'Token abc123');
      expect(headers['Content-Type'], 'application/json');
    });

    test('omits the header when no token is available', () {
      expect(
        ApiService.buildHeaders().containsKey(AppConstants.authHeaderKey),
        isFalse,
      );
      expect(
        ApiService.buildHeaders(token: '')
            .containsKey(AppConstants.authHeaderKey),
        isFalse,
      );
    });

    test('hits the distribution dashboard endpoint', () {
      expect(
        AppConstants.dashboardEndpoint,
        'http://167.71.227.184/api/v1/distribution/dashboard/',
      );
    });
  });

  group('DashboardModel.fromJson', () {
    test('parses the live /distribution/dashboard/ payload', () {
      final json = jsonDecode(liveResponse) as Map<String, dynamic>;
      final dashboard = DashboardModel.fromJson(json);

      expect(dashboard.message, 'Distributor dashboard data');
      expect(dashboard.responseCode, 200);
      expect(dashboard.dealers, isEmpty);
      expect(dashboard.summary.openOrders, 0);
      expect(dashboard.summary.approvedOrders, 0);
      expect(dashboard.summary.pendingDispatch, 0);
      expect(dashboard.summary.returns, 0);
      expect(dashboard.summary.stockHealth, 'critical');
      expect(dashboard.summary.isStockCritical, isTrue);
      expect(dashboard.summary.totalOrders, 0);
    });

    test('falls back to zeros when summary and dealers are missing', () {
      final dashboard = DashboardModel.fromJson({'response_code': 200});

      expect(dashboard.message, isEmpty);
      expect(dashboard.summary.stockHealth, 'unknown');
      expect(dashboard.summary.isStockCritical, isFalse);
      expect(dashboard.dealers, isEmpty);
    });

    test('normalises stock_health casing and accepts numeric strings', () {
      final dashboard = DashboardModel.fromJson({
        'summary': {
          'open_orders': '7',
          'approved_orders': 3,
          'pending_dispatch': 5.0,
          'returns': 1,
          'stock_health': '  HEALTHY ',
        },
      });

      expect(dashboard.summary.openOrders, 7);
      expect(dashboard.summary.approvedOrders, 3);
      expect(dashboard.summary.pendingDispatch, 5);
      expect(dashboard.summary.stockHealth, 'healthy');
      expect(dashboard.summary.totalOrders, 15);
      expect(dashboard.summary.hasActionableItems, isTrue);
    });
  });

  group('dealers stay dynamic', () {
    test('keeps dealer rows as raw maps with all their fields', () {
      final dashboard = DashboardModel.fromJson({
        'dealers': [
          {
            'id': 12,
            'dealer_name': 'Jain Mining Co.',
            'city': 'Nagpur',
            'open_orders': 4,
            'credit_limit': 500000.5,
            'is_verified': true,
            'tags': ['vip', 'north'],
          },
        ],
      });

      expect(dashboard.dealers, hasLength(1));
      final dealer = dashboard.dealers.first;
      expect(dealer['dealer_name'], 'Jain Mining Co.');
      expect(dealer['id'], 12);
      expect(dealer['open_orders'], 4);
      expect(dealer['credit_limit'], 500000.5);
      expect(dealer['is_verified'], true);
      expect(dealer['tags'], ['vip', 'north']);
    });

    test('yields an empty list for a missing or non-list dealers value', () {
      expect(DashboardModel.fromJson({}).dealers, isEmpty);
      expect(DashboardModel.fromJson({'dealers': null}).dealers, isEmpty);
      expect(
        DashboardModel.fromJson({'dealers': 'nope'}).dealers,
        isEmpty,
      );
    });

    test('skips non-object entries instead of throwing', () {
      final dashboard = DashboardModel.fromJson({
        'dealers': [
          {'name': 'Jain Mining Co.'},
          'garbage',
          42,
          null,
        ],
      });

      expect(dashboard.dealers, hasLength(1));
      expect(dashboard.dealers.first['name'], 'Jain Mining Co.');
    });
  });

  group('network children', () {
    test('reads the children list from dealer_list too', () {
      final dashboard = DashboardModel.fromJson({
        'dealer_list': [
          {'id': 77, 'name': 'Rahul Traders', 'phone': '9876543210', 'store': null},
        ],
      });

      expect(dashboard.dealers, hasLength(1));
    });

    test('parses id, name, phone and store', () {
      final member = NetworkMember.tryParse({
        'id': '77',
        'name': 'Rahul Traders',
        'phone': '9876543210',
        'store': null,
      })!;

      expect(member.id, 77);
      expect(member.name, 'Rahul Traders');
      expect(member.phone, '9876543210');
      expect(member.store, isNull);
    });

    test('skips entries without a usable id', () {
      expect(NetworkMember.tryParse({'name': 'No id'}), isNull);
      expect(NetworkMember.tryParse({'id': 'abc', 'name': 'Bad'}), isNull);
    });
  });
}
