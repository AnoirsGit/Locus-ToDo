import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../entities/user/user.dart';
import '../../shared/api/auth_api.dart';
import '../../shared/api/api_client.dart';

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final storage = ref.watch(secureStorageProvider);
    final token = await storage.getAccessToken();
    if (token == null) return null;
    try {
      return await ref.read(authApiProvider).me();
    } catch (_) {
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
    state = const AsyncData(null);
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(() => AuthNotifier());
