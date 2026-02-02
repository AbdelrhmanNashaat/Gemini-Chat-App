import 'package:chat_bot_gemini/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ClickableImage extends StatelessWidget {
  const ClickableImage({
    super.key,
    required this.imagePath,
    required this.onTap,
    this.hasQuestion = false,
  });
  final String imagePath;
  final VoidCallback onTap;
  final bool hasQuestion;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SvgPicture.asset(
        imagePath,
        colorFilter: ColorFilter.mode(
          hasQuestion ? AppColors.primaryColor : const Color(0xffCECECE),
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
