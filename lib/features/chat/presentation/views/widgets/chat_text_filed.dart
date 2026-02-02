import 'package:chat_bot_gemini/core/utils/app_colors.dart';
import 'package:chat_bot_gemini/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';
import '../../manager/chat_cubit/chat_cubit.dart';
import 'suffix_icons_row.dart';

class ChatTextFiled extends StatelessWidget {
  const ChatTextFiled({
    super.key,
    required this.controller,
    required this.chatCubit,
  });

  final TextEditingController controller;
  final ChatCubit chatCubit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [
          BoxShadow(
            color: AppColors.boxShadowColor,
            offset: Offset(5, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40, maxHeight: 150),
        child: Scrollbar(
          child: TextFormField(
            controller: controller,
            style: AppTextStyles.text14Medium.copyWith(
              color: AppColors.textColor2,
            ),
            minLines: 1,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  return SuffixIconsRow(
                    hasQuestion: value.text.isNotEmpty,
                    chatCubit: chatCubit,
                  );
                },
              ),
              hintText: 'Write your message',
              hintStyle: AppTextStyles.text14Bold.copyWith(
                color: AppColors.textFiledHintTextColor,
                fontSize: 13,
              ),
              border: borderMethod(),
              enabledBorder: borderMethod(),
              focusedBorder: borderMethod(),
              fillColor: AppColors.whiteColor,
              filled: true,
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder borderMethod() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide.none,
    );
  }
}
