import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../models/distribution_order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';

/// Approves a placed order after the user confirms.
class ApproveOrderButton extends StatelessWidget {
  final DistributionOrder order;

  /// Called after a successful approval, e.g. to close a sheet
  final VoidCallback? onApproved;

  const ApproveOrderButton({super.key, required this.order, this.onApproved});

  Future<void> _approve(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Approve order?'),
            content: Text(
              'Approve ${order.orderId} for ${order.dealerName}? '
              'This cannot be undone from the app.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Approve'),
              ),
            ],
          ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<OrderProvider>().approveOrder(
      order.orderId,
      token: context.read<AuthProvider>().authToken,
    );

    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? '${order.orderId} approved'),
        backgroundColor: error == null ? AppColors.successGreen : null,
      ),
    );
    if (error == null) onApproved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final approving = context.select<OrderProvider, bool>(
      (p) => p.isApproving(order.orderId),
    );

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: approving ? null : () => _approve(context),
        icon:
            approving
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Icon(Icons.check_circle_outline, size: 18),
        label: Text(approving ? 'Approving…' : 'Approve'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.successGreen,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
