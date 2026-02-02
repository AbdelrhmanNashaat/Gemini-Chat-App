import 'package:chat_bot_gemini/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets.dart';
import 'custom_nav_button.dart';

class OnBoardingViewBody extends StatelessWidget {
  const OnBoardingViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        children: [
          SizedBox(height: size.height * 0.06),
          Text(
            'You AI Assistant',
            style: AppTextStyles.heading23Bold.copyWith(
              color: AppColors.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: size.height * 0.01),
          Text(
            'Using this software,you can ask you questions and receive articles using artificial intelligence assistant',
            textAlign: TextAlign.center,
            style: AppTextStyles.text15Medium.copyWith(
              color: AppColors.onBoardingTextColor,
            ),
          ),
          const Spacer(),
          Image.asset(Assets.assetsImagesOnBoardingImage),
          const Spacer(),
          const CustomNavButton(),
          SizedBox(height: size.height * 0.04),
        ],
      ),
    );
  }
}
