import '../../../data/models/chat_model.dart';

abstract class ChatState {
  final List<ChatModel> messages;
  const ChatState({this.messages = const []});
}

class ChatCubitInitial extends ChatState {
  const ChatCubitInitial({super.messages});
}

class ChatCubitLoading extends ChatState {
  const ChatCubitLoading({required super.messages});
}

class ChatCubitSuccess extends ChatState {
  const ChatCubitSuccess({required super.messages});
}

class ChatCubitError extends ChatState {
  final String errorMessage;
  const ChatCubitError({required this.errorMessage, required super.messages});
}
