// Live check of the create-order flow against the real backend, using the
// same providers the app uses. Skipped unless credentials are passed in.
//
// Dry run (logs in, loads children, builds and prints the payload, sends
// nothing):
//   flutter test test/live/create_order_live_test.dart \
//     --dart-define=LIVE_USERNAME=<user> --dart-define=LIVE_PASSWORD=<pass> \
//     --dart-define=LIVE_USER_TYPE=<2|3|4>
//
// Or reuse an existing session instead of a password: pass
// --dart-define=LIVE_TOKEN=<token> --dart-define=LIVE_LOGIN_FILE=<path to the
// login response JSON> (plus LIVE_USER_TYPE).
//
// Add --dart-define=LIVE_SUBMIT=true to actually place the order, and
// --dart-define=LIVE_CHILD_ID=<id> to order on behalf of a dealer/sub-dealer.
// This creates a REAL order on the server.
//
// Approval: pass --dart-define=LIVE_APPROVE_ORDER_ID=<ORD-...> instead of
// LIVE_SUBMIT to approve that order and read its status back. This changes a
// REAL order on the server.
import 'dart:convert';
import 'dart:io';

import 'package:distributor/config/constants/product_catalog.dart';
import 'package:distributor/models/product_model.dart';
import 'package:distributor/providers/auth_provider.dart';
import 'package:distributor/providers/cart_provider.dart';
import 'package:distributor/providers/dashboard_provider.dart';
import 'package:distributor/providers/order_provider.dart';
import 'package:distributor/models/reward_ledger.dart';
import 'package:distributor/providers/reward_provider.dart';
import 'package:distributor/services/api_service.dart';
import 'package:distributor/widgets/orders/order_target_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _username = String.fromEnvironment('LIVE_USERNAME');
const _password = String.fromEnvironment('LIVE_PASSWORD');
const _token = String.fromEnvironment('LIVE_TOKEN');
const _loginFile = String.fromEnvironment('LIVE_LOGIN_FILE');
const _userType = int.fromEnvironment('LIVE_USER_TYPE', defaultValue: 3);
const _childId = int.fromEnvironment('LIVE_CHILD_ID', defaultValue: -1);
const _submit = bool.fromEnvironment('LIVE_SUBMIT');
const _approveOrderId = String.fromEnvironment('LIVE_APPROVE_ORDER_ID');
// With LIVE_SUBMIT, also approve the order just created (full flow)
const _approveCreated = bool.fromEnvironment('LIVE_APPROVE_CREATED');
// With LIVE_SUBMIT, edit the order just created (before any approval)
const _editCreated = bool.fromEnvironment('LIVE_EDIT_CREATED');
// Read-only check of the reward ledger
const _checkRewards = bool.fromEnvironment('LIVE_REWARDS');
// Full multi-item lifecycle: create 6 items, edit, approve, compare rewards
const _multiItem = bool.fromEnvironment('LIVE_MULTI_ITEM');
// Pre-demo flow through the app's providers, as the screens use them
const _demoFlow = bool.fromEnvironment('LIVE_DEMO_FLOW');
const _hasSession = _username != '' || _token != '';

void _log(String label, Object? value) {
  final text =
      value is Map || value is List
          ? const JsonEncoder.withIndent('  ').convert(value)
          : '$value';
  // ignore: avoid_print
  print('── $label\n$text\n');
}

