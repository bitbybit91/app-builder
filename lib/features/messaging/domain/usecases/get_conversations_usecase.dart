import '../entities/conversation.dart';
import '../repositories/messaging_repository.dart';

class GetConversationsUseCase {
  final MessagingRepository _repository;
  GetConversationsUseCase(this._repository);

  Future<List<Conversation>> call({int page = 1}) {
    return _repository.getConversations(page: page);
  }
}
