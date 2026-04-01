import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';

class MessagingRemoteDataSource {
  final ApiClient _apiClient;
  MessagingRemoteDataSource(this._apiClient);

  Future<List<ConversationModel>> getConversations({int page = 1}) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.conversations, queryParameters: {'page': page});
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      return list.map((json) => ConversationModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ServerException(message: 'Failed to fetch conversations: ${e.toString()}');
    }
  }

  Future<List<MessageModel>> getMessages(String conversationId, {int page = 1}) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.messages}/$conversationId',
        queryParameters: {'page': page},
      );
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      return list.map((json) => MessageModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ServerException(message: 'Failed to fetch messages: ${e.toString()}');
    }
  }

  Future<MessageModel> sendMessage(String conversationId, String content, {bool encrypt = false}) async {
    try {
      final response = await _apiClient.post(
        '${ApiEndpoints.messages}/$conversationId',
        data: {'content': content, 'is_encrypted': encrypt},
      );
      return MessageModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Failed to send message: ${e.toString()}');
    }
  }

  Future<void> markAsRead(String conversationId) async {
    try {
      await _apiClient.post('${ApiEndpoints.conversations}/$conversationId/read');
    } catch (e) {
      throw ServerException(message: 'Failed to mark as read: ${e.toString()}');
    }
  }
}
