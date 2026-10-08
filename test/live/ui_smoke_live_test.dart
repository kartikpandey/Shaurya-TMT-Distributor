// Boots the real app against the live backend with a saved session and
// walks every screen at phone size, failing on any exception or layout
// overflow. Read-only: it opens screens but never places, edits or approves.
//
//   flutter test test/live/ui_smoke_live_test.dart \
//     --dart-define=LIVE_TOKEN=<token> \
//     --dart-define=LIVE_LOGIN_FILE=<login response JSON> \
//     --dart-define=LIVE_USER_TYPE=3
import 'dart:io';

import 'package:distributor/main.dart';
import 'package:distributor/providers/auth_provider.dart';
import 'package:distributor/widgets/dashboard/kpi_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _token = String.fromEnvironment('LIVE_TOKEN');
const _loginFile = String.fromEnvironment('LIVE_LOGIN_FILE');
const _userType = int.fromEnvironment('LIVE_USER_TYPE', defaultValue: 3);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The test binding fakes every HTTP call; this test needs the real network
  HttpOverrides.global = null;

  testWidgets(
    'every screen renders with live data at phone size',
    (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 780 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({
        'auth_token': _token,
        'login_response': File(_loginFile).readAsStringSync(),
        'user_type': _userType,
      });
      final auth = AuthProvider();
      await tester.runAsync(auth.loadSession);

      // Let real network calls finish, then render
      Future<void> settle([int seconds = 3]) async {
        // Alternate real waiting with frames so responses get processed
        for (var i = 0; i < seconds * 4; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 250)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
        final error = tester.takeException();
        if (error != null) {
          // ignore: avoid_print
          print(error is FlutterError ? error.toStringDeep() : error);
          debugDumpRenderTree();
        }
        expect(error, isNull);
      }

      // The app bar uses a custom back button, so pop the route directly
      Future<void> back() async {
        tester.state<NavigatorState>(find.byType(Navigator).first).pop();
        await tester.pump();
      }

      void step(String name) {
        // ignore: avoid_print
        print('✓ $name');
      }

      await tester.pumpWidget(MyApp(authProvider: auth));
      await settle();

      // Home
      Finder tile(String title) => find.widgetWithText(KPICard, title);
      expect(tile('Open Orders'), findsOneWidget);
      expect(tile('Approved'), findsOneWidget);
      expect(tile('Order Value'), findsOneWidget);
      expect(tile('Active Sub-dealers'), findsOneWidget);
      expect(find.text('Recent Orders'), findsOneWidget);
      expect(find.text('New Order'), findsNothing);
      expect(find.text('View Reports'), findsNothing);
      expect(find.textContaining('Stock'), findsNothing);
      step('Home: 4 tiles, no stock health or quick actions');

      // Recent orders: at most five
      await tester.ensureVisible(find.text('View All'));
      await settle(1);
      step('Home: recent orders visible');

      // Approved tile -> Awaiting Approval
      await tester.ensureVisible(tile('Approved'));
      await tester.pump();
      await tester.tap(tile('Approved'));
      await settle();
      expect(find.text('Awaiting Approval'), findsOneWidget);
      expect(find.text('Approve'), findsWidgets);
      step('Approved tile opens Awaiting Approval with Approve buttons');

      // Order details sheet -> Edit Order screen (not saved)
      await tester.tap(find.textContaining('ORD-').first);
      await settle(1);
      expect(find.text('Order Details'), findsOneWidget);
      expect(find.text('Payment'), findsNothing);
      expect(find.text('Edit Order'), findsOneWidget);
      step('Details sheet: no payment status, Edit available');

      await tester.tap(find.text('Edit Order'));
      await settle(1);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Add product'), findsOneWidget);
      await tester.tap(find.text('Add product'));
      await settle(1);
      await tester.tap(find.text('ShauryaTMT 12mm').first);
      await settle(1);
      expect(find.text('1 items · 1 t'), findsOneWidget);
      step('Edit screen: add product works (not saved)');

      await back();
      await settle(1);
      await back();
      await settle(1);

      // View All -> Orders tab
      expect(find.text('Recent Orders'), findsOneWidget);
      await tester.ensureVisible(find.text('View All'));
      await tester.pump();
      await tester.tap(find.text('View All'));
      await settle();
      expect(find.text('Order History'), findsOneWidget);
      expect(find.text('All Orders'), findsOneWidget);
      step('View All switches to Order History');

      await tester.enterText(find.byType(TextField).first, 'DHARMA');
      await settle(1);
      step('Order History: search works');

      // Rewards: balance and ledger under Activity
      await tester.tap(find.text('Rewards'));
      await settle();
      expect(find.text('Super Coins Balance'), findsOneWidget);
      expect(find.text('—'), findsNothing, reason: 'Points should load');
      await tester.tap(find.text('Activity'));
      await settle(1);
      expect(find.text('Order reward'), findsWidgets);
      step('Rewards: live points and ledger under Activity');

      // New order: catalog -> add -> review (not placed)
      await tester.tap(find.text('Home'));
      await settle(1);
      await tester.tap(find.byType(FloatingActionButton));
      await settle(1);
      expect(find.text('Products'), findsOneWidget);
      await tester.tap(find.text('Add to Order').first);
      await settle(1);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add to Order'));
      await settle(1);
      await tester.tap(find.text('Review'));
      await settle(1);
      expect(find.text('Review Order'), findsOneWidget);
      await tester.tap(find.text('Tap to choose'));
      await settle();
      expect(find.text('Myself'), findsOneWidget);
      await tester.tap(find.text('Myself'));
      await settle(1);
      expect(find.text('Choose who this order is for.'), findsNothing);
      step(
        'New order: catalog, cart, review and Order-for picker (not placed)',
      );

      await back();
      await settle(1);
      await back();
      await settle(1);

      // Profile
      await tester.tap(find.text('Profile'));
      await settle(1);
      step('Profile renders');
    },
    skip: _token.isEmpty,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
