import 'package:chat_bot_gemini/features/chat/presentation/manager/chat_cubit/chat_cubit.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_text_styles.dart';

class CustomErrorWidget extends StatelessWidget {
  const CustomErrorWidget({
    super.key,
    required this.errorMessage,
    required this.chatCubit,
  });
  final String errorMessage;
  final ChatCubit chatCubit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.whiteColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              errorMessage,
              style: AppTextStyles.text13Bold.copyWith(
                color: AppColors.whiteColor,
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.whiteColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              chatCubit.sendQuestion(isRetry: true);
            },
            label: Text(
              'Retry',
              style: AppTextStyles.text14Bold.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
            icon: const Icon(
              Icons.refresh,
              color: AppColors.primaryColor,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
