// Tolerant int coercion: the API may send numbers, numeric strings or nulls
int? _asInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

// Tolerant string coercion: ids and enums may arrive as numbers
String? _asString(dynamic value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is num) return value.toString();
  if (value is bool) return value.toString();
  return null;
}

class DashboardModel {
  final String message;
  final DashboardSummary summary;

  /// Raw dealer objects straight off the API. Kept dynamic until the dealer
  /// schema is confirmed, so new fields show up without a model change.
  final List<Map<String, dynamic>> dealers;
  final int responseCode;
  final DateTime fetchedAt;

  DashboardModel({
    required this.message,
    required this.summary,
    required this.dealers,
    required this.responseCode,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  // Create from JSON
  factory DashboardModel.fromJson(Map<String, dynamic> json) => DashboardModel(
    message: _asString(json['message']) ?? '',
    summary: DashboardSummary.fromJson(
      (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    // The backend has named the children list both ways
    dealers: _asMapList(
      json['dealers'] ?? json['dealer_list'] ?? json['dealers_list'],
    ),
    responseCode: _asInt(json['response_code']) ?? 200,
  );

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    'message': message,
    'summary': summary.toJson(),
    'dealers': dealers,
    'response_code': responseCode,
  };
}

// Coerce a JSON array into a list of string-keyed maps, skipping other shapes
List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
}

class DashboardSummary {
  final int openOrders;
  final int approvedOrders;
  final int pendingDispatch;
  final int returns;
  final String stockHealth;

  DashboardSummary({
    this.openOrders = 0,
    this.approvedOrders = 0,
    this.pendingDispatch = 0,
    this.returns = 0,
    this.stockHealth = 'unknown',
  });

  // Create from JSON
  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        openOrders: _asInt(json['open_orders']) ?? 0,
        approvedOrders: _asInt(json['approved_orders']) ?? 0,
        pendingDispatch: _asInt(json['pending_dispatch']) ?? 0,
        returns: _asInt(json['returns']) ?? 0,
        stockHealth:
            _asString(json['stock_health'])?.toLowerCase() ?? 'unknown',
      );

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    'open_orders': openOrders,
    'approved_orders': approvedOrders,
    'pending_dispatch': pendingDispatch,
    'returns': returns,
    'stock_health': stockHealth,
  };

  // Total orders across every pipeline stage
  int get totalOrders => openOrders + approvedOrders + pendingDispatch;

  // True when any stage needs attention
  bool get hasActionableItems =>
      openOrders > 0 ||
      approvedOrders > 0 ||
      pendingDispatch > 0 ||
      returns > 0;

  // Stock health severity, used to pick the accent colour
  bool get isStockCritical => stockHealth == 'critical' || stockHealth == 'low';
}
