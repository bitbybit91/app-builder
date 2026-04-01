import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../datasources/messaging_remote_datasource.dart';

class MessagingRepositoryImpl implements MessagingRepository {
  final MessagingRemoteDataSource _remoteDataSource;
  MessagingRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Conversation>> getConversations({int page = 1}) async {
    try {
      return await _remoteDataSource.getConversations(page: page);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<List<Message>> getMessages(String conversationId, {int page = 1}) async {
    try {
      return await _remoteDataSource.getMessages(conversationId, page: page);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<Message> sendMessage(String conversationId, String content, {bool encrypt = false}) async {
    try {
      return await _remoteDataSource.sendMessage(conversationId, content, encrypt: encrypt);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    try {
      await _remoteDataSource.markAsRead(conversationId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<Conversation> createConversation(String userId) async {
    throw ServerFailure(message: 'Not implemented');
  }
}
