import 'package:chat_bot_gemini/features/chat/presentation/views/widgets/chat_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../manager/chat_cubit/chat_cubit.dart';
import '../../manager/chat_cubit/chat_state.dart';
import 'chat_text_filed.dart';
import 'initial_list_of_questions.dart';
import 'internet_widget.dart';

class ChatBlocConsumerWidget extends StatelessWidget {
  const ChatBlocConsumerWidget({super.key, required this.isOnline});
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final chatCubit = context.read<ChatCubit>();
    return isOnline
        ? BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              final messages = state.messages;
              return Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      reverse: true,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        if (messages.isEmpty)
                          InitialListOfQuestions(chatCubit: chatCubit)
                        else
                          ChatListWidget(
                            messages: messages,
                            isLoading: state is ChatCubitLoading ? true : false,
                            errorMessage: state is ChatCubitError
                                ? state.errorMessage
                                : '',
                            chatCubit: chatCubit,
                          ),
                      ],
                    ),
                  ),
                  ChatTextFiled(
                    controller: chatCubit.messageController,
                    chatCubit: chatCubit,
                  ),
                ],
              );
            },
          )
        : const NoInternetWidget();
  }
}
