import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required ProfileDataSource source}) : _source = source;
  final ProfileDataSource _source;

  @override
  Future<Either<Failure, User>> publicProfile(String username) async {
    try {
      return Right<Failure, User>(await _source.publicProfile(username));
    } on NotFoundException catch (e) {
      return Left<Failure, User>(NotFoundFailure(e.message));
    } catch (e) {
      return Left<Failure, User>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Feedback>>> feedback(String username) async {
    try {
      return Right<Failure, List<Feedback>>(await _source.feedback(username));
    } catch (e) {
      return Left<Failure, List<Feedback>>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> update(User user) async {
    try {
      return Right<Failure, User>(await _source.update(user));
    } catch (e) {
      return Left<Failure, User>(UnexpectedFailure(e.toString()));
    }
  }
}
