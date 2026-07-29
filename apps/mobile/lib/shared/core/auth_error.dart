import 'package:dio/dio.dart';
import 'strings.dart';

/// Maps a login/register failure to a short, human-readable message.
///
/// Previously both auth pages rendered `error.toString()` directly, which
/// surfaced raw `DioException` internals (e.g. "DioException [bad
/// response]: ...") to the user instead of something actionable.
String formatAuthError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 401) return S.errorInvalidCreds;
    if (status == 409) return S.errorUserExists;
    if (status == 422 || status == 400) return S.errorValidation;
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return S.errorNoConnection;
    }
  }
  return S.errorGeneric;
}
