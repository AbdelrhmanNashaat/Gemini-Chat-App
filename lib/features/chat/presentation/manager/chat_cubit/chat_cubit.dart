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

    messageController.clear();

    final conversation = List<ChatMessageModel>.from(messages)
      ..add(ChatMessageModel(role: 'user', message: userMessage));

    await _requestReply(conversation);
  }

  Future<void> resendLastQuestion() async {
    if (state is! ChatCubitError) return;

    final conversation = _conversationWithoutPendingReply();
    if (conversation.isEmpty || conversation.last.role != 'user') return;

    await _requestReply(conversation);
  }

  Future<void> _requestReply(List<ChatMessageModel> conversation) async {
    messages
      ..clear()
      ..addAll(conversation)
      ..add(ChatMessageModel(role: 'model', message: ''));

    final botIndex = messages.length - 1;

    emit(ChatCubitLoading(messages: List<ChatMessageModel>.from(messages)));

    final response = await chatRepo.sendMessage(
      messages: List<ChatMessageModel>.from(conversation),
    );

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

  List<ChatMessageModel> _conversationWithoutPendingReply() {
    final conversation = List<ChatMessageModel>.from(messages);

    // The trailing empty model item is only a UI placeholder while waiting.
    if (conversation.isNotEmpty &&
        conversation.last.role == 'model' &&
        conversation.last.message.trim().isEmpty) {
      conversation.removeLast();
    }

    return conversation;
  }
}
