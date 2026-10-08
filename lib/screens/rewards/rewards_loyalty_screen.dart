import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../models/reward_ledger.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reward_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../utils/formatters.dart';

class RewardsLoyaltyScreen extends StatefulWidget {
  const RewardsLoyaltyScreen({super.key});

  @override
  State<RewardsLoyaltyScreen> createState() => _RewardsLoyaltyScreenState();
}

class _RewardsLoyaltyScreenState extends State<RewardsLoyaltyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load after the first frame: providers notify listeners as they load,
    // which isn't allowed while this screen is still building
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RewardProvider>().fetchRewards();
      _loadLedger();
    });
  }

  Future<void> _loadLedger() {
    return context.read<RewardProvider>().fetchLedger(
      token: context.read<AuthProvider>().authToken,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Rewards & Loyalty',
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Balance Card
            Consumer<RewardProvider>(
              builder: (context, rewardProvider, _) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.premiumGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Super Coins Balance',
                          style: AppTextStyles.bodyLarge(
                            context,
                          ).copyWith(color: Colors.white.withOpacity(0.9)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            rewardProvider.isLedgerLoading &&
                                    rewardProvider.ledger == null
                                ? const SizedBox(
                                  height: 40,
                                  width: 40,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  // Total current reward points
                                  rewardProvider.ledger != null
                                      ? '${rewardProvider.ledger!.balance}'
                                      : '—',
                                  style: AppTextStyles.displayLarge(
                                    context,
                                  ).copyWith(color: Colors.white),
                                ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Redeem Now',
                                style: AppTextStyles.labelMedium(
                                  context,
                                ).copyWith(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildBalanceInfo(
                              'Total Earned',
                              '${rewardProvider.ledger?.totalEarned ?? '—'}',
                            ),
                            _buildBalanceInfo(
                              'Redeemed',
                              '${rewardProvider.ledger?.totalRedeemed ?? '—'}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Earn Steps Guide
            _buildEarnStepsGuide(context),

            // Tabs
            Container(
              margin: const EdgeInsets.only(top: 24),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primaryOrange,
                    unselectedLabelColor: AppColors.textHint,
                    indicatorColor: AppColors.primaryOrange,
                    tabs: const [
                      Tab(text: 'Earned'),
                      Tab(text: 'Redeem'),
                      Tab(text: 'Activity'),
                    ],
                  ),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildEarnedTab(context),
                        _buildRedeemTab(context),
                        _buildActivityTab(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall(
            context,
          ).copyWith(color: Colors.white.withOpacity(0.7)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.titleMedium(
            context,
          ).copyWith(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildEarnStepsGuide(BuildContext context) {
    return Consumer<RewardProvider>(
      builder: (context, rewardProvider, _) {
        final steps = rewardProvider.getEarnSteps();
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to Earn Super Coins',
                style: AppTextStyles.headlineSmall(context),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: steps.length,
                  itemBuilder: (context, index) {
                    final step = steps[index];
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color:
                                  step.isCompleted
                                      ? AppColors.successGreen
                                      : AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${step.stepNumber}',
                                style: AppTextStyles.titleMedium(
                                  context,
                                ).copyWith(
                                  color:
                                      step.isCompleted
                                          ? Colors.white
                                          : AppColors.textHint,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step.title,
                            style: AppTextStyles.labelSmall(context),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEarnedTab(BuildContext context) {
    return Consumer<RewardProvider>(
      builder: (context, rewardProvider, _) {
        final earned = rewardProvider.earnedRewards;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: earned.length,
          itemBuilder: (context, index) {
            final reward = earned[index];
            return _buildRewardItem(context, reward);
          },
        );
      },
    );
  }

  Widget _buildRedeemTab(BuildContext context) {
    return Consumer<RewardProvider>(
      builder: (context, rewardProvider, _) {
        final redeemable = rewardProvider.getRedeemableRewards();
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: redeemable.length,
          itemBuilder: (context, index) {
            final reward = redeemable[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reward.title,
                              style: AppTextStyles.titleMedium(context),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reward.description,
                              style: AppTextStyles.bodySmall(
                                context,
                              ).copyWith(color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${reward.pointsRequired} coins',
                          style: AppTextStyles.labelMedium(context).copyWith(
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        rewardProvider.redeemReward(reward.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${reward.title} redeemed!'),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );
                      },
                      child: const Text('Redeem'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Reward ledger: every super-coin credit and debit, newest first
  Widget _buildActivityTab(BuildContext context) {
    return Consumer<RewardProvider>(
      builder: (context, rewardProvider, _) {
        final ledger = rewardProvider.ledger;

        if (rewardProvider.isLedgerLoading && ledger == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ledger == null) {
          return _buildLedgerMessage(
            context,
            Icons.cloud_off,
            rewardProvider.ledgerError ?? 'Unable to load reward ledger.',
            showRetry: true,
          );
        }
        if (ledger.entries.isEmpty) {
          return _buildLedgerMessage(
            context,
            Icons.receipt_long_outlined,
            'No reward activity yet',
          );
        }

        return RefreshIndicator(
          onRefresh: _loadLedger,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: ledger.entries.length,
            separatorBuilder:
                (_, __) =>
                    const Divider(height: 1, color: AppColors.borderLight),
            itemBuilder:
                (context, index) => _buildLedgerRow(context, ledger, index),
          ),
        );
      },
    );
  }

  Widget _buildLedgerRow(BuildContext context, RewardLedger ledger, int index) {
    final entry = ledger.entries[index];
    final color =
        entry.isCredit ? AppColors.successGreen : AppColors.warningRed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              entry.isCredit ? Icons.south_west : Icons.north_east,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description,
                  style: AppTextStyles.titleSmall(context),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (entry.orderId != null) entry.orderId!,
                    if (entry.date != null)
                      AppFormatters.formatDateTime(entry.date!),
                  ].join(' · '),
                  style: AppTextStyles.labelSmall(
                    context,
                  ).copyWith(color: AppColors.textHint),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.isCredit ? '+' : '−'}${entry.coins}',
                style: AppTextStyles.titleMedium(
                  context,
                ).copyWith(color: color, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                'Bal ${ledger.balanceAfter(index)}',
                style: AppTextStyles.labelSmall(
                  context,
                ).copyWith(color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerMessage(
    BuildContext context,
    IconData icon,
    String message, {
    bool showRetry = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.bodyMedium(context),
              textAlign: TextAlign.center,
            ),
            if (showRetry)
              TextButton.icon(
                onPressed: _loadLedger,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardItem(BuildContext context, dynamic reward) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.title, style: AppTextStyles.titleMedium(context)),
                const SizedBox(height: 4),
                Text(
                  reward.description,
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.textHint),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${reward.pointsValue}',
              style: AppTextStyles.labelMedium(context).copyWith(
                color: AppColors.successGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
