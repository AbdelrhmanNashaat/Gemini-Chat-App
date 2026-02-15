import 'package:chat_bot_gemini/core/utils/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/utils/app_colors.dart';
import 'back_arrow_widget.dart';
import 'title_with_online_widget.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key, required this.isOnline});
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const BackArrowButton(),
          const SizedBox(width: 16),
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
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TitleWithOnlineWidget(isOnline: isOnline),
          if (isOnline) ...[
            const Spacer(),
            SvgPicture.asset(Assets.assetsImagesVolumeSvg),
            const SizedBox(width: 16),
            SvgPicture.asset(Assets.assetsImagesExportSvg),
            const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }
}
