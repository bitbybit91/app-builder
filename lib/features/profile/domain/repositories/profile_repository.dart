import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user.dart';

class Feedback {
  const Feedback({
    required this.fromUsername,
    required this.positive,
    required this.comment,
    required this.createdAt,
  });
  final String fromUsername;
  final bool positive;
  final String comment;
  final DateTime createdAt;
}

abstract class ProfileRepository {
  Future<Either<Failure, User>> publicProfile(String username);
  Future<Either<Failure, List<Feedback>>> feedback(String username);
  Future<Either<Failure, User>> update(User user);
}
