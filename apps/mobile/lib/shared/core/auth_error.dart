import 'package:dio/dio.dart';

/// Maps a login/register failure to a short, human-readable message.
///
/// Previously both auth pages rendered `error.toString()` directly, which
/// surfaced raw `DioException` internals (e.g. "DioException [bad
/// response]: ...") to the user instead of something actionable.
String formatAuthError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 401) return 'Неверный email или пароль';
    if (status == 409) return 'Пользователь с таким email уже существует';
    if (status == 422 || status == 400) return 'Проверьте правильность введённых данных';
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Нет соединения с сервером';
    }
  }
  return 'Что-то пошло не так. Попробуйте ещё раз';
}
