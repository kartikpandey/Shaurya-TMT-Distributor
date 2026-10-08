import 'package:flutter/material.dart';
import '../../config/theme/app_text_styles.dart';
import '../../models/distribution_order.dart';
import '../../utils/formatters.dart';
import '../../screens/orders/edit_order_screen.dart';
import '../dashboard/order_summary_card.dart';
import 'approve_order_button.dart';

/// Bottom sheet with an order's details, and Approve / Edit for orders that
/// are not approved yet
Future<void> showOrderDetailSheet(
  BuildContext context,
  DistributionOrder order,
) {
  return showModalBottomSheet(
    context: context,
    // Grow past the default half-screen cap to fit all the actions, and
    // scroll if a small screen still can't
    isScrollControlled: true,
    builder:
        (sheetContext) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Details',
                  style: AppTextStyles.headlineSmall(sheetContext),
                ),
                const SizedBox(height: 16),
                _row(sheetContext, 'Order ID', order.orderId),
                _row(sheetContext, 'Dealer', order.dealerName),
                _row(
                  sheetContext,
                  'Status',
                  OrderSummaryCard.statusLabel(order.status),
                ),
                _row(
                  sheetContext,
                  'Total',
                  AppFormatters.formatCurrency(order.totalAmount),
                ),
                _row(
                  sheetContext,
                  'Order Date',
                  order.date != null
                      ? AppFormatters.formatDate(order.date!)
                      : '—',
                ),
                const SizedBox(height: 16),
                if (order.isAwaitingApproval) ...[
                  ApproveOrderButton(
                    order: order,
                    onApproved: () => Navigator.pop(sheetContext),
                  ),
                  const SizedBox(height: 8),
                ],
                if (order.isEditable) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditOrderScreen(order: order),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit Order'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

Widget _row(BuildContext context, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium(context)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.titleMedium(context),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    ),
  );
}
