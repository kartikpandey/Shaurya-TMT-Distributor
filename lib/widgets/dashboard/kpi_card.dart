import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';

class KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  /// SVG asset shown instead of [icon] when set
  final String? svgAsset;
  final Color accentColor;

  /// 0 to 1; null hides the progress bar
  final double? progress;
  final VoidCallback? onTap;

  const KPICard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    this.icon = Icons.insights,
    this.svgAsset,
    required this.accentColor,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        svgAsset != null
                            ? SvgPicture.asset(svgAsset!, width: 24, height: 24)
                            : Icon(icon, color: accentColor, size: 24),
                  ),
                  Icon(
                    onTap != null ? Icons.chevron_right : Icons.trending_up,
                    color: accentColor,
                    size: onTap != null ? 20 : 16,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Value, shrunk to fit long amounts
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: AppTextStyles.numericMedium(context)),
              ),
              const SizedBox(height: 4),

              // Title
              Text(
                title,
                style: AppTextStyles.labelMedium(
                  context,
                ).copyWith(color: AppColors.textHint),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Progress bar
              if (progress != null) ...[
                SizedBox(
                  height: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Subtitle
              Text(
                subtitle,
                style: AppTextStyles.labelSmall(
                  context,
                ).copyWith(color: AppColors.textHint),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
