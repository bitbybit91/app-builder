import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../trading/domain/entities/offer.dart';
import '../../../trading/domain/entities/trade.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl({required AdminRemoteDataSource source}) : _source = source;
  final AdminRemoteDataSource _source;

  @override
  Future<Either<Failure, List<User>>> listUsers() async {
    try {
      return Right<Failure, List<User>>(await _source.users());
    } catch (e) {
      return Left<Failure, List<User>>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Trade>>> listDisputes() async {
    try {
      return Right<Failure, List<Trade>>(await _source.disputes());
    } catch (e) {
      return Left<Failure, List<Trade>>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Offer>>> reportedOffers() async {
    try {
      return Right<Failure, List<Offer>>(await _source.reportedOffers());
    } catch (e) {
      return Left<Failure, List<Offer>>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PlatformStats>> stats() async {
    try {
      return Right<Failure, PlatformStats>(await _source.stats());
    } catch (e) {
      return Left<Failure, PlatformStats>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> moderateUser({
    required String username,
    required UserModerationAction action,
  }) async {
    try {
      await _source.moderateUser(username, action);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> resolveDispute({
    required String tradeId,
    required bool forBuyer,
  }) async {
    try {
      await _source.resolveDispute(tradeId, forBuyer);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(UnexpectedFailure(e.toString()));
    }
  }
}
