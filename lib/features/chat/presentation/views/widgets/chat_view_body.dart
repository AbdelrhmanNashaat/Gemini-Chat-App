import 'package:chat_bot_gemini/core/utils/app_colors.dart';
import 'package:chat_bot_gemini/features/chat/presentation/views/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'chat_bloc_consumer_widget.dart';

class ChatViewBody extends StatelessWidget {
  const ChatViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return StreamBuilder<InternetStatus>(
      stream: InternetConnection().onStatusChange,
      builder: (context, snapshot) {
        final isChecking = snapshot.connectionState == ConnectionState.waiting;
        final isOnline = snapshot.data == InternetStatus.connected;

        return Column(
          children: [
            SizedBox(height: size.height * 0.02),
            CustomAppBar(isOnline: isChecking ? true : isOnline),
            SizedBox(height: size.height * 0.01),
            const Divider(color: AppColors.dividerColor),
            SizedBox(height: size.height * 0.02),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ChatBlocConsumerWidget(
                  isOnline: isChecking ? true : isOnline,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
