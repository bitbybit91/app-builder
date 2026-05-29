import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/message.dart';

abstract class MessagingRepository {
  Future<Either<Failure, List<Conversation>>> conversations();
  Future<Either<Failure, List<DirectMessage>>> thread(String peerUsername);
  Future<Either<Failure, DirectMessage>> send({
    required String fromUsername,
    required String toUsername,
    required String body,
    bool encrypted = false,
  });
}
