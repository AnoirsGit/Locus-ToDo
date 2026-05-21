import 'package:dio/dio.dart';
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
      final (user, accessToken, refreshToken) =
          await ref.read(authApiProvider).login(email, password);
      await ref.read(secureStorageProvider).saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      return user;
    });
  }

  Future<void> register(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final (user, accessToken, refreshToken) =
          await ref.read(authApiProvider).register(email, password);
      await ref.read(secureStorageProvider).saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      return user;
    });
  }

  Future<void> logout() async {
    final storage = ref.read(secureStorageProvider);
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        final dio = ref.read(dioProvider);
        await dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      } on DioException catch (_) {
        // Best-effort revocation — clear locally regardless
      }
    }
    await storage.clearTokens();
    state = const AsyncData(null);
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(() => AuthNotifier());
