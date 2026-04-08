import 'package:flutter/material.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_text_styles.dart';

class CustomErrorWidget extends StatelessWidget {
  const CustomErrorWidget({
    super.key,
    required this.errorMessage,
    required this.onResend,
  });

  final String errorMessage;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row: icon + title ──────────────────────────────
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.whiteColor.withValues(alpha: .18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.whiteColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Something went wrong',
              style: AppTextStyles.text14Bold.copyWith(
                color: AppColors.whiteColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ── Error detail message ──────────────────────────────────
        Text(
          errorMessage,
          style: AppTextStyles.text13Bold.copyWith(
            color: AppColors.whiteColor.withValues(alpha: .85),
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 14),

        // ── Resend button ─────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('resend_button'),
            onPressed: onResend,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.whiteColor,
              side: BorderSide(
                color: AppColors.whiteColor.withValues(alpha: .5),
                width: 1.2,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: Text(
              'Try again',
              style: AppTextStyles.text13Bold.copyWith(
                color: AppColors.whiteColor,
                letterSpacing: .3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
