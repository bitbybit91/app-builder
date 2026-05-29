import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../datasources/messaging_data_source.dart';

class MessagingRepositoryImpl implements MessagingRepository {
  MessagingRepositoryImpl({required MessagingDataSource source})
      : _source = source;
  final MessagingDataSource _source;

  @override
  Future<Either<Failure, List<Conversation>>> conversations() async {
    try {
      return Right<Failure, List<Conversation>>(await _source.conversations());
    } catch (e) {
      return Left<Failure, List<Conversation>>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DirectMessage>>> thread(String peerUsername) async {
    try {
      return Right<Failure, List<DirectMessage>>(
          await _source.thread(peerUsername));
    } catch (e) {
      return Left<Failure, List<DirectMessage>>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DirectMessage>> send({
    required String fromUsername,
    required String toUsername,
    required String body,
    bool encrypted = false,
  }) async {
    try {
      final DirectMessage sent = await _source.send(DirectMessage(
        id: '',
        fromUsername: fromUsername,
        toUsername: toUsername,
        body: body,
        sentAt: DateTime.now(),
        encrypted: encrypted,
      ));
      return Right<Failure, DirectMessage>(sent);
    } catch (e) {
      return Left<Failure, DirectMessage>(UnexpectedFailure(e.toString()));
    }
  }
}
