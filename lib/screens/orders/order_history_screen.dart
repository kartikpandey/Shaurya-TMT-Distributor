import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../models/distribution_order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/dashboard/order_summary_card.dart';
import '../../widgets/orders/order_detail_sheet.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  static const _allFilter = 'ALL';

  String _selectedFilter = _allFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return context.read<OrderProvider>().fetchOrders(
      token: context.read<AuthProvider>().authToken,
    );
  }

  // Apply the status filter and search text; the list is already newest first
  List<DistributionOrder> _visibleOrders(OrderProvider provider) {
    final query = _searchController.text.trim().toLowerCase();
    return provider.orders.where((order) {
      final statusMatch =
          _selectedFilter == _allFilter || order.status == _selectedFilter;
      final searchMatch =
          query.isEmpty ||
          order.orderId.toLowerCase().contains(query) ||
          order.dealerName.toLowerCase().contains(query);
      return statusMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Order History', showBackButton: false),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          final orders = _visibleOrders(orderProvider);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search order ID or dealer',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                            : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),

                // Filter Chips, from the statuses the backend returned
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(_allFilter, 'All Orders'),
                      for (final status in orderProvider.statuses) ...[
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          status,
                          OrderSummaryCard.statusLabel(status),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

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
                    showRetry: true,
                  )
                else if (orders.isEmpty)
                  _buildMessage(
                    context,
                    Icons.receipt_long_outlined,
                    orderProvider.orders.isEmpty
                        ? 'No orders yet'
                        : 'No orders match your filters',
                  )
                else
                  ...orders.map(
                    (order) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OrderSummaryCard(
                        order: order,
                        onTap: () => showOrderDetailSheet(context, order),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      backgroundColor: AppColors.primaryLight,
      selectedColor: AppColors.primaryOrange.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? AppColors.primaryOrange : AppColors.textHint,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? AppColors.primaryOrange : AppColors.borderLight,
        ),
      ),
    );
  }

  Widget _buildMessage(
    BuildContext context,
    IconData icon,
    String message, {
    bool showRetry = false,
  }) {
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
          if (showRetry) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
