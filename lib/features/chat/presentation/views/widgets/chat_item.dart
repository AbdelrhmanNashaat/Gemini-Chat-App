import 'package:chat_bot_gemini/features/chat/presentation/manager/chat_cubit/chat_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_text_styles.dart';
import '../../../data/models/chat_message_model.dart';
import 'custom_error_widget.dart';
import 'loading_widget.dart';

class ChatItem extends StatelessWidget {
  const ChatItem({
    super.key,
    required this.chatModel,
    this.isLoading = false,
    required this.chatCubit,
    this.errorMessage = '',
  });

  final ChatMessageModel chatModel;
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
        if (!isUser)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.smart_toy,
                color: AppColors.whiteColor,
                size: 20,
              ),
            ),
          ),
        SizedBox(width: isUser ? 0 : 4),
        Flexible(
          child: Container(
            width: isLoading ? 60 : null,
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
                : GestureDetector(
                    onLongPress: () {
                      const ClipboardData(text: 'Copied Message');
                    },
                    child: Text(
                      chatModel.message,
                      style: AppTextStyles.text13Bold.copyWith(
                        color: textColor,
                        fontWeight: isUser ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
