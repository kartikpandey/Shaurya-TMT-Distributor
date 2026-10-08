import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../models/cart_item.dart';
import '../../../models/order_target.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common/custom_app_bar.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/custom_card.dart';
import '../../../widgets/orders/order_target_picker.dart';
import '../../../widgets/orders/tonnage_input.dart';
import 'order_success_screen.dart';

class OrderReviewScreen extends StatefulWidget {
  const OrderReviewScreen({super.key});

  @override
  State<OrderReviewScreen> createState() => _OrderReviewScreenState();
}

class _OrderReviewScreenState extends State<OrderReviewScreen> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartProvider>();
    _noteController = TextEditingController(text: cart.note);

    // Sub-dealers can only order for themselves, so skip the picker
    final identity = OrderingIdentity.of(context.read<AuthProvider>());
    if (cart.target == null &&
        identity.role == OrderingRole.subDealer &&
        identity.problem == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => cart.setTarget(identity.self()),
      );
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    final orders = context.read<OrderProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final identity = OrderingIdentity.of(auth);
    final problem = identity.problem;
    if (problem != null) {
      messenger.showSnackBar(SnackBar(content: Text(problem)));
      return;
    }

    final payload = cart.buildOrderPayload(createdById: identity.selfId!);
    final placed = await orders.submitOrder(
      payload: payload,
      token: auth.authToken,
    );
    if (!mounted) return;

    if (!placed) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            orders.submitError ?? 'Could not place order. Please try again.',
          ),
        ),
      );
      return;
    }

    // Refresh dashboard order counts in the background
    context.read<DashboardProvider>().fetchDashboard(
      token: auth.authToken,
      force: true,
    );

    final totalAmount = cart.totalAmount;
    final totalTonnes = cart.totalTonnes;
    cart.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => OrderSuccessScreen(
              orderReference: orders.lastOrderReference,
              totalAmount: totalAmount,
              totalTonnes: totalTonnes,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Review Order'),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) return _buildEmptyCart(context);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTargetCard(context, cart),
              const SizedBox(height: 20),
              Text('Items', style: AppTextStyles.titleLarge(context)),
              const SizedBox(height: 12),
              ...cart.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildLineItem(context, cart, item),
                ),
              ),
              const SizedBox(height: 8),
              Text('Note', style: AppTextStyles.titleLarge(context)),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 3,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'e.g. Urgent delivery for site work',
                ),
                onChanged: cart.setNote,
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer2<CartProvider, OrderProvider>(
        builder: (context, cart, orders, _) {
          if (cart.isEmpty) return const SizedBox.shrink();
          return _buildSubmitBar(context, cart, orders);
        },
      ),
    );
  }

  Widget _buildTargetCard(BuildContext context, CartProvider cart) {
    final target = cart.target;
    final canChange =
        OrderingIdentity.of(context.read<AuthProvider>()).role !=
        OrderingRole.subDealer;
    return CustomCard(
      padding: const EdgeInsets.all(16),
      onTap: canChange ? () => showOrderTargetPicker(context) : null,
      child: Row(
        children: [
          const Icon(Icons.storefront_outlined, color: AppColors.primaryOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ordering for',
                  style: AppTextStyles.labelMedium(
                    context,
                  ).copyWith(color: AppColors.textHint),
                ),
                const SizedBox(height: 4),
                Text(
                  target?.label ?? 'Tap to choose',
                  style: AppTextStyles.titleMedium(context).copyWith(
                    color: target == null ? AppColors.primaryOrange : null,
                  ),
                ),
              ],
            ),
          ),
          if (canChange)
            const Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
    );
  }

  Widget _buildLineItem(
    BuildContext context,
    CartProvider cart,
    CartItem item,
  ) {
    return CustomCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: AppTextStyles.titleMedium(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.grade} · ${AppFormatters.formatCurrency(item.unitPrice)}/t',
                      style: AppTextStyles.bodySmall(context),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppColors.warningRed,
                tooltip: 'Remove',
                onPressed: () => cart.remove(item.productVariantId),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TonnageInput(
                value: item.quantity,
                onChanged:
                    (tonnes) => cart.setQuantity(item.productVariantId, tonnes),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    AppFormatters.formatCurrency(item.lineTotal),
                    style: AppTextStyles.titleMedium(
                      context,
                    ).copyWith(color: AppColors.primaryOrange),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitBar(
    BuildContext context,
    CartProvider cart,
    OrderProvider orders,
  ) {
    final error = cart.validationError;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: const Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${cart.itemCount} items · ${TonnageInput.format(cart.totalTonnes)} t',
                    style: AppTextStyles.bodyMedium(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      AppFormatters.formatCurrency(cart.totalAmount),
                      style: AppTextStyles.titleLarge(context),
                    ),
                  ),
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error,
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(color: AppColors.warningRed),
              ),
            ],
            const SizedBox(height: 12),
            CustomButton(
              label: 'Place Order',
              icon: Icons.check_circle_outline,
              isEnabled: cart.canSubmit,
              isLoading: orders.isSubmitting,
              onPressed: _placeOrder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Your order is empty',
            style: AppTextStyles.titleMedium(context),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Browse products'),
          ),
        ],
      ),
    );
  }
}
