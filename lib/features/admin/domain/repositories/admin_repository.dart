import '../entities/admin_stats.dart';
import '../../../auth/domain/entities/user.dart';

abstract class AdminRepository {
  Future<AdminStats> getStats();
  Future<List<User>> getUsers({int page = 1, String? search});
  Future<void> banUser(String userId);
  Future<void> unbanUser(String userId);
  Future<void> verifyUser(String userId);
  Future<void> resolveDispute(String disputeId, String resolution);
}
