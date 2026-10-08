import 'package:flutter/material.dart';
import '../models/distribution_order.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';

class OrderProvider extends ChangeNotifier {
  List<DistributionOrder> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSubmitting = false;
  String? _submitError;
  String? _lastOrderReference;
  final Set<String> _approving = {};

  // Getters

  /// The user's own and children's orders, newest first
  List<DistributionOrder> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;
  String? get lastOrderReference => _lastOrderReference;

  List<DistributionOrder> recentOrders([int count = 5]) =>
      _orders.take(count).toList();

  List<DistributionOrder> get awaitingApproval =>
      _orders.where((o) => o.isAwaitingApproval).toList();

  /// Total value of orders dated in the current IST calendar month
  double get currentMonthOrderValue {
    final now = AppFormatters.nowIst();
    return _orders
        .where((o) => o.date?.year == now.year && o.date?.month == now.month)
        .fold(0.0, (sum, o) => sum + o.totalAmount);
  }

  /// Statuses present in the loaded orders, for filter chips
  List<String> get statuses => {..._orders.map((o) => o.status)}.toList();

  bool isApproving(String orderId) => _approving.contains(orderId);

  // Fetch orders from the distribution orders API
  Future<void> fetchOrders({String? token}) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.fetchDistributionOrders(token: token);
      final items = data['items'];
      _orders =
          (items is List ? items : const [])
              .whereType<Map>()
              .map((e) => DistributionOrder.tryParse(e.cast<String, dynamic>()))
              .whereType<DistributionOrder>()
              .toList()
            ..sort(DistributionOrder.newestFirst);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Unable to load orders. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Approve a placed order, then reload the list so its status updates.
  /// Returns null on success, otherwise an error message.
  Future<String?> approveOrder(String orderId, {String? token}) async {
    if (_approving.contains(orderId)) return null;

    _approving.add(orderId);
    notifyListeners();

    try {
      await ApiService.approveOrder(orderId: orderId, token: token);
      _approving.remove(orderId);
      await fetchOrders(token: token);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Could not approve order. Please try again.';
    } finally {
      if (_approving.remove(orderId)) notifyListeners();
    }
  }

  /// Replace an unapproved order's note and lines, then reload the list.
  /// Returns null on success, otherwise an error message.
  Future<String?> editOrder({
    required Map<String, dynamic> payload,
    String? token,
  }) async {
    try {
      await ApiService.editOrder(payload: payload, token: token);
      await fetchOrders(token: token);
      return null;
    } on ApiException catch (e) {
      return e.statusCode == 404
          ? 'Order editing is not available on the server yet.'
          : e.message;
    } catch (e) {
      return 'Could not update order. Please try again.';
    }
  }

  // Place a new order with the create-order API.
  // Returns true on success; otherwise [submitError] explains why.
  Future<bool> submitOrder({
    required Map<String, dynamic> payload,
    String? token,
  }) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _submitError = null;
    _lastOrderReference = null;
    notifyListeners();

    try {
      final data = await ApiService.createOrder(payload: payload, token: token);
      _lastOrderReference = _extractOrderReference(data);
      return true;
    } on ApiException catch (e) {
      _submitError = e.message;
      return false;
    } catch (e) {
      _submitError = 'Could not place order. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // Response schema is unconfirmed, so look for an order id in likely places
  String? _extractOrderReference(Map<String, dynamic> data) {
    for (final source in [data, data['data'], data['order']]) {
      if (source is! Map) continue;
      for (final key in const ['order_number', 'order_id', 'id']) {
        final value = source[key];
        if (value is String && value.isNotEmpty) return value;
        if (value is num) return value.toString();
      }
    }
    return null;
  }

  // Forget the previous user's orders on logout
  void clear() {
    _orders = [];
    _errorMessage = null;
    notifyListeners();
  }
}
