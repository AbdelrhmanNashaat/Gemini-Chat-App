import 'package:flutter/material.dart';
import 'core/utils/app_router.dart';

void main() {
  runApp(const ChatBot());
}

class ChatBot extends StatelessWidget {
  const ChatBot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRoutes.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
