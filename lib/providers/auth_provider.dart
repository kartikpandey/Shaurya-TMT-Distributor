import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants/app_constants.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _authToken;
  String? _errorMessage;
  int? _userTypeId;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get authToken => _authToken;
  String? get errorMessage => _errorMessage;

  /// Login API user type (1-7), see AppConstants; null for mock OTP logins
  int? get userTypeId => _userTypeId;

  // Login via API
  Future<bool> login(
    String username,
    String password, {
    int userType = AppConstants.defaultUserType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.login(
        username: username,
        password: password,
        userType: userType,
      );

      final prefs = await SharedPreferences.getInstance();

      // Save every info received from the response
      await prefs.setString(
        AppConstants.loginResponseKey,
        jsonEncode(_withoutSecrets(data)),
      );
      await prefs.setInt(AppConstants.userTypeKey, userType);
      _userTypeId = userType;

      final token = _extractToken(data);
      if (token != null) {
        _authToken = token;
        await prefs.setString(AppConstants.authTokenKey, token);
      }

      _currentUser = _buildUserFromResponse(data, username, userType);
      if (_currentUser != null) {
        await prefs.setString(
          AppConstants.userDataKey,
          jsonEncode(_currentUser!.toJson()),
        );
      }
      _isLoggedIn = true;

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Restore persisted session on app startup
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString(AppConstants.authTokenKey);
    final rawResponse = prefs.getString(AppConstants.loginResponseKey);
    final savedUser = prefs.getString(AppConstants.userDataKey);

    if (token == null && (rawResponse == null && savedUser == null)) {
      return;
    }

    _authToken = token;

    Map<String, dynamic>? responseData;
    if (rawResponse != null) {
      try {
        responseData = jsonDecode(rawResponse) as Map<String, dynamic>;
      } catch (_) {
        responseData = null;
      }
    }

    final int? savedUserType = prefs.getInt(AppConstants.userTypeKey);
    _userTypeId = savedUserType;

    if (responseData != null) {
      _currentUser = _buildUserFromResponse(
        responseData,
        _extractUsername(responseData, savedUser),
        savedUserType ?? AppConstants.defaultUserType,
      );
    }

    if (_currentUser == null && savedUser != null) {
      try {
        _currentUser = UserModel.fromJson(
          jsonDecode(savedUser) as Map<String, dynamic>,
        );
      } catch (_) {
        _currentUser = null;
      }
    }

    _isLoggedIn = _authToken != null || _currentUser != null;
    notifyListeners();
  }

  // Login with OTP
  Future<bool> loginWithOTP(String phone, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Mock login with OTP
      _currentUser = UserModel(
        name: 'Rahul Sharma',
        email: 'rahul@traders.com',
        phoneNumber: phone,
        userType: 'distributor',
        companyName: 'Rahul Traders Inc.',
        location: 'Mumbai, Maharashtra',
        isVerified: true,
      );
      _authToken = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
      _isLoggedIn = true;

      return true;
    } catch (e) {
      _errorMessage = 'Login failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send OTP
  Future<bool> sendOTP(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      return true;
    } catch (e) {
      _errorMessage = 'Failed to send OTP. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.authTokenKey);
    await prefs.remove(AppConstants.userDataKey);
    await prefs.remove(AppConstants.loginResponseKey);
    await prefs.remove(AppConstants.userTypeKey);

    _currentUser = null;
    _authToken = null;
    _userTypeId = null;
    _isLoggedIn = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Update user profile
  void updateUserProfile(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  // Enable biometric
  void enableBiometric(bool enable) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(isBiometricEnabled: enable);
      notifyListeners();
    }
  }

  // Check if authenticated
  bool get isAuthenticated => _isLoggedIn && _currentUser != null;

  // ---- Helpers ----

  // The login response includes the user's password hash; never persist it
  static dynamic _withoutSecrets(dynamic value) {
    if (value is Map) {
      return {
        for (final entry in value.entries)
          if (entry.key != 'password') entry.key: _withoutSecrets(entry.value),
      };
    }
    if (value is List) return value.map(_withoutSecrets).toList();
    return value;
  }

  String? _extractToken(Map<String, dynamic> data) {
    for (final key in const [
      'token',
      'key',
      'access_token',
      'access',
      'jwt',
      'auth_token',
      'accessToken',
      'authToken',
    ]) {
      final value = data[key];
      if (value is String && value.isNotEmpty) return value;
    }
    for (final nestedKey in const [
      'data',
      'user',
      'result',
      'response',
      'tokens',
    ]) {
      final nested = data[nestedKey];
      if (nested is Map<String, dynamic>) {
        final value = _extractToken(nested);
        if (value != null) return value;
      }
    }
    return null;
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      if (v is String && v.trim().isNotEmpty) return v.trim();
      // Ids arrive as numbers
      if (v is num) return v.toString();
    }
    return '';
  }

  UserModel? _buildUserFromResponse(
    Map<String, dynamic> data,
    String fallbackUsername,
    int userType,
  ) {
    Map<String, dynamic> userData = {};
    for (final key in const [
      'user_details',
      'user',
      'data',
      'result',
      'response',
      'profile',
    ]) {
      var nested = data[key];
      // user_details arrives as a one-element list
      if (nested is List && nested.isNotEmpty) nested = nested.first;
      if (nested is Map<String, dynamic>) {
        userData = nested;
        break;
      }
    }
    if (userData.isEmpty) userData = data;

    final nameParts = [
      userData['first_name'],
      userData['middle_name'],
      userData['last_name'],
    ].whereType<String>().map((p) => p.trim()).where((p) => p.isNotEmpty);

    final name = _firstNonEmpty([
      userData['name'],
      userData['full_name'],
      userData['fullname'],
      nameParts.join(' '),
      data['name'],
      data['full_name'],
      fallbackUsername,
    ]);

    final email = _firstNonEmpty([
      userData['email'],
      userData['email_id'],
      userData['official_email'],
      data['email'],
      data['email_id'],
    ]);

    final phone = _firstNonEmpty([
      userData['phone'],
      userData['phone_number'],
      userData['primary_contact_number'],
      userData['mobile'],
      userData['mobile_number'],
      data['phone'],
      data['mobile'],
    ]);

    final String userTypeLabel =
        (userData['user_type'] ??
                    userData['userType'] ??
                    data['user_type'] ??
                    data['userType'] ??
                    userType)
                is int
            ? AppConstants.userTypeLabels[(userData['user_type'] ??
                        userData['userType'] ??
                        data['user_type'] ??
                        data['userType'] ??
                        userType)
                    as int] ??
                userType.toString()
            : (userData['user_type'] ??
                    userData['userType'] ??
                    data['user_type'] ??
                    data['userType'] ??
                    '')
                .toString();

    final company = _firstNonEmpty([
      userData['company_name'],
      userData['company'],
      userData['store_name'],
      userData['companyName'],
      data['company_name'],
      data['company'],
    ]);

    final location = _firstNonEmpty([
      userData['location'],
      userData['address'],
      data['location'],
      data['address'],
    ]);

    final id = _firstNonEmpty([
      userData['id'],
      userData['user_id'],
      userData['userId'],
      data['id'],
      data['user_id'],
    ]);

    if (name.isEmpty && email.isEmpty && phone.isEmpty) {
      return null;
    }

    return UserModel(
      id: id.isEmpty ? null : id,
      name: name.isNotEmpty ? name : 'User',
      email: email.isNotEmpty ? email : fallbackUsername,
      phoneNumber: phone.isNotEmpty ? phone : '',
      userType: userTypeLabel,
      companyName: company.isNotEmpty ? company : null,
      location: location.isNotEmpty ? location : null,
      isVerified: true,
    );
  }

  String _extractUsername(Map<String, dynamic> data, String? savedUser) {
    if (savedUser != null) {
      try {
        final decoded = jsonDecode(savedUser) as Map<String, dynamic>;
        final email = decoded['email'] as String?;
        if (email != null && email.isNotEmpty) return email;
      } catch (_) {}
    }
    for (final key in const ['username', 'email', 'email_id']) {
      final value = data[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return '';
  }
}
