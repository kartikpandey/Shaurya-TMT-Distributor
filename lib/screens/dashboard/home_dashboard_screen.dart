import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../models/dashboard_model.dart';
import '../../models/order_target.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/dashboard/dealer_card.dart';
import '../../widgets/dashboard/greeting_card.dart';
import '../../widgets/dashboard/kpi_card.dart';
import '../../widgets/dashboard/order_summary_card.dart';
import '../../widgets/orders/order_detail_sheet.dart';
import '../../widgets/orders/order_target_picker.dart';
import '../navigation/main_navigation_screen.dart';
import '../orders/awaiting_approval_screen.dart';
import 'product_listing_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboard());
  }

  // Load dashboard summary and orders using the token captured at login
  Future<void> _loadDashboard({bool force = false}) async {
    final token = context.read<AuthProvider>().authToken;
    await Future.wait([
      context.read<DashboardProvider>().fetchDashboard(
        token: token,
        force: force,
      ),
      context.read<OrderProvider>().fetchOrders(token: token),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadDashboard(force: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting Card
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      final user = authProvider.currentUser;
                      if (user == null) return const SizedBox.shrink();
                      return GreetingCard(user: user, isOnline: true);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Dashboard Summary
                  _buildDashboardSection(context),
                  const SizedBox(height: 24),

                  // Dealers
                  _buildDealersSection(context),
                  const SizedBox(height: 24),

                  // Recent Orders Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Recent Orders',
                          style: AppTextStyles.headlineSmall(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed:
                            () => MainNavigationScreen.selectTab(
                              context,
                              MainNavigationScreen.ordersTab,
                            ),
                        child: Text(
                          'View All',
                          style: AppTextStyles.labelMedium(
                            context,
                          ).copyWith(color: AppColors.primaryOrange),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildRecentOrders(context),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNewOrder(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Dashboard summary: loading, error, or live data
  Widget _buildDashboardSection(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, _) {
        final summary = dashboardProvider.summary;

        if (summary == null) {
          if (dashboardProvider.isLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _buildErrorCard(context, dashboardProvider.errorMessage);
        }

        return _buildKPISummary(context, summary);
      },
    );
  }

  // KPI grid: order pipeline from the dashboard API, plus this month's
  // order value and the user's active children
  Widget _buildKPISummary(BuildContext context, DashboardSummary summary) {
    final total = summary.totalOrders;

    // Share of the pipeline, used for the progress bars
    double share(int value) => total == 0 ? 0 : value / total;

    final orders = context.watch<OrderProvider>();
    final awaiting = orders.awaitingApproval.length;
    final identity = OrderingIdentity.of(context.read<AuthProvider>());
    final childCount = _children(context).length;

    final tiles = [
      KPICard(
        title: 'Open Orders',
        value: '${summary.openOrders}',
        subtitle: 'In progress',
        icon: Icons.shopping_bag_outlined,
        accentColor: AppColors.primaryOrange,
        progress: share(summary.openOrders),
      ),
      KPICard(
        title: 'Approved',
        value: '${summary.approvedOrders}',
        subtitle:
            awaiting == 0
                ? 'None awaiting approval'
                : '$awaiting awaiting approval',
        icon: Icons.verified_outlined,
        accentColor: AppColors.successGreen,
        progress: share(summary.approvedOrders),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AwaitingApprovalScreen()),
            ),
      ),
      KPICard(
        title: 'Order Value',
        value: AppFormatters.formatCurrency(orders.currentMonthOrderValue),
        subtitle: AppFormatters.formatDate(AppFormatters.nowIst(), 'MMMM yyyy'),
        svgAsset: 'assets/images/kpi_order_value.svg',
        accentColor: AppColors.accentBlue,
      ),
      KPICard(
        title:
            identity.role == OrderingRole.distributor
                ? 'Active Dealers'
                : 'Active Sub-dealers',
        value: '$childCount',
        subtitle: 'Linked to your account',
        svgAsset: 'assets/images/kpi_network.svg',
        accentColor: const Color(0xFF7C3AED),
      ),
    ];

    // Two rows sized to their content, so tiles never clip at small widths
    // or large font sizes
    Widget row(Widget a, Widget b) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      ),
    );

    return Column(
      children: [
        row(tiles[0], tiles[1]),
        const SizedBox(height: 12),
        row(tiles[2], tiles[3]),
      ],
    );
  }

  // The user's direct children, without the user themselves (the dashboard
  // list can include them)
  List<Map<String, dynamic>> _children(BuildContext context) {
    final selfId = OrderingIdentity.of(context.read<AuthProvider>()).selfId;
    return context
        .read<DashboardProvider>()
        .dealers
        .where((d) => '${d['id']}' != '$selfId')
        .toList();
  }

  // Latest five orders, newest first
  Widget _buildRecentOrders(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (orderProvider.orders.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                orderProvider.errorMessage ?? 'No orders yet',
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.textHint),
              ),
            ),
          );
        }

        return Column(
          children:
              orderProvider
                  .recentOrders()
                  .map(
                    (order) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OrderSummaryCard(
                        order: order,
                        onTap: () => showOrderDetailSheet(context, order),
                      ),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }

  // Dealers list from the API
  Widget _buildDealersSection(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, _) {
        final dealers = _children(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Dealers', style: AppTextStyles.headlineSmall(context)),
                Text(
                  '${dealers.length}',
                  style: AppTextStyles.labelMedium(
                    context,
                  ).copyWith(color: AppColors.textHint),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (dealers.isEmpty)
              _buildEmptyDealers(context)
            else
              ...dealers.map(
                (dealer) => DealerCard(
                  dealer: dealer,
                  onTap: () {
                    // Navigate to dealer details
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyDealers(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurface
                : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 32, color: AppColors.textHint),
          const SizedBox(height: 8),
          Text('No dealers yet', style: AppTextStyles.titleSmall(context)),
          const SizedBox(height: 4),
          Text(
            'Dealers will appear here once they are onboarded.',
            style: AppTextStyles.labelSmall(
              context,
            ).copyWith(color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Error state with retry
  Widget _buildErrorCard(BuildContext context, String? message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warningRed.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off, size: 28, color: AppColors.warningRed),
          const SizedBox(height: 8),
          Text(
            message ?? 'Unable to load dashboard.',
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.textDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _loadDashboard(force: true),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Start (or resume) building an order from the product catalog
  void _openNewOrder(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProductListingScreen()),
    );
  }
}
