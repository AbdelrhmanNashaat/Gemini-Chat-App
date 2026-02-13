import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../domain/chat_repo.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({required this.chatRepo}) : super(ChatCubitInitial());

  final ChatRepo chatRepo;

  final List<ChatMessageModel> _messages = [];

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  final userMessage = TextEditingController();
  Future<void> sendQuestion() async {
    _messages.add(
      ChatMessageModel(message: userMessage.text.trim(), role: 'user'),
    );

    emit(ChatCubitLoading());

    final response = await chatRepo.sendMessage(messages: _messages);

    response.fold(
      (failure) {
        emit(ChatCubitError(errorMessage: failure.errorMessage));
      },
      (botMessage) {
        _messages.add(ChatMessageModel(message: botMessage, role: 'model'));

        emit(ChatCubitSuccess());
      },
    );
  }
}
