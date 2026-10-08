import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/constants/app_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  /// Raw body of a non-JSON error response, kept for diagnostics only
  final String? responseBody;

  ApiException(this.message, {this.statusCode, this.responseBody});

  @override
  String toString() => message;
}

class ApiService {
  // Build request headers, attaching DRF token auth when a token is available
  static Map<String, String> buildHeaders({String? token}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers[AppConstants.authHeaderKey] = '${AppConstants.authScheme} $token';
    }
    return headers;
  }

  // Decode response body and validate the response_code envelope
  static Map<String, dynamic> decodeResponse(
    http.Response response, {
    String failureLabel = 'Request failed',
  }) {
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Unexpected server response (${response.statusCode}). Please try again.',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }

    final rawCode = decoded['response_code'];
    final int? responseCode =
        rawCode is num
            ? rawCode.toInt()
            : rawCode is String
            ? int.tryParse(rawCode)
            : null;
    final bool success =
        (response.statusCode >= 200 && response.statusCode < 300) ||
        responseCode == 200;

    if (!success) {
      final rawMessage = decoded['message'];
      final message =
          (rawMessage is String ? rawMessage : null) ??
          '$failureLabel (${responseCode ?? response.statusCode}). Please try again.';
      throw ApiException(
        message,
        statusCode: responseCode ?? response.statusCode,
      );
    }

    return decoded;
  }

  // Send a request, translating transport failures into ApiException
  static Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(AppConstants.apiTimeout);
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      throw ApiException('Unable to reach the server. Please try again.');
    }
  }

  // GET request helper
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
  }) async {
    final response = await _send(
      () => http.get(Uri.parse(endpoint), headers: buildHeaders(token: token)),
    );
    return decodeResponse(response);
  }

  // POST request helper, JSON-encoding the body
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
    String failureLabel = 'Request failed',
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse(endpoint),
        headers: buildHeaders(token: token),
        body: jsonEncode(body),
      ),
    );
    return decodeResponse(response, failureLabel: failureLabel);
  }

  // Fetch distributor dashboard data
  static Future<Map<String, dynamic>> fetchDistributionDashboard({
    String? token,
  }) async {
    return get(AppConstants.dashboardEndpoint, token: token);
  }

  // Place a new order
  static Future<Map<String, dynamic>> createOrder({
    required Map<String, dynamic> payload,
    String? token,
  }) async {
    return post(
      AppConstants.createOrderEndpoint,
      body: payload,
      token: token,
      failureLabel: 'Could not place order',
    );
  }

  // Orders visible to the logged-in user (own and children's)
  static Future<Map<String, dynamic>> fetchDistributionOrders({
    String? token,
  }) async {
    return get(AppConstants.ordersEndpoint, token: token);
  }

  // Approve an order by its display id, e.g. ORD-20260930120114.
  // Parents approve their children's orders; dealers may approve their own.
  static Future<Map<String, dynamic>> approveOrder({
    required String orderId,
    String? token,
  }) async {
    return post(
      AppConstants.approveOrderEndpoint,
      body: {'order_id': orderId},
      token: token,
      failureLabel: 'Could not approve order',
    );
  }

  // Super-coin ledger and current points for the logged-in user
  static Future<Map<String, dynamic>> fetchRewardLedger({String? token}) async {
    return get(AppConstants.rewardLedgerEndpoint, token: token);
  }

  // Replace an unapproved order's note and product lines
  static Future<Map<String, dynamic>> editOrder({
    required Map<String, dynamic> payload,
    String? token,
  }) async {
    return post(
      AppConstants.editOrderEndpoint,
      body: payload,
      token: token,
      failureLabel: 'Could not update order',
    );
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    required int userType,
  }) async {
    return post(
      AppConstants.loginEndpoint,
      body: {'username': username, 'password': password, 'user_type': userType},
      failureLabel: 'Login failed',
    );
  }
}
