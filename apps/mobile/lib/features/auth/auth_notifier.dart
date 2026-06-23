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
      final user = await ref.read(authApiProvider).me();
      await storage.saveUser(user.toJson());
      return user;
    } on DioException catch (e) {
      // Genuine auth failure (refresh already failed in the interceptor) →
      // sign out. Any other error (server down, no network) → stay signed in
      // with the cached profile so the app keeps working offline / read-only.
      if (e.response?.statusCode == 401) {
        await storage.clearTokens();
        await storage.clearUser();
        return null;
      }
      final cached = await storage.getUser();
      return cached != null ? User.fromJson(cached) : null;
    } catch (_) {
      final cached = await storage.getUser();
      return cached != null ? User.fromJson(cached) : null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final (user, accessToken, refreshToken) =
          await ref.read(authApiProvider).login(email, password);
      final storage = ref.read(secureStorageProvider);
      await storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      await storage.saveUser(user.toJson());
      return user;
    });
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final (user, accessToken, refreshToken) =
          await ref.read(authApiProvider).register(name, email, password);
      final storage = ref.read(secureStorageProvider);
      await storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      await storage.saveUser(user.toJson());
      return user;
    });
  }

  Future<void> updateProfile({String? name, String? email}) async {
    final updated = await ref.read(authApiProvider).updateProfile(name: name, email: email);
    await ref.read(secureStorageProvider).saveUser(updated.toJson());
    state = AsyncData(updated);
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
    await storage.clearUser();
    state = const AsyncData(null);
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(() => AuthNotifier());
