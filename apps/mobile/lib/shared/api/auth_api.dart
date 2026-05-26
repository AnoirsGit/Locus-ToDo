import '../../entities/user/user.dart';
import 'api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  /// Returns (user, accessToken, refreshToken)
  Future<(User, String, String)> login(String email, String password) async {
    final res = await _client.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final user = User.fromJson(res.data['user'] as Map<String, dynamic>);
    final accessToken = res.data['accessToken'] as String;
    final refreshToken = res.data['refreshToken'] as String;
    return (user, accessToken, refreshToken);
  }

  Future<(User, String, String)> register(String name, String email, String password) async {
    final res = await _client.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    final user = User.fromJson(res.data['user'] as Map<String, dynamic>);
    final accessToken = res.data['accessToken'] as String;
    final refreshToken = res.data['refreshToken'] as String;
    return (user, accessToken, refreshToken);
  }

  Future<User> me() async {
    final res = await _client.get('/auth/me');
    return User.fromJson(res.data);
  }

  Future<User> updateProfile({String? name, String? email}) async {
    final res = await _client.patch('/auth/profile', data: {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
    });
    return User.fromJson(res.data);
  }
}

final authApiProvider = Provider((ref) => AuthApi(ref.watch(apiClientProvider)));
