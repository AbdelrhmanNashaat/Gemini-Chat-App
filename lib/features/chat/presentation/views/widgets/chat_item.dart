import 'package:chat_bot_gemini/core/utils/assets.dart';
import 'package:chat_bot_gemini/features/chat/data/models/chat_model.dart';
import 'package:chat_bot_gemini/features/chat/presentation/manager/chat_cubit/chat_cubit.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_text_styles.dart';
import 'custom_error_widget.dart';

class ChatItem extends StatelessWidget {
  const ChatItem({
    super.key,
    required this.chatModel,
    this.isLoading = false,
    required this.chatCubit,
    this.errorMessage = '',
  });

  final ChatModel chatModel;
  final bool isLoading;
  final String errorMessage;
  final ChatCubit chatCubit;

  @override
  Widget build(BuildContext context) {
    final bool isUser = chatModel.role == 'user';
    const double radius = 36;

    final Color backgroundColor = errorMessage.isNotEmpty
        ? AppColors.errorColor
        : (isUser ? AppColors.primaryColor : AppColors.chatBotItemColor);

    final Color textColor = errorMessage.isNotEmpty
        ? AppColors.whiteColor
        : (isUser ? AppColors.whiteColor : AppColors.chatBotItemTextColor);
    final bool hasError = errorMessage.isNotEmpty;

    return Row(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisAlignment: isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!isUser) Image.asset(Assets.assetsImagesRobot),
        SizedBox(width: isUser ? 0 : 8),
        Container(
          constraints: isLoading ? null : const BoxConstraints(maxWidth: 345),
          padding: isLoading
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
              : const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(radius),
              topRight: Radius.circular(isUser ? 0 : radius),
              bottomLeft: Radius.circular(isUser ? radius : 0),
              bottomRight: const Radius.circular(radius),
            ),
          ),
          child: isLoading
              ? const CustomLoadingWidget()
              : hasError
              ? CustomErrorWidget(
                  errorMessage: errorMessage,
                  chatCubit: chatCubit,
                )
              : Text(
                  chatModel.message,
                  style: AppTextStyles.text13Bold.copyWith(
                    color: textColor,
                    fontWeight: isUser ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
        ),
      ],
    );
  }
}

class CustomLoadingWidget extends StatelessWidget {
  const CustomLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 24,
      child: Center(
        child: LoadingIndicator(
          indicatorType: Indicator.ballPulse,
          colors: [AppColors.primaryColor],
          strokeWidth: 3,
        ),
      ),
    );
  }
}
