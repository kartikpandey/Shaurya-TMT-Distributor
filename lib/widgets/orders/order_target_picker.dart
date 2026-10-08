import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../models/network_member.dart';
import '../../models/order_target.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/dashboard_provider.dart';

/// The logged-in user's ordering role and id, or a reason they can't order
class OrderingIdentity {
  final OrderingRole? role;
  final int? selfId;
  final String name;

  const OrderingIdentity._(this.role, this.selfId, this.name);

  factory OrderingIdentity.of(AuthProvider auth) => OrderingIdentity._(
    OrderingRole.fromUserType(auth.userTypeId),
    int.tryParse(auth.currentUser?.id ?? ''),
    auth.currentUser?.name ?? 'Me',
  );

  String? get problem {
    if (role == null) return 'Your account type cannot place orders.';
    if (selfId == null) {
      return 'Your account id is missing. Please log in again.';
    }
    return null;
  }

  OrderTarget self() => OrderTarget.resolve(
    role: role!,
    selfId: selfId!,
    label: 'Myself ($name)',
  );

  OrderTarget child(NetworkMember member) => OrderTarget.resolve(
    role: role!,
    selfId: selfId!,
    childId: member.id,
    label: member.name,
  );

  // What this user's children are called
  String get childrenLabel =>
      role == OrderingRole.distributor ? 'Your dealers' : 'Your sub-dealers';
}

/// Bottom sheet for choosing who the order in the cart is for
Future<void> showOrderTargetPicker(BuildContext context) {
  final auth = context.read<AuthProvider>();
  final identity = OrderingIdentity.of(auth);

  // Children come from the dashboard; load them if the home screen hasn't
  if (identity.role != OrderingRole.subDealer) {
    context.read<DashboardProvider>().fetchDashboard(token: auth.authToken);
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder:
        (sheetContext) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder:
              (sheetContext, scrollController) => _OrderTargetSheet(
                identity: identity,
                token: auth.authToken,
                scrollController: scrollController,
              ),
        ),
  );
}

class _OrderTargetSheet extends StatelessWidget {
  final OrderingIdentity identity;
  final String? token;
  final ScrollController scrollController;

  const _OrderTargetSheet({
    required this.identity,
    required this.token,
    required this.scrollController,
  });

  void _choose(BuildContext context, OrderTarget target) {
    context.read<CartProvider>().setTarget(target);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final problem = identity.problem;
    final selected = context.watch<CartProvider>().target;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Text('Order for', style: AppTextStyles.headlineSmall(context)),
        const SizedBox(height: 16),
        if (problem != null)
          Text(problem, style: AppTextStyles.bodyMedium(context))
        else ...[
          _tile(
            context,
            icon: Icons.person_outline,
            title: 'Myself',
            subtitle: identity.name,
            isSelected: selected?.customerId == identity.selfId,
            onTap: () => _choose(context, identity.self()),
          ),
          if (identity.role != OrderingRole.subDealer) ...[
            const SizedBox(height: 20),
            Text(
              identity.childrenLabel,
              style: AppTextStyles.titleMedium(context),
            ),
            const SizedBox(height: 8),
            _buildChildren(context, selected),
          ],
        ],
      ],
    );
  }

  Widget _buildChildren(BuildContext context, OrderTarget? selected) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        if (dashboard.isLoading && !dashboard.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (dashboard.errorMessage != null && !dashboard.hasData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dashboard.errorMessage!,
                style: AppTextStyles.bodyMedium(context),
              ),
              TextButton(
                onPressed:
                    () => dashboard.fetchDashboard(token: token, force: true),
                child: const Text('Retry'),
              ),
            ],
          );
        }

        // The dealer list can include the user themselves; "Myself" covers it
        final children =
            dashboard.children.where((c) => c.id != identity.selfId).toList();
        if (children.isEmpty) {
          return Text(
            'No one is linked to your account yet.',
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textHint),
          );
        }

        return Column(
          children:
              children
                  .map(
                    (member) => _tile(
                      context,
                      icon: Icons.storefront_outlined,
                      title: member.name,
                      subtitle: member.store ?? member.phone,
                      isSelected: selected?.customerId == member.id,
                      onTap: () => _choose(context, identity.child(member)),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, color: AppColors.primaryOrange),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing:
          isSelected
              ? const Icon(Icons.check_circle, color: AppColors.primaryOrange)
              : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}
