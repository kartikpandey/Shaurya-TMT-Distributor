import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/reward_provider.dart';
import '../../widgets/common/custom_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Profile', showBackButton: false),
      body: SingleChildScrollView(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final user = authProvider.currentUser;
            return Column(
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(24),
                  color: AppColors.primaryOrange.withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              user?.name[0] ?? 'U',
                              style: AppTextStyles.displayLarge(
                                context,
                              ).copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              user?.name ?? 'User',
                              style: AppTextStyles.headlineMedium(context),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.companyName ?? 'Distributor',
                              style: AppTextStyles.bodyMedium(
                                context,
                              ).copyWith(color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Profile Details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Information',
                        style: AppTextStyles.headlineSmall(context),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailField(
                        context,
                        'Email',
                        user?.email ?? 'N/A',
                        Icons.email_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailField(
                        context,
                        'Phone',
                        user?.phoneNumber ?? 'N/A',
                        Icons.phone_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailField(
                        context,
                        'Location',
                        user?.location ?? 'N/A',
                        Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailField(
                        context,
                        'User Type',
                        user?.userType ?? 'N/A',
                        Icons.business_outlined,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Settings Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: AppTextStyles.headlineSmall(context),
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsTile(
                        context,
                        'Notifications',
                        'Manage notifications',
                        Icons.notifications_outlined,
                      ),
                      const SizedBox(height: 8),
                      _buildSettingsTile(
                        context,
                        'Security',
                        'Password and security',
                        Icons.lock_outlined,
                      ),
                      const SizedBox(height: 8),
                      _buildSettingsTile(
                        context,
                        'Help & Support',
                        'Contact support',
                        Icons.help_outline,
                      ),
                      const SizedBox(height: 8),
                      _buildSettingsTile(
                        context,
                        'About',
                        'App version and info',
                        Icons.info_outline,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Don't carry this user's data over to the next user
                        context.read<CartProvider>().clear();
                        context.read<OrderProvider>().clear();
                        context.read<DashboardProvider>().clear();
                        context.read<RewardProvider>().clearLedger();
                        authProvider.logout();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logged out successfully'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warningRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailField(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall(
                    context,
                  ).copyWith(color: AppColors.textHint),
                ),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.bodyMedium(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryOrange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleMedium(context)),
                    Text(
                      subtitle,
                      style: AppTextStyles.labelSmall(
                        context,
                      ).copyWith(color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
