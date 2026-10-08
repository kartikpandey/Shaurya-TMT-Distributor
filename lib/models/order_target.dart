import '../config/constants/app_constants.dart';

/// The three roles that can place orders, from the top of the hierarchy down.
/// Distributor → Dealer → Sub-dealer (Mason/Contractor/Architect).
enum OrderingRole {
  distributor,
  dealer,
  subDealer;

  // Map the login API's integer user type to an ordering role
  static OrderingRole? fromUserType(int? userType) {
    switch (userType) {
      case AppConstants.distributorUserType:
        return OrderingRole.distributor;
      case AppConstants.dealerUserType:
        return OrderingRole.dealer;
      case AppConstants.contractorUserType:
        return OrderingRole.subDealer;
      default:
        return null;
    }
  }
}

class OrderTargetException implements Exception {
  final String message;

  OrderTargetException(this.message);

  @override
  String toString() => message;
}

/// Who an order is for, resolved into the ids the create-order API expects.
///
/// `customer_id` is always whoever the order is for. Parent ids the app does
/// not know (a dealer's distributor, a sub-dealer's dealer and distributor)
/// are sent as null and filled in by the backend.
class OrderTarget {
  final int? distributorId;
  final int? dealerId;
  final int customerId;

  /// Human-readable name of whoever the order is for, shown on review screens
  final String label;

  const OrderTarget({
    this.distributorId,
    this.dealerId,
    required this.customerId,
    required this.label,
  });

  /// Resolve the order's distributor/dealer/customer ids.
  ///
  /// [selfId] is the logged-in user. [childId] is one of the user's direct
  /// children (a distributor's dealer or a dealer's sub-dealer) when ordering
  /// on their behalf; leave it null for an order the user places for
  /// themselves.
  factory OrderTarget.resolve({
    required OrderingRole role,
    required int selfId,
    int? childId,
    required String label,
  }) {
    switch (role) {
      case OrderingRole.subDealer:
        if (childId != null) {
          throw OrderTargetException(
            'Sub-dealers can only place orders for themselves.',
          );
        }
        return OrderTarget(customerId: selfId, label: label);

      case OrderingRole.dealer:
        return OrderTarget(
          dealerId: selfId,
          customerId: childId ?? selfId,
          label: label,
        );

      case OrderingRole.distributor:
        return OrderTarget(
          distributorId: selfId,
          dealerId: childId,
          customerId: childId ?? selfId,
          label: label,
        );
    }
  }

  // Party fields of the create-order payload
  Map<String, dynamic> toRequestJson() => {
    'distributor_id': distributorId,
    'dealer_id': dealerId,
    'customer_id': customerId,
  };
}
