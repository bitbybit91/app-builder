import '../../../auth/domain/entities/user.dart';
import '../../../trading/domain/entities/offer.dart';
import '../../../trading/domain/entities/trade.dart';
import '../../domain/repositories/admin_repository.dart';

abstract class AdminRemoteDataSource {
  Future<List<User>> users();
  Future<List<Trade>> disputes();
  Future<List<Offer>> reportedOffers();
  Future<PlatformStats> stats();
  Future<void> moderateUser(String username, UserModerationAction action);
  Future<void> resolveDispute(String tradeId, bool forBuyer);
}

class InMemoryAdminDataSource implements AdminRemoteDataSource {
  final Map<String, UserModerationAction> _moderation =
      <String, UserModerationAction>{};

  @override
  Future<List<User>> users() async {
    final DateTime now = DateTime.now();
    return <User>[
      User(
        id: 'u-satoshi',
        username: 'satoshi',
        role: UserRole.user,
        createdAt: now.subtract(const Duration(days: 1500)),
        tradeCount: 312,
        feedbackScore: 99,
      ),
      User(
        id: 'u-alice',
        username: 'alice',
        role: UserRole.user,
        createdAt: now.subtract(const Duration(days: 220)),
        tradeCount: 47,
        feedbackScore: 100,
      ),
      User(
        id: 'u-mallory',
        username: 'mallory',
        role: UserRole.user,
        createdAt: now.subtract(const Duration(days: 12)),
        tradeCount: 1,
        feedbackScore: 0,
      ),
    ];
  }

  @override
  Future<List<Trade>> disputes() async => <Trade>[];

  @override
  Future<List<Offer>> reportedOffers() async => <Offer>[];

  @override
  Future<PlatformStats> stats() async {
    return const PlatformStats(
      totalUsers: 12421,
      activeOffers: 318,
      openTrades: 47,
      openDisputes: 3,
      weeklyVolumeUsd: 482310.12,
    );
  }

  @override
  Future<void> moderateUser(String username, UserModerationAction action) async {
    _moderation[username] = action;
  }

  @override
  Future<void> resolveDispute(String tradeId, bool forBuyer) async {
    // Stub: in production this would call the backend escrow service.
  }
}
