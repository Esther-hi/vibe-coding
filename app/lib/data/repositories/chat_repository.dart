import '../datasources/remote/api_client.dart';
import '../../core/config/api_config.dart';

class ChatRepository {
  final ApiClient _apiClient;
  ChatRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> sendMessage({required String message, String? sessionId}) async {
    final response = await _apiClient.post(ApiConfig.chat, data: {
      'message': message,
      if (sessionId != null) 'session_id': sessionId,
    });
    return response.data;
  }
}
