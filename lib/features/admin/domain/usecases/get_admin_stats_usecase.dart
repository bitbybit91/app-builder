import '../entities/admin_stats.dart';
import '../repositories/admin_repository.dart';

class GetAdminStatsUseCase {
  final AdminRepository _repository;
  GetAdminStatsUseCase(this._repository);

  Future<AdminStats> call() {
    return _repository.getStats();
  }
}
