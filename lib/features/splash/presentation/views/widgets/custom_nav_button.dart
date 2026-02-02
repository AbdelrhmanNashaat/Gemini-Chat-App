import 'package:chat_bot_gemini/core/utils/app_colors.dart';
import 'package:chat_bot_gemini/core/utils/app_router.dart';
import 'package:chat_bot_gemini/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomNavButton extends StatelessWidget {
  const CustomNavButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.blue,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          GoRouter.of(context).push(AppRoutes.kChatRoute);
        },
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'Continue',
                style: AppTextStyles.text19Bold.copyWith(
                  color: AppColors.whiteColor,
                ),
              ),
              const Positioned(
                right: 12,
                child: Icon(Icons.arrow_forward, color: AppColors.whiteColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
