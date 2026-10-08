import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/dashboard/order_summary_card.dart';
import '../../widgets/orders/approve_order_button.dart';
import '../../widgets/orders/order_detail_sheet.dart';

/// Orders still in PLACED status, each with an Approve button.
/// Parents approve their children's orders; dealers may approve their own.
class AwaitingApprovalScreen extends StatefulWidget {
  const AwaitingApprovalScreen({super.key});

  @override
  State<AwaitingApprovalScreen> createState() => _AwaitingApprovalScreenState();
}

class _AwaitingApprovalScreenState extends State<AwaitingApprovalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() {
    return context.read<OrderProvider>().fetchOrders(
      token: context.read<AuthProvider>().authToken,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Awaiting Approval'),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          final pending = orderProvider.awaitingApproval;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (orderProvider.isLoading && orderProvider.orders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (orderProvider.errorMessage != null &&
                    orderProvider.orders.isEmpty)
                  _buildMessage(
                    context,
                    Icons.cloud_off,
                    orderProvider.errorMessage!,
                  )
                else if (pending.isEmpty)
                  _buildMessage(
                    context,
                    Icons.task_alt,
                    'No orders are waiting for approval',
                  )
                else ...[
                  Text(
                    '${pending.length} order${pending.length == 1 ? '' : 's'} '
                    'waiting for approval',
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: AppColors.textHint),
                  ),
                  const SizedBox(height: 12),
                  ...pending.map(
                    (order) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OrderSummaryCard(
                        order: order,
                        onTap: () => showOrderDetailSheet(context, order),
                        action: ApproveOrderButton(order: order),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessage(BuildContext context, IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.bodyMedium(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
