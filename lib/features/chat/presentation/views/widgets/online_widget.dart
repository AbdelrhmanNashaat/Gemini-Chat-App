import 'package:flutter/material.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_text_styles.dart';

class CheckInternetAvailabilityWidget extends StatelessWidget {
  const CheckInternetAvailabilityWidget({super.key, required this.isOnline});
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 3.5,
          backgroundColor: isOnline
              ? AppColors.onlineColor
              : AppColors.errorColor,
        ),
        const SizedBox(width: 4),
        Text(
          isOnline ? 'Online' : 'Offline',
          style: AppTextStyles.text17Medium.copyWith(
            color: isOnline ? AppColors.onlineColor : AppColors.errorColor,
          ),
        ),
      ],
    );
  }
}
