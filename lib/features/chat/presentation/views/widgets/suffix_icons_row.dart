import 'package:flutter/material.dart';
import '../../../../../core/utils/assets.dart';
import '../../manager/chat_cubit/chat_cubit.dart';
import 'clickable_image.dart';

class SuffixIconsRow extends StatelessWidget {
  const SuffixIconsRow({
    super.key,
    required this.hasQuestion,
    required this.chatCubit,
  });
  final bool hasQuestion;
  final ChatCubit chatCubit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: Row(
        children: [
          ClickableImage(
            imagePath: Assets.assetsImagesMicrophoneSvg,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          ClickableImage(
            imagePath: Assets.assetsImagesSendMessageArrowSvg,
            onTap: () {
              if (hasQuestion) {
                chatCubit.sendQuestion();
                FocusScope.of(context).unfocus();
              }
            },
            hasQuestion: hasQuestion,
          ),
        ],
      ),
    );
  }
}
