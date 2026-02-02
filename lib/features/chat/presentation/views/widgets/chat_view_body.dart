import 'package:chat_bot_gemini/core/utils/app_colors.dart';
import 'package:chat_bot_gemini/features/chat/presentation/views/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'chat_bloc_consumer_widget.dart';

class ChatViewBody extends StatelessWidget {
  const ChatViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return StreamBuilder<InternetConnectionStatus>(
      stream: InternetConnectionChecker.instance.onStatusChange,
      builder: (context, snapshot) {
        final isOnline = snapshot.data == InternetConnectionStatus.connected;
        final isChecking = snapshot.connectionState == ConnectionState.waiting;
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
