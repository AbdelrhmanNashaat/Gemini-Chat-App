import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../../features/chat/data/repos/gemini_chat_repo_impl.dart';
import '../../features/chat/domain/chat_repo.dart';
import '../../features/chat/presentation/manager/chat_cubit/chat_cubit.dart';
import '../services/api_service.dart';
import '../services/gemini_chat_service.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton(() => Dio());
  getIt.registerLazySingleton(() => ApiService(dio: getIt<Dio>()));
  getIt.registerLazySingleton(
    () => GeminiChatService(apiService: getIt<ApiService>()),
  );
  // Register the concrete implementation under the ChatRepo interface so that
  // tests can replace it with a mock without touching the concrete class.
  getIt.registerLazySingleton<ChatRepo>(
    () => GeminiChatRepoImpl(geminiChatService: getIt<GeminiChatService>()),
  );
  // Resolve ChatRepo (interface) so the mock registered in tests is picked up.
  getIt.registerFactory(() => ChatCubit(chatRepo: getIt<ChatRepo>()));
}
