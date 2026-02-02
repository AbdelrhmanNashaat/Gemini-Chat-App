import 'package:flutter/material.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_text_styles.dart';
import 'online_widget.dart';

class TitleWithOnlineWidget extends StatelessWidget {
  const TitleWithOnlineWidget({super.key, required this.isOnline});
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ChatGPT',
          style: AppTextStyles.text20Bold.copyWith(
            color: AppColors.primaryColor,
          ),
        ),
        CheckInternetAvailabilityWidget(isOnline: isOnline),
      ],
    );
  }
}
