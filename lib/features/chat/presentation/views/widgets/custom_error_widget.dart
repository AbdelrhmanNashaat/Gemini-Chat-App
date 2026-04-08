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
        Text(
          'Something went wrong',
          style: AppTextStyles.text14Bold.copyWith(color: AppColors.whiteColor),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.whiteColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                errorMessage,
                style: AppTextStyles.text13Bold.copyWith(
                  color: AppColors.whiteColor.withOpacity(.92),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onResend,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.whiteColor,
            backgroundColor: AppColors.whiteColor.withOpacity(.16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.whiteColor.withOpacity(.24)),
            ),
          ),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(
            'Resend',
            style: AppTextStyles.text13Bold.copyWith(
              color: AppColors.whiteColor,
            ),
          ),
        ),
      ],
    );
  }
}
