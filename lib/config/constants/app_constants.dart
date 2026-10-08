class AppConstants {
  // App Info
  static const String appName = 'Shaurya TMT';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'B2B Distributor & Dealer Management Portal';

  // API Endpoints
  static const String baseUrl = 'http://167.71.227.184/api/v1';
  static const String loginEndpoint = '$baseUrl/login';
  static const String ordersEndpoint = '$baseUrl/distribution/orders/';
  static const String createOrderEndpoint =
      '$baseUrl/distribution/orders/create/';
  static const String approveOrderEndpoint =
      '$baseUrl/distribution/orders/approve/';
  static const String editOrderEndpoint = '$baseUrl/distribution/orders/edit/';
  static const String rewardsEndpoint = '$baseUrl/rewards';
  // Super-coin ledger and current points for the logged-in user
  static const String rewardLedgerEndpoint = '$baseUrl/distribution/rewards/';
  static const String dashboardEndpoint = '$baseUrl/distribution/dashboard/';

  // DRF token auth header format: 'Authorization: Token <token>'
  static const String authHeaderKey = 'Authorization';
  static const String authScheme = 'Token';

  // User types accepted by the login API (integer 1-7)
  static const int superAdminUserType = 1;
  static const int distributorUserType = 2;
  static const int dealerUserType = 3;
  static const int contractorUserType = 4;
  static const int salesManagerUserType = 5;
  static const int teamLeadUserType = 6;
  static const int salesmanUserType = 7;
  static const int defaultUserType = 3;

  static const Map<int, String> userTypeLabels = {
    superAdminUserType: 'Super Admin',
    distributorUserType: 'Distributor',
    dealerUserType: 'Dealer',
    contractorUserType: 'Mason/Contractor/Architect',
    salesManagerUserType: 'Sales Manager',
    teamLeadUserType: 'Team Lead',
    salesmanUserType: 'Salesman',
  };

  // Local Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String loginResponseKey = 'login_response';
  static const String userTypeKey = 'user_type';
  static const String userPreferencesKey = 'user_preferences';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';

  // Demo Data - Dealers/Distributors
  static const List<String> dealerNames = [
    'Rahul Traders Inc.',
    'Jain Mining Co.',
    'Sudama Traders',
    'Maruthi Hardware',
    'Sharma Steel Depot',
    'Kumar Distribution Center',
  ];

  // Demo Products
  static const List<String> productSizes = [
    '6mm',
    '8mm',
    '10mm',
    '12mm',
    '16mm',
    '20mm',
  ];

  static const List<String> productGrades = ['Grade A', 'Grade B'];

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);

  // UI Constants
  static const double defaultBorderRadius = 16.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 24.0;

  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Timeout Durations
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration debounceTimeout = Duration(milliseconds: 500);
}
