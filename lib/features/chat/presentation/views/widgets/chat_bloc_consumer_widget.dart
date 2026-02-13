import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../manager/chat_cubit/chat_cubit.dart';
import '../../manager/chat_cubit/chat_state.dart';
import 'chat_list_widget.dart';
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
              return Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      reverse: true,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        if (chatCubit.messages.isEmpty)
                          InitialListOfQuestions(chatCubit: chatCubit)
                        else
                          ChatListWidget(
                            messages: chatCubit.messages,
                            isLoading: state is ChatCubitLoading ? true : false,
                            errorMessage: state is ChatCubitError
                                ? state.errorMessage
                                : '',
                            chatCubit: chatCubit,
                          ),
                      ],
                    ),
                  ),
                  ChatTextFiled(chatCubit: chatCubit),
                ],
              );
            },
          )
        : const NoInternetWidget();
  }
}
