import 'package:chat_bot_gemini/features/chat/presentation/views/widgets/chat_item.dart';
import 'package:flutter/material.dart';
import '../../../data/models/chat_message_model.dart';
import '../../manager/chat_cubit/chat_cubit.dart';

class ChatListWidget extends StatelessWidget {
  const ChatListWidget({
    super.key,
    required this.messages,
    this.isLoading = false,
    this.errorMessage = '',
    required this.chatCubit,
  });

  final List<ChatMessageModel> messages;
  final bool isLoading;
  final String errorMessage;
  final ChatCubit chatCubit;

  @override
  Widget build(BuildContext context) {
    final reversedMessages = messages.reversed.toList();

    return SliverList.builder(
      itemCount: reversedMessages.length,
      itemBuilder: (context, index) {
        final chat = reversedMessages[index];
        final isLatestMessage = index == 0 && chat.role == 'model';
        return ChatItem(
          chatModel: chat,
          isLoading: isLoading && isLatestMessage,
          errorMessage: errorMessage.isNotEmpty && isLatestMessage
              ? errorMessage
              : '',
          chatCubit: chatCubit,
        );
      },
    );
  }
}
