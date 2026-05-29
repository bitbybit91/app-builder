import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../trading/domain/entities/offer.dart';
import '../../../trading/domain/entities/trade.dart';

class PlatformStats {
  const PlatformStats({
    required this.totalUsers,
    required this.activeOffers,
    required this.openTrades,
    required this.openDisputes,
    required this.weeklyVolumeUsd,
  });
  final int totalUsers;
  final int activeOffers;
  final int openTrades;
  final int openDisputes;
  final double weeklyVolumeUsd;
}

enum UserModerationAction { ban, warn, verify }

abstract class AdminRepository {
  Future<Either<Failure, List<User>>> listUsers();
  Future<Either<Failure, List<Trade>>> listDisputes();
  Future<Either<Failure, List<Offer>>> reportedOffers();
  Future<Either<Failure, PlatformStats>> stats();
  Future<Either<Failure, Unit>> moderateUser({
    required String username,
    required UserModerationAction action,
  });
  Future<Either<Failure, Unit>> resolveDispute({
    required String tradeId,
    required bool forBuyer,
  });
}
