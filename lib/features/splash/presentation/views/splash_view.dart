import 'package:chat_bot_gemini/core/utils/app_colors.dart';
import 'package:flutter/material.dart';

import 'widgets/splash_view_body.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: SafeArea(child: SplashViewBody()),
    );
  }
}
