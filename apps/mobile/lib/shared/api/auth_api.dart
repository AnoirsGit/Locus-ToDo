import '../../entities/user/user.dart';
import 'api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  Future<(User, String)> login(String email, String password) async {
    final res = await _client.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final user = User.fromJson(res.data['user'] as Map<String, dynamic>);
    final token = res.data['accessToken'] as String;
    return (user, token);
  }

  Future<User> me() async {
    final res = await _client.get('/auth/me');
    return User.fromJson(res.data);
  }
}

final authApiProvider = Provider((ref) => AuthApi(ref.watch(apiClientProvider)));
