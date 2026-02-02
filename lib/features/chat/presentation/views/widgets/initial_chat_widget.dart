import 'package:chat_bot_gemini/core/utils/app_colors.dart';
import 'package:chat_bot_gemini/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../data/models/initial_item_model.dart';
import 'suggested_question_widget.dart';

class InitialChatWidget extends StatelessWidget {
  const InitialChatWidget({
    super.key,
    required this.items,
    required this.selectedQuestion,
    required this.onQuestionTap,
  });

  final InitialItemModel items;
  final String? selectedQuestion;
  final void Function(String) onQuestionTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset(items.imagePath),
        const SizedBox(height: 6),
        Text(
          items.title,
          style: AppTextStyles.text14Bold.copyWith(color: AppColors.textColor1),
        ),
        const SizedBox(height: 16),
        SuggestedQuestionWidget(
          title: items.subTitle1,
          onTap: () => onQuestionTap(items.subTitle1),
          borderColor: selectedQuestion == items.subTitle1
              ? AppColors.textColor1
              : AppColors.containerColor,
        ),
        SuggestedQuestionWidget(
          title: items.subTitle2,
          onTap: () => onQuestionTap(items.subTitle2),
          borderColor: selectedQuestion == items.subTitle2
              ? AppColors.textColor1
              : AppColors.containerColor,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
