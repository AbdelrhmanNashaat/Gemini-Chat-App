import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/repos/chat_repo.dart';
import 'chat_state.dart';
import 'package:flutter/widgets.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({required this.chatRepo}) : super(const ChatCubitInitial());

  final ChatRepo chatRepo;
  final TextEditingController messageController = TextEditingController();

  String _lastUserMessage = '';

  Future<void> sendQuestion({bool isRetry = false}) async {
    final currentMessages = List<ChatModel>.from(state.messages);

    // 1️⃣ Determine message
    final userMessage = isRetry
        ? _lastUserMessage
        : messageController.text.trim();

    if (userMessage.isEmpty) return;

    if (!isRetry) {
      _lastUserMessage = userMessage;
      currentMessages.add(ChatModel(role: 'user', message: userMessage));
      messageController.clear();
    }

    int botIndex = currentMessages.lastIndexWhere(
      (m) => m.role == 'bot' && m.message.isEmpty,
    );

    if (botIndex == -1) {
      currentMessages.add(ChatModel(role: 'bot', message: ''));
      botIndex = currentMessages.length - 1;
    }

    emit(ChatCubitLoading(messages: currentMessages));

    final response = await chatRepo.sendMessage(message: userMessage);

    response.fold(
      (failure) {
        emit(
          ChatCubitError(
            messages: currentMessages,
            errorMessage: failure.errorMessage,
          ),
        );
      },
      (botMessage) {
        currentMessages[botIndex] = ChatModel(role: 'bot', message: botMessage);
        emit(ChatCubitSuccess(messages: currentMessages));
      },
    );
  }
}
