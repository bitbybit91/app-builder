import '../entities/message.dart';
import '../entities/conversation.dart';

abstract class MessagingRepository {
  Future<List<Conversation>> getConversations({int page = 1});
  Future<List<Message>> getMessages(String conversationId, {int page = 1});
  Future<Message> sendMessage(String conversationId, String content, {bool encrypt = false});
  Future<void> markAsRead(String conversationId);
  Future<Conversation> createConversation(String userId);
}
