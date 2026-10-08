import '../utils/formatters.dart';

/// One product line of an order, as sent to the create/edit APIs
class DistributionOrderLine {
  final int productVariantId;
  final double quantity; // tonnes
  final double unitPrice; // per tonne

  const DistributionOrderLine({
    required this.productVariantId,
    required this.quantity,
    required this.unitPrice,
  });

  static DistributionOrderLine? tryParse(Map<String, dynamic> json) {
    final variant = _num(json['product_variant_id'] ?? json['variant_id']);
    final quantity = _num(json['quantity']);
    if (variant == null || quantity == null) return null;
    return DistributionOrderLine(
      productVariantId: variant.toInt(),
      quantity: quantity.toDouble(),
      unitPrice: (_num(json['unit_price']) ?? 0).toDouble(),
    );
  }

  static num? _num(dynamic value) =>
      value is num ? value : num.tryParse('${value ?? ''}'.trim());
}

/// An order as listed by the distribution orders API
/// (`GET /api/v1/distribution/orders/`), whose items carry
/// `id`, `status`, `dealer`, `total_amount` and `date`. The note and product
/// lines are read when the backend includes them (needed to pre-fill edits).
class DistributionOrder {
  /// Display id, e.g. ORD-20260930120114
  final String orderId;

  /// Upper-case backend status, e.g. PLACED or APPROVED
  final String status;
  final String dealerName;
  final double totalAmount;
  final DateTime? date;
  final String? note;

  /// Empty when the list API doesn't send product lines
  final List<DistributionOrderLine> lines;

  const DistributionOrder({
    required this.orderId,
    required this.status,
    required this.dealerName,
    required this.totalAmount,
    this.date,
    this.note,
    this.lines = const [],
  });

  static const String placedStatus = 'PLACED';

  /// Placed orders still need a parent's (or the dealer's own) approval
  bool get isAwaitingApproval => status == placedStatus;

  /// Orders can be edited only until they are approved
  bool get isEditable => isAwaitingApproval;

  /// Parse an order-list item; returns null when it has no id
  static DistributionOrder? tryParse(Map<String, dynamic> json) {
    final id = _text(json['id']) ?? _text(json['order_id']);
    if (id == null) return null;

    final amount = json['total_amount'];
    final rawLines = json['items'] ?? json['order_items'] ?? json['products'];
    return DistributionOrder(
      orderId: id,
      status: (_text(json['status']) ?? 'UNKNOWN').toUpperCase(),
      dealerName: _text(json['dealer']) ?? '—',
      totalAmount:
          amount is num
              ? amount.toDouble()
              : double.tryParse('${amount ?? ''}') ?? 0,
      date: AppFormatters.parseIst(_text(json['date'])),
      note: _text(json['note']),
      lines:
          (rawLines is List ? rawLines : const [])
              .whereType<Map>()
              .map(
                (e) =>
                    DistributionOrderLine.tryParse(e.cast<String, dynamic>()),
              )
              .whereType<DistributionOrderLine>()
              .toList(),
    );
  }

  static String? _text(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is num) return value.toString();
    return null;
  }

  /// Newest first. Dates are day-only, so ties fall back to the id, whose
  /// ORD-yyyyMMddHHmmss format sorts chronologically.
  static int newestFirst(DistributionOrder a, DistributionOrder b) {
    final byDate = (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0));
    return byDate != 0 ? byDate : b.orderId.compareTo(a.orderId);
  }
}
