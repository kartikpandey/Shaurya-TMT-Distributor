import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../models/network_member.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardModel? _dashboard;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  DashboardModel? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _dashboard != null;

  DashboardSummary? get summary => _dashboard?.summary;

  /// Raw dealer objects, kept dynamic until the dealer schema is confirmed
  List<Map<String, dynamic>> get dealers => _dashboard?.dealers ?? const [];
  int get dealerCount => dealers.length;

  /// The user's direct children (dealers or sub-dealers) with usable ids
  List<NetworkMember> get children =>
      dealers.map(NetworkMember.tryParse).whereType<NetworkMember>().toList();

  // Fetch distributor dashboard data
  Future<void> fetchDashboard({String? token, bool force = false}) async {
    if (_isLoading) return;
    if (_dashboard != null && !force) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.fetchDistributionDashboard(token: token);
      _dashboard = DashboardModel.fromJson(data);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Unable to load dashboard. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Clear cached dashboard data
  void clear() {
    _dashboard = null;
    _errorMessage = null;
    notifyListeners();
  }
}
