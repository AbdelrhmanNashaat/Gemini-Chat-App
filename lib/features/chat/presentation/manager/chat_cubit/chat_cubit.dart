import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../domain/chat_repo.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({required this.chatRepo}) : super(const ChatCubitInitial());

  final ChatRepo chatRepo;
  final TextEditingController messageController = TextEditingController();

  final List<ChatMessageModel> messages = [];

  Future<void> sendQuestion() async {
    final userMessage = messageController.text.trim();
    if (userMessage.isEmpty) return;

    messages.add(ChatMessageModel(role: 'user', message: userMessage));
    messageController.clear();

    messages.add(ChatMessageModel(role: 'model', message: ''));
    final botIndex = messages.length - 1;

    emit(ChatCubitLoading(messages: List<ChatMessageModel>.from(messages)));

    final response = await chatRepo.sendMessage(messages: messages);

    response.fold(
      (failure) {
        emit(
          ChatCubitError(
            messages: List<ChatMessageModel>.from(messages),
            errorMessage: failure.errorMessage,
          ),
        );
      },
      (botMessage) {
        messages[botIndex] = ChatMessageModel(
          role: 'model',
          message: botMessage,
        );
        emit(ChatCubitSuccess(messages: List<ChatMessageModel>.from(messages)));
      },
    );
  }
}
