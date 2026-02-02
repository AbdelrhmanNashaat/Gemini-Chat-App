import 'package:go_router/go_router.dart';

import '../../features/chat/presentation/views/chat_view.dart';
import '../../features/splash/presentation/views/on_boarding_view.dart';
import '../../features/splash/presentation/views/splash_view.dart';

abstract class AppRoutes {
  static const String kSplashRoute = '/';
  static const String kOnBoardingRoute = '/onBoarding';
  static const String kChatRoute = '/chat';
  static final router = GoRouter(
    routes: [
      GoRoute(
        path: kSplashRoute,
        builder: (context, state) => const SplashView(),
      ),
      GoRoute(
        path: kOnBoardingRoute,
        builder: (context, state) => const OnBoardingView(),
      ),
      GoRoute(path: kChatRoute, builder: (context, state) => const ChatView()),
    ],
  );
}