// Pull the exception out of a Django DEBUG error page
String? _djangoErrorSummary(String? body) {
  if (body == null) return null;
  String? grab(String pattern) {
    final m = RegExp(pattern, dotAll: true).firstMatch(body);
    return m?.group(1)?.replaceAll(RegExp(r'<[^>]+>'), '').trim();
  }

  final title = grab(r'<title>(.*?)</title>');
  final value = grab(r'<pre class="exception_value">(.*?)</pre>');
  final location = grab(
    r'<th scope="row">Exception Location:</th>\s*<td>(.*?)</td>',
  );
  if (title == null && value == null) {
    return body.length > 1500 ? body.substring(0, 1500) : body;
  }
  return [title, value, location]
      .whereType<String>()
      .map((s) => s.replaceAll('&#x27;', "'").replaceAll('&quot;', '"'))
      .join('\n');
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // The test binding fakes every HTTP call; this test needs the real network
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues(
      _token.isEmpty
          ? {}
          : {
            'auth_token': _token,
            'login_response': File(_loginFile).readAsStringSync(),
            'user_type': _userType,
          },
    );
  });

  test(
    'create order against the live backend',
    () async {
      final auth = await _signIn();

      final identity = OrderingIdentity.of(auth);
      _log('Identity', {
        'user_type': auth.userTypeId,
        'role': identity.role?.name,
        'self_id': identity.selfId,
        'raw_user_id': auth.currentUser?.id,
        'has_token': auth.authToken != null,
      });
      expect(identity.problem, isNull, reason: identity.problem);

      final dashboard = DashboardProvider();
      await dashboard.fetchDashboard(token: auth.authToken);
      _log('Dashboard error', dashboard.errorMessage);
      _log('Raw dealer list', dashboard.dealers);
      _log(
        'Parsed children',
        dashboard.children.map((c) => '${c.id} · ${c.name}').toList(),
      );

      final variant = ProductCatalog.variants.first;
      final cart =
          CartProvider()
            ..add(
              ProductModel(
                variantId: variant.variantId,
                name: variant.name,
                size: variant.size,
                grade: variant.grade,
                quantity: 0,
                unitPrice: variant.pricePerTonne,
                totalPrice: 0,
              ),
              0.5,
            )
            ..setNote('App test order – please ignore');

      if (_childId >= 0) {
        final child = dashboard.children.firstWhere(
          (c) => c.id == _childId,
          orElse: () => throw StateError('No child with id $_childId'),
        );
        cart.setTarget(identity.child(child));
      } else {
        cart.setTarget(identity.self());
      }

      final payload = cart.buildOrderPayload(createdById: identity.selfId!);
      _log('Payload', payload);

      String? createdOrderId;
      if (!_submit) {
        _log('Dry run', 'Not sent. Pass LIVE_SUBMIT=true to place it.');
        return;
      }

      try {
        final response = await ApiService.createOrder(
          payload: payload,
          token: auth.authToken,
        );
        _log('Create-order response', response);
        createdOrderId = response['order_id'] as String?;
      } on ApiException catch (e) {
        _log('Create-order FAILED (${e.statusCode})', e.message);
        _log('Server error detail', _djangoErrorSummary(e.responseBody));
        rethrow;
      }

      if (_editCreated) {
        expect(createdOrderId, isNotNull, reason: 'No order_id in response');
        await _editAndVerify(createdOrderId!, auth.authToken);
      }

      if (_approveCreated) {
        expect(createdOrderId, isNotNull, reason: 'No order_id in response');
        await _approveAndVerify(createdOrderId!, auth.authToken);

        // Rules: an approved order can't be edited or approved again
        await _expectRejected(
          'Edit after approval',
          () => ApiService.editOrder(
            payload: {
              'order_id': createdOrderId,
              'note': 'Should be rejected',
              'items': [
                {'product_variant_id': 1, 'quantity': 1, 'unit_price': 1},
              ],
            },
            token: auth.authToken,
          ),
        );
        await _expectRejected(
          'Approve twice',
          () => ApiService.approveOrder(
            orderId: createdOrderId!,
            token: auth.authToken,
          ),
        );
        _log(
          'Order after rule checks',
          await _findOrder(createdOrderId, auth.authToken),
        );
      }
    },
    skip:
        !_hasSession
            ? 'Pass LIVE_USERNAME/LIVE_PASSWORD or LIVE_TOKEN to run'
            : _approveOrderId.isNotEmpty ||
                (_checkRewards && !_submit) ||
                _multiItem ||
                _demoFlow
            ? 'Approval, rewards-only or multi-item run'
            : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'approve order against the live backend',
    () async {
      final auth = await _signIn();
      _log(
        'Approving as',
        '${auth.currentUser?.name} (${auth.currentUser?.id})',
      );

      await _approveAndVerify(_approveOrderId, auth.authToken);
    },
    skip:
        !_hasSession || _approveOrderId.isEmpty
            ? 'Pass a session and LIVE_APPROVE_ORDER_ID to run'
            : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'multi-item order: create 6, edit, approve, rewards',
    () async {
      final auth = await _signIn();
      final identity = OrderingIdentity.of(auth);
      final token = auth.authToken;
      _log(
        'Identity',
        '${auth.currentUser?.name} · ${identity.role?.name} '
            '#${identity.selfId}',
      );

      final before = (await _ledger(token))!;
      _log('Rewards before', _ledgerSummary(before));

      // 1. Create with six different products and quantities
      final cart =
          CartProvider()
            ..add(_catalogProduct(1), 2.5)
            ..add(_catalogProduct(2), 3)
            ..add(_catalogProduct(3), 1.25)
            ..add(_catalogProduct(4), 4)
            ..add(_catalogProduct(5), 0.75)
            ..add(_catalogProduct(6), 5)
            ..setNote('App multi-item test order – please ignore')
            ..setTarget(identity.self());
      expect(cart.itemCount, 6);
      _log('Order as created', _cartSummary(cart));

      final created = await ApiService.createOrder(
        payload: cart.buildOrderPayload(createdById: identity.selfId!),
        token: token,
      );
      _log('Create response', created);
      final orderId = created['order_id'] as String;

      // 2. Edit, exactly as the edit screen does: start from the order's
      // lines, then remove two, raise two and lower one
      cart
        ..remove(5)
        ..remove(6)
        ..setQuantity(1, 4) // 2.5 -> 4
        ..setQuantity(2, 6.5) // 3 -> 6.5
        ..setQuantity(3, 0.5) // 1.25 -> 0.5
        ..setNote('App multi-item test order (edited) – please ignore');
      expect(cart.itemCount, 4);
      _log('Order after edits (#4 unchanged at 4 t)', _cartSummary(cart));

      final editPayload = cart.buildEditPayload(orderId: orderId);
      _log('Edit payload', editPayload);
      final edited = await ApiService.editOrder(
        payload: editPayload,
        token: token,
      );
      _log('Edit response', edited);
      _log('Order after edit', await _findOrder(orderId, token));

      // 3. Approve
      final approved = await ApiService.approveOrder(
        orderId: orderId,
        token: token,
      );
      _log('Approve response', approved);
      final after = await _findOrder(orderId, token);
      _log('Order after approval', after);
      expect(after?['status'], 'APPROVED');

      // 4. Rewards granted?
      final afterLedger = (await _ledger(token))!;
      _log('Rewards after', _ledgerSummary(afterLedger));
      _log(
        'Points granted by this order',
        afterLedger.balance - before.balance,
      );
    },
    skip:
        !_hasSession || !_multiItem
            ? 'Pass a session and LIVE_MULTI_ITEM=true to run'
            : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'demo flow through app providers',
    () async {
      // 1. Login, then restore the session as an app restart would
      final login = await _signIn();
      final auth = AuthProvider();
      await auth.loadSession();
      final identity = OrderingIdentity.of(auth);
      final token = auth.authToken;
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUser?.id, login.currentUser?.id);
      expect(identity.problem, isNull, reason: identity.problem);
      _log('1. Login + session restore', {
        'name': auth.currentUser?.name,
        'email': auth.currentUser?.email,
        'phone': auth.currentUser?.phoneNumber,
        'store': auth.currentUser?.companyName,
        'role': identity.role?.name,
        'id': identity.selfId,
      });

      // 2. Home dashboard
      final dashboard = DashboardProvider();
      await dashboard.fetchDashboard(token: token);
      expect(dashboard.errorMessage, isNull, reason: dashboard.errorMessage);
      final children =
          dashboard.children
              .where((c) => c.id != identity.selfId)
              .map((c) => '${c.id} ${c.name}')
              .toList();
      _log('2. Dashboard', {
        'open_orders': dashboard.summary?.openOrders,
        'approved_orders': dashboard.summary?.approvedOrders,
        'children_shown': children,
      });

      // 3. Orders list as Home/Orders show it
      final orders = OrderProvider();
      await orders.fetchOrders(token: token);
      expect(orders.errorMessage, isNull, reason: orders.errorMessage);
      final ids = orders.orders.map((o) => o.orderId).toList();
      expect(
        ids,
        [...ids]..sort((a, b) => b.compareTo(a)),
        reason: 'Orders must be newest first',
      );
      _log('3. Orders', {
        'count': orders.orders.length,
        'recent_5':
            orders
                .recentOrders()
                .map((o) => '${o.orderId} ${o.status}')
                .toList(),
        'awaiting_approval': orders.awaitingApproval.length,
        'this_month_value': orders.currentMonthOrderValue,
      });

      final rewardsBefore = (await _ledger(token))!;
      _log('4. Rewards before', _ledgerSummary(rewardsBefore));

      // 5. Create a 6-item order through the cart and OrderProvider
      final cart =
          CartProvider()
            ..add(_catalogProduct(7), 3.5)
            ..add(_catalogProduct(8), 2)
            ..add(_catalogProduct(9), 1.75)
            ..add(_catalogProduct(10), 6)
            ..add(_catalogProduct(11), 0.5)
            ..add(_catalogProduct(12), 2.25)
            ..setNote('Pre-demo test order – please ignore')
            ..setTarget(identity.self());
      _log('5. New order', _cartSummary(cart));
      final placed = await orders.submitOrder(
        payload: cart.buildOrderPayload(createdById: identity.selfId!),
        token: token,
      );
      expect(placed, isTrue, reason: orders.submitError);
      final orderId = orders.lastOrderReference!;
      await orders.fetchOrders(token: token);
      expect(
        orders.orders.first.orderId,
        orderId,
        reason: 'New order should be first in the list',
      );
      expect(orders.awaitingApproval.map((o) => o.orderId), contains(orderId));
      _log('5. Placed', '$orderId · first in list · awaiting approval');

      // 6. Edit: remove 2, raise 2, lower 1, keep 1
      cart
        ..remove(11)
        ..remove(12)
        ..setQuantity(7, 5)
        ..setQuantity(8, 4.5)
        ..setQuantity(9, 1)
        ..setNote('Pre-demo test order (edited) – please ignore');
      _log('6. Edited order', _cartSummary(cart));
      final editError = await orders.editOrder(
        payload: cart.buildEditPayload(orderId: orderId),
        token: token,
      );
      expect(editError, isNull, reason: editError);

      // 7. Approve through OrderProvider
      final approveError = await orders.approveOrder(orderId, token: token);
      expect(approveError, isNull, reason: approveError);
      final approved = orders.orders.firstWhere((o) => o.orderId == orderId);
      expect(approved.status, 'APPROVED');
      expect(approved.isEditable, isFalse);
      expect(
        orders.awaitingApproval.map((o) => o.orderId),
        isNot(contains(orderId)),
      );
      _log('7. Approved', '${approved.orderId} ${approved.status}');

      // 8. Rules the app relies on
      expect(
        await orders.editOrder(
          payload: cart.buildEditPayload(orderId: orderId),
          token: token,
        ),
        isNotNull,
        reason: 'Editing an approved order must fail',
      );
      expect(
        await orders.approveOrder(orderId, token: token),
        isNotNull,
        reason: 'Approving twice must fail',
      );
      _log('8. Rules', 'edit-after-approve and double-approve both rejected');

      // 9. Rewards after approval
      final rewardsAfter = (await _ledger(token))!;
      _log('9. Rewards after', _ledgerSummary(rewardsAfter));
      _log('9. Points granted', rewardsAfter.balance - rewardsBefore.balance);
      expect(
        rewardsAfter.entries.map((e) => e.orderId),
        contains(orderId),
        reason: 'Approved order should appear in the reward ledger',
      );

      // 10. Logout clears the session
      await auth.logout();
      final afterLogout = AuthProvider();
      await afterLogout.loadSession();
      expect(afterLogout.isAuthenticated, isFalse);
      _log('10. Logout', 'session cleared');
    },
    skip:
        !_hasSession || !_demoFlow
            ? 'Pass a session and LIVE_DEMO_FLOW=true to run'
            : false,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'reward ledger from the live backend',
    () async {
      final auth = await _signIn();
      final rewards = RewardProvider();
      await rewards.fetchLedger(token: auth.authToken);

      _log('Ledger error', rewards.ledgerError);
      final ledger = rewards.ledger;
      expect(ledger, isNotNull, reason: rewards.ledgerError);
      _log('Ledger', {
        'current_points': ledger!.balance,
        'total_earned': ledger.totalEarned,
        'total_redeemed': ledger.totalRedeemed,
        'entries': [
          for (final e in ledger.entries)
            '${e.date} ${e.isCredit ? '+' : '-'}${e.coins} ${e.description}',
        ],
      });
    },
    skip:
        !_hasSession || !_checkRewards
            ? 'Pass a session and LIVE_REWARDS=true to run'
            : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

