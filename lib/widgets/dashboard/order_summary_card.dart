import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../models/distribution_order.dart';
import '../../utils/formatters.dart';

class OrderSummaryCard extends StatelessWidget {
  final DistributionOrder order;
  final VoidCallback? onTap;

  /// Optional action shown under the details, e.g. an Approve button
  final Widget? action;

  const OrderSummaryCard({
    super.key,
    required this.order,
    this.onTap,
    this.action,
  });

  static Color statusColor(String status) {
    switch (status) {
      case DistributionOrder.placedStatus:
        return Colors.orange;
      case 'APPROVED':
        return AppColors.successGreen;
      case 'REJECTED':
      case 'CANCELLED':
        return AppColors.warningRed;
      default:
        return AppColors.infoBlue;
    }
  }

  // PENDING_DISPATCH -> Pending dispatch
  static String statusLabel(String status) {
    final words = status.replaceAll('_', ' ').toLowerCase();
    return AppFormatters.capitalize(words);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = statusColor(order.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.dealerName,
                          style: AppTextStyles.titleMedium(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.orderId,
                          style: AppTextStyles.labelSmall(
                            context,
                          ).copyWith(color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel(order.status),
                      style: AppTextStyles.labelSmall(
                        context,
                      ).copyWith(color: color, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                height: 1,
              ),
              const SizedBox(height: 12),

              // Details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      'Total Amount',
                      AppFormatters.formatCurrency(order.totalAmount),
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      'Order Date',
                      order.date != null
                          ? AppFormatters.formatDate(order.date!)
                          : '—',
                    ),
                  ),
                ],
              ),
              if (action != null) ...[const SizedBox(height: 12), action!],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall(
            context,
          ).copyWith(color: AppColors.textHint),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.titleSmall(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
