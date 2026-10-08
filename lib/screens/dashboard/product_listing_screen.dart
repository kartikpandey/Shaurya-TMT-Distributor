import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/dashboard/product_card.dart';
import '../../widgets/orders/tonnage_input.dart';
import '../orders/create_order/order_review_screen.dart';

class ProductListingScreen extends StatefulWidget {
  const ProductListingScreen({super.key});

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  late ScrollController _scrollController;
  bool _showFilterBar = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 50) {
      if (_showFilterBar) {
        setState(() => _showFilterBar = false);
      }
    } else {
      if (!_showFilterBar) {
        setState(() => _showFilterBar = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Products'),
      bottomNavigationBar: _buildCartBar(context),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          return Column(
            children: [
              // Filter Bar
              if (_showFilterBar) _buildFilterBar(context, productProvider),

              // Products Grid
              Expanded(
                child:
                    productProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : productProvider.products.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No products found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                        : GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                // Fixed height: a ratio made cards too short
                                // on narrow phones
                                mainAxisExtent: 270,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: productProvider.products.length,
                          itemBuilder: (context, index) {
                            final product = productProvider.products[index];
                            return ProductCard(
                              product: product,
                              onAddToCart: () {
                                _showAddToCartDialog(context, product);
                              },
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    ProductProvider productProvider,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: AppTextStyles.titleMedium(
              context,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  'Grade',
                  productProvider.getAvailableGrades(),
                  productProvider.selectedGrade,
                  (selected) {
                    productProvider.filterProducts(
                      grade: selected,
                      size: productProvider.selectedSize,
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Size',
                  productProvider.getAvailableSizes(),
                  productProvider.selectedSize,
                  (selected) {
                    productProvider.filterProducts(
                      grade: productProvider.selectedGrade,
                      size: selected,
                    );
                  },
                ),
                const SizedBox(width: 8),
                if (productProvider.selectedGrade != 'All' ||
                    productProvider.selectedSize != 'All')
                  TextButton.icon(
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear'),
                    onPressed: () => productProvider.resetFilters(),
                  ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            child: Text(
              'Showing ${productProvider.products.length} products',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    List<String> options,
    String selected,
    Function(String) onSelected,
  ) {
    return Wrap(
      spacing: 4,
      children:
          options
              .map(
                (option) => FilterChip(
                  label: Text(option),
                  selected: selected == option,
                  onSelected: (isSelected) {
                    if (isSelected) {
                      onSelected(option);
                    }
                  },
                  backgroundColor: AppColors.primaryLight,
                  selectedColor: AppColors.primaryOrange.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color:
                        selected == option
                            ? AppColors.primaryOrange
                            : AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color:
                          selected == option
                              ? AppColors.primaryOrange
                              : AppColors.borderLight,
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  void _showAddToCartDialog(BuildContext context, ProductModel product) {
    double quantity = 1;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(product.name),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grade: ${product.grade}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Price per tonne: ${AppFormatters.formatCurrency(product.unitPrice)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Quantity (tonnes):'),
                  const SizedBox(height: 8),
                  TonnageInput(
                    value: quantity,
                    onChanged: (tonnes) => setState(() => quantity = tonnes),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:'),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              AppFormatters.formatCurrency(
                                product.unitPrice * quantity,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.read<CartProvider>().add(product, quantity);
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${product.name} (${TonnageInput.format(quantity)} t) added to order',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Add to Order'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Sticky summary of the order being built, linking to the review screen
  Widget _buildCartBar(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        if (cart.isEmpty) return const SizedBox.shrink();
        return SafeArea(
          child: Material(
            color: AppColors.primaryOrange,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderReviewScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${cart.itemCount} items · '
                        '${TonnageInput.format(cart.totalTonnes)} t · '
                        '${AppFormatters.formatCurrency(cart.totalAmount)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Text(
                      'Review',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
