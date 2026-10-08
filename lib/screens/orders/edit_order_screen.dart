import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants/product_catalog.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../models/cart_item.dart';
import '../../models/distribution_order.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/orders/tonnage_input.dart';

/// Edit an unapproved order's products and note. Saving replaces the order's
/// lines with exactly what is on this screen.
class EditOrderScreen extends StatelessWidget {
  final DistributionOrder order;

  const EditOrderScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // A cart of its own, so editing never touches a new order in progress
    return ChangeNotifierProvider(
      create: (_) => _prefilledCart(order),
      child: _EditOrderView(order: order),
    );
  }

  static CartProvider _prefilledCart(DistributionOrder order) {
    final cart = CartProvider();
    for (final line in order.lines) {
      cart.add(
        _productFor(line.productVariantId, line.unitPrice),
        line.quantity,
      );
    }
    cart.setNote(order.note ?? '');
    return cart;
  }

  // Catalog details for a variant id, keeping the order's own unit price
  static ProductModel _productFor(int variantId, double unitPrice) {
    final variant = ProductCatalog.variants.where(
      (v) => v.variantId == variantId,
    );
    final v = variant.isEmpty ? null : variant.first;
    return ProductModel(
      variantId: variantId,
      name: v?.name ?? 'Variant #$variantId',
      size: v?.size ?? '',
      grade: v?.grade ?? '',
      quantity: 0,
      unitPrice: unitPrice,
      totalPrice: 0,
    );
  }
}

class _EditOrderView extends StatefulWidget {
  final DistributionOrder order;

  const _EditOrderView({required this.order});

  @override
  State<_EditOrderView> createState() => _EditOrderViewState();
}

class _EditOrderViewState extends State<_EditOrderView> {
  late final TextEditingController _noteController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(
      text: context.read<CartProvider>().note,
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final cart = context.read<CartProvider>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _saving = true);
    final error = await context.read<OrderProvider>().editOrder(
      payload: cart.buildEditPayload(orderId: widget.order.orderId),
      token: context.read<AuthProvider>().authToken,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? '${widget.order.orderId} updated'),
        backgroundColor: error == null ? AppColors.successGreen : null,
      ),
    );
    if (error == null) Navigator.pop(context);
  }

  // Pick a catalog product to add at 1 t (merges into an existing line)
  Future<void> _addProduct() async {
    final cart = context.read<CartProvider>();
    final variant = await showModalBottomSheet<CatalogVariant>(
      context: context,
      isScrollControlled: true,
      builder:
          (sheetContext) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            builder:
                (sheetContext, controller) => ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Add product',
                      style: AppTextStyles.headlineSmall(sheetContext),
                    ),
                    const SizedBox(height: 8),
                    ...ProductCatalog.variants.map(
                      (v) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(v.name),
                        subtitle: Text(v.grade),
                        trailing: Text(
                          '${AppFormatters.formatCurrency(v.pricePerTonne)}/t',
                        ),
                        onTap: () => Navigator.pop(sheetContext, v),
                      ),
                    ),
                  ],
                ),
          ),
    );
    if (variant == null) return;

    cart.add(
      ProductModel(
        variantId: variant.variantId,
        name: variant.name,
        size: variant.size,
        grade: variant.grade,
        quantity: 0,
        unitPrice: variant.pricePerTonne,
        totalPrice: 0,
      ),
      1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Edit ${widget.order.orderId}'),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.order.lines.isEmpty) _buildMissingLinesNotice(context),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Items', style: AppTextStyles.titleLarge(context)),
                  TextButton.icon(
                    onPressed: _addProduct,
                    icon: const Icon(Icons.add),
                    label: const Text('Add product'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (cart.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No products. Add at least one to save.',
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: AppColors.textHint),
                    textAlign: TextAlign.center,
                  ),
                )
              else
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
                  hintText: 'e.g. Updated delivery note',
                ),
                onChanged: cart.setNote,
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder:
            (context, cart, _) => SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: const Border(
                    top: BorderSide(color: AppColors.borderLight),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${cart.itemCount} items · '
                            '${TonnageInput.format(cart.totalTonnes)} t',
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
                    const SizedBox(height: 12),
                    CustomButton(
                      label: 'Save Changes',
                      icon: Icons.save_outlined,
                      isEnabled: !cart.isEmpty,
                      isLoading: _saving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  // The order list API doesn't send product lines yet, so the form can't
  // show what the order currently contains
  Widget _buildMissingLinesNotice(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "This order's current products couldn't be loaded. Add every "
              'product it should contain — saving replaces all its items.',
              style: AppTextStyles.bodySmall(context),
            ),
          ),
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
                      [
                        if (item.grade.isNotEmpty) item.grade,
                        '${AppFormatters.formatCurrency(item.unitPrice)}/t',
                      ].join(' · '),
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
}
