import 'package:chat_bot_gemini/core/utils/assets.dart';
import 'package:chat_bot_gemini/features/chat/presentation/manager/chat_cubit/chat_cubit.dart';
import 'package:flutter/material.dart';

import '../../../data/models/initial_item_model.dart';
import 'initial_chat_widget.dart';

class InitialListOfQuestions extends StatefulWidget {
  const InitialListOfQuestions({super.key, required this.chatCubit});
  final ChatCubit chatCubit;

  @override
  State<InitialListOfQuestions> createState() => _InitialListOfQuestionsState();
}

class _InitialListOfQuestionsState extends State<InitialListOfQuestions> {
  String? selectedQuestion;

  final List<InitialItemModel> items = [
    InitialItemModel(
      imagePath: Assets.assetsImagesExplainSvg,
      title: 'Explain',
      subTitle1: 'Explain Quantum physics',
      subTitle2: 'What are wormholes explain like i am 5',
    ),
    InitialItemModel(
      imagePath: Assets.assetsImagesEditSvg,
      title: 'Write & edit',
      subTitle1: 'Write a tweet about global warming',
      subTitle2: 'Write a rap song lyrics about',
    ),
    InitialItemModel(
      imagePath: Assets.assetsImagesTranslate,
      title: 'Translate',
      subTitle1: 'How do you say “how are you” in korean?',
      subTitle2: 'Write a poem about flower and love',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = items[index];
        return InitialChatWidget(
          items: item,
          selectedQuestion: selectedQuestion,
          onQuestionTap: (question) {
            setState(() {
              selectedQuestion = question;
            });
            widget.chatCubit.userMessage.text = question;
          },
        );
      }, childCount: items.length),
    );
  }
}
