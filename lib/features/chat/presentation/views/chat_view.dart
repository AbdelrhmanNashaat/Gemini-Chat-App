import 'package:chat_bot_gemini/core/services/api_service.dart';
import 'package:chat_bot_gemini/core/services/gemini_chat_service.dart';
import 'package:chat_bot_gemini/features/chat/data/repos/chat_repo_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../manager/chat_cubit/chat_cubit.dart';
import 'widgets/chat_view_body.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocProvider(
          create: (context) => ChatCubit(
            chatRepo: ChatRepoImpl(
              geminiChatService: GeminiChatService(
                apiService: ApiService(dio: Dio()),
              ),
            ),
          ),
          child: const ChatViewBody(),
        ),
      ),
    );
  }
}