// Log in with a password, or restore the session exactly as the app does on
// startup when a token is given
Future<AuthProvider> _signIn() async {
  final auth = AuthProvider();
  if (_token.isEmpty) {
    final loggedIn = await auth.login(
      _username,
      _password,
      userType: _userType,
    );
    expect(loggedIn, isTrue, reason: 'Login failed: ${auth.errorMessage}');
  } else {
    await auth.loadSession();
  }
  return auth;
}

ProductModel _catalogProduct(int variantId) {
  final v = ProductCatalog.variants.firstWhere((v) => v.variantId == variantId);
  return ProductModel(
    variantId: v.variantId,
    name: v.name,
    size: v.size,
    grade: v.grade,
    quantity: 0,
    unitPrice: v.pricePerTonne,
    totalPrice: 0,
  );
}

Map<String, dynamic> _cartSummary(CartProvider cart) => {
  'lines': [
    for (final i in cart.items)
      '#${i.productVariantId} ${i.productName} ${i.grade}: '
          '${i.quantity} t × ₹${i.unitPrice} = ₹${i.lineTotal}',
  ],
  'total_tonnes': cart.totalTonnes,
  'expected_total_amount': cart.totalAmount,
};

Future<RewardLedger?> _ledger(String? token) async {
  final rewards = RewardProvider();
  await rewards.fetchLedger(token: token);
  expect(rewards.ledgerError, isNull, reason: rewards.ledgerError);
  return rewards.ledger;
}

