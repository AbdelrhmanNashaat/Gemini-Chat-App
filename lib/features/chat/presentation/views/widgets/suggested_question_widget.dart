import 'package:flutter/material.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_text_styles.dart';

class SuggestedQuestionWidget extends StatelessWidget {
  const SuggestedQuestionWidget({
    super.key,
    required this.title,
    this.borderColor = AppColors.containerColor,
    required this.onTap,
  });
  final String title;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 0.8),
          color: AppColors.containerColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: AppTextStyles.text14Medium.copyWith(
              color: AppColors.textColor2,
            ),
          ),
        ),
      ),
    );
  }
}
