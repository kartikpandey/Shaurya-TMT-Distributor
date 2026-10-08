import 'dart:convert';

import 'package:distributor/config/constants/app_constants.dart';
import 'package:distributor/models/order_target.dart';
import 'package:distributor/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Shape of the live login response, with fake values
final _loginResponse = {
  'token': 'abc123',
  'user_details': [
    {
      'id': 760,
      'salutation': 'Mr',
      'first_name': 'Test',
      'middle_name': '',
      'last_name': 'Dealer',
      'store_name': 'Test Store',
      'official_email': 'dealer@example.com',
      'primary_contact_number': '9000000000',
      'password': 'pbkdf2_sha256\$fake',
      'organization_id': null,
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reads the user from the user_details list', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.authTokenKey: 'abc123',
      AppConstants.loginResponseKey: jsonEncode(_loginResponse),
      AppConstants.userTypeKey: AppConstants.dealerUserType,
    });

    final auth = AuthProvider();
    await auth.loadSession();
    final user = auth.currentUser!;

    expect(user.id, '760');
    expect(user.name, 'Test Dealer');
    expect(user.email, 'dealer@example.com');
    expect(user.phoneNumber, '9000000000');
    expect(user.companyName, 'Test Store');
    expect(
      OrderingRole.fromUserType(auth.userTypeId),
      OrderingRole.dealer,
    );
  });
}