Map<String, dynamic> _ledgerSummary(RewardLedger l) => {
  'current_points': l.balance,
  'entries': [
    for (final e in l.entries)
      '${e.date} ${e.isCredit ? '+' : '-'}${e.coins} ${e.description}',
  ],
};

// Call something the backend should refuse, and report what happened
Future<void> _expectRejected(
  String label,
  Future<Map<String, dynamic>> Function() call,
) async {
  try {
    final response = await call();
    _log('RULE BROKEN: $label was accepted', response);
  } on ApiException catch (e) {
    _log('Rule OK: $label rejected (${e.statusCode})', e.message);
  }
}

// Edit an order through the app's cart and provider, then read it back
Future<void> _editAndVerify(String orderId, String? token) async {
  final variant = ProductCatalog.variants[1];
  final cart =
      CartProvider()
        ..add(
          ProductModel(
            variantId: variant.variantId,
            name: variant.name,
            size: variant.size,
            grade: variant.grade,
            quantity: 0,
            unitPrice: variant.pricePerTonne,
            totalPrice: 0,
          ),
          1.5,
        )
        ..setNote('App test order (edited) – please ignore');

  final payload = cart.buildEditPayload(orderId: orderId);
  _log('Edit payload', payload);

  try {
    final response = await ApiService.editOrder(payload: payload, token: token);
    _log('Edit response', response);
  } on ApiException catch (e) {
    _log('Edit FAILED (${e.statusCode})', e.message);
    _log('Server error detail', _djangoErrorSummary(e.responseBody));
    rethrow;
  }

  _log('Order after edit', await _findOrder(orderId, token));
}

// Approve an order, then read it back and check its status changed
Future<void> _approveAndVerify(String orderId, String? token) async {
  final before = await _findOrder(orderId, token);
  _log('Order before approval', before);
  expect(before, isNotNull, reason: '$orderId not in order list');

  try {
    final response = await ApiService.approveOrder(
      orderId: orderId,
      token: token,
    );
    _log('Approve response', response);
  } on ApiException catch (e) {
    _log('Approve FAILED (${e.statusCode})', e.message);
    _log('Server error detail', _djangoErrorSummary(e.responseBody));
    rethrow;
  }

  final after = await _findOrder(orderId, token);
  _log('Order after approval', after);
  expect(after?['status'], isNot(before?['status']));
}

// Look an order up in the user's order list by its display id
Future<Map<String, dynamic>?> _findOrder(String orderId, String? token) async {
  final data = await ApiService.fetchDistributionOrders(token: token);
  final items = (data['items'] as List?) ?? const [];
  for (final item in items.whereType<Map>()) {
    if (item['id'] == orderId) return item.cast<String, dynamic>();
  }
  return null;
}
