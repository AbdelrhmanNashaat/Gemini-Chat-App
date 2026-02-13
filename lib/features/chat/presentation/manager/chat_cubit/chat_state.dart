abstract class ChatState {}

final class ChatCubitInitial extends ChatState {}

class ChatCubitLoading extends ChatState {}

class ChatCubitSuccess extends ChatState {}

class ChatCubitError extends ChatState {
  final String errorMessage;

  ChatCubitError({required this.errorMessage});
}
