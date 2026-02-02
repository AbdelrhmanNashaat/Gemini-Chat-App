import 'package:chat_bot_gemini/core/utils/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
          Image.asset(Assets.assetsImagesRobot),
          const SizedBox(width: 16),
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
