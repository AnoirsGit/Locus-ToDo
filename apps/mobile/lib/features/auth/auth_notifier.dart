import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../entities/user/user.dart';
import '../../shared/api/auth_api.dart';
import '../../shared/api/api_client.dart';

part 'auth_notifier.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<User?> build() async {
    final storage = ref.watch(secureStorageProvider);
    final token = await storage.getAccessToken();
    
    if (token == null) return null;

    try {
      return await ref.read(authApiProvider).me();
    } catch (e) {
      await storage.clearTokens();
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final (user, token) = await ref.read(authApiProvider).login(email, password);
      await ref.read(secureStorageProvider).saveTokens(
        accessToken: token, 
        refreshToken: '', 
      );
      return user;
    });
  }

  Future<void> logout() async {
    await ref.read(secureStorageProvider).clearTokens();
    state = const AsyncValue.data(null);
  }
}
