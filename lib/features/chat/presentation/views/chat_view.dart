import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/service_locator.dart';
import '../manager/chat_cubit/chat_cubit.dart';
import 'widgets/chat_view_body.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocProvider(
          create: (context) => getIt<ChatCubit>(),
          child: const ChatViewBody(),
        ),
      ),
    );
  }
}
