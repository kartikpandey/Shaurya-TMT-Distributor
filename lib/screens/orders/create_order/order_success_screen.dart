import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/orders/tonnage_input.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String? orderReference;
  final double totalAmount;
  final double totalTonnes;

  const OrderSuccessScreen({
    super.key,
    this.orderReference,
    required this.totalAmount,
    required this.totalTonnes,
  });

  // Return to the main navigation, dropping the catalog and review screens
  void _backToHome(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToHome(context);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 88,
                  color: AppColors.successGreen,
                ),
                const SizedBox(height: 24),
                Text(
                  'Order placed',
                  style: AppTextStyles.headlineMedium(context),
                ),
                const SizedBox(height: 8),
                if (orderReference != null)
                  Text(
                    'Order $orderReference',
                    style: AppTextStyles.titleMedium(context),
                  ),
                const SizedBox(height: 16),
                Text(
                  '${TonnageInput.format(totalTonnes)} t · '
                  '${AppFormatters.formatCurrency(totalAmount)}',
                  style: AppTextStyles.bodyLarge(context),
                ),
                const SizedBox(height: 40),
                CustomButton(
                  label: 'Back to Home',
                  onPressed: () => _backToHome(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
