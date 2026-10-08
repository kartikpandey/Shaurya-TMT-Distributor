import 'package:flutter/material.dart';
import '../models/reward_ledger.dart';
import '../models/reward_model.dart';
import '../services/api_service.dart';

class RewardProvider extends ChangeNotifier {
  RewardBalanceModel _balance = RewardBalanceModel(
    totalCoins: 859,
    availableCoins: 859,
    redeemedCoins: 0,
  );

  List<RewardModel> _rewards = [];
  bool _isLoading = false;

  // Live super-coin ledger
  RewardLedger? _ledger;
  bool _isLedgerLoading = false;
  String? _ledgerError;

  // Getters
  RewardBalanceModel get balance => _balance;
  List<RewardModel> get rewards => _rewards;
  List<RewardModel> get earnedRewards =>
      _rewards.where((r) => r.category == 'earn').toList();
  List<RewardModel> get redeemedRewards =>
      _rewards.where((r) => r.category == 'redeem' && r.isRedeemed).toList();
  bool get isLoading => _isLoading;
  RewardLedger? get ledger => _ledger;
  bool get isLedgerLoading => _isLedgerLoading;
  String? get ledgerError => _ledgerError;

  // Load the user's super-coin ledger and current points
  Future<void> fetchLedger({String? token}) async {
    if (_isLedgerLoading) return;

    _isLedgerLoading = true;
    _ledgerError = null;
    notifyListeners();

    try {
      final data = await ApiService.fetchRewardLedger(token: token);
      _ledger = RewardLedger.fromResponse(data);
    } on ApiException catch (e) {
      _ledgerError = e.message;
    } catch (e) {
      _ledgerError = 'Unable to load reward points. Please try again.';
    }

    _isLedgerLoading = false;
    notifyListeners();
  }

  // Forget the previous user's ledger on logout
  void clearLedger() {
    _ledger = null;
    _ledgerError = null;
    notifyListeners();
  }

  RewardProvider() {
    _initializeMockData();
  }

  // Initialize mock data
  void _initializeMockData() {
    _rewards = [
      RewardModel(
        title: 'Welcome Bonus',
        description: 'Sign up bonus for new distributors',
        pointsRequired: 0,
        category: 'earn',
        pointsValue: 100,
        isRedeemed: true,
        date: DateTime.now().subtract(const Duration(days: 30)),
      ),
      RewardModel(
        title: 'First Order',
        description: 'Complete your first order',
        pointsRequired: 0,
        category: 'earn',
        pointsValue: 50,
        isRedeemed: true,
        date: DateTime.now().subtract(const Duration(days: 25)),
      ),
      RewardModel(
        title: 'Bulk Order Bonus',
        description: 'Order above 500 tonnes',
        pointsRequired: 0,
        category: 'earn',
        pointsValue: 200,
        isRedeemed: true,
        date: DateTime.now().subtract(const Duration(days: 10)),
      ),
      RewardModel(
        title: 'On-time Payment',
        description: 'Complete payment within 5 days',
        pointsRequired: 0,
        category: 'earn',
        pointsValue: 75,
        isRedeemed: true,
        date: DateTime.now().subtract(const Duration(days: 5)),
      ),
      RewardModel(
        title: 'Free Consultation',
        description: 'Redeem for a free business consultation',
        pointsRequired: 150,
        category: 'redeem',
        pointsValue: 150,
        isRedeemed: false,
      ),
      RewardModel(
        title: 'Discount Voucher',
        description: '10% discount on next order',
        pointsRequired: 200,
        category: 'redeem',
        pointsValue: 200,
        isRedeemed: false,
      ),
      RewardModel(
        title: 'Premium Support',
        description: '1 month of premium customer support',
        pointsRequired: 300,
        category: 'redeem',
        pointsValue: 300,
        isRedeemed: false,
      ),
      RewardModel(
        title: 'Logistics Credit',
        description: '₹5000 logistics credit',
        pointsRequired: 500,
        category: 'redeem',
        pointsValue: 500,
        isRedeemed: false,
      ),
    ];
  }

  // Fetch rewards
  Future<void> fetchRewards() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Redeem reward
  Future<bool> redeemReward(String rewardId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      final index = _rewards.indexWhere((r) => r.id == rewardId);
      if (index != -1) {
        final reward = _rewards[index];
        if (_balance.availableCoins >= reward.pointsRequired) {
          _rewards[index] = reward.copyWith(isRedeemed: true);

          // Update balance
          _balance = RewardBalanceModel(
            totalCoins: _balance.totalCoins,
            availableCoins: _balance.availableCoins - reward.pointsRequired,
            redeemedCoins: _balance.redeemedCoins + reward.pointsRequired,
          );

          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Add coins
  void addCoins(int coins, String reason) {
    _balance = RewardBalanceModel(
      totalCoins: _balance.totalCoins + coins,
      availableCoins: _balance.availableCoins + coins,
      redeemedCoins: _balance.redeemedCoins,
    );

    _rewards.insert(
      0,
      RewardModel(
        title: reason,
        description: reason,
        pointsRequired: 0,
        category: 'earn',
        pointsValue: coins,
        isRedeemed: true,
      ),
    );

    notifyListeners();
  }

  // Get reward steps for earn guide
  List<RewardStepModel> getEarnSteps() {
    return [
      RewardStepModel(
        stepNumber: 1,
        title: 'Create Account',
        description: 'Sign up and complete verification',
        isCompleted: true,
        iconName: 'user_check',
      ),
      RewardStepModel(
        stepNumber: 2,
        title: 'Place Orders',
        description: 'Make your first order',
        isCompleted: true,
        iconName: 'shopping_cart',
      ),
      RewardStepModel(
        stepNumber: 3,
        title: 'Complete Payment',
        description: 'Pay your invoices on time',
        isCompleted: true,
        iconName: 'credit_card',
      ),
      RewardStepModel(
        stepNumber: 4,
        title: 'Earn Points',
        description: 'Accumulate Super Coins',
        isCompleted: true,
        iconName: 'star',
      ),
      RewardStepModel(
        stepNumber: 5,
        title: 'Redeem Rewards',
        description: 'Exchange coins for benefits',
        isCompleted: false,
        iconName: 'gift',
      ),
    ];
  }

  // Get redeemable rewards (available with current coins)
  List<RewardModel> getRedeemableRewards() {
    return _rewards
        .where(
          (r) =>
              r.category == 'redeem' &&
              r.pointsRequired <= _balance.availableCoins &&
              !r.isRedeemed,
        )
        .toList();
  }
}
