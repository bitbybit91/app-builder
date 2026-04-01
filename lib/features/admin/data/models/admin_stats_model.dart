import '../../domain/entities/admin_stats.dart';

class AdminStatsModel extends AdminStats {
  const AdminStatsModel({
    required super.totalUsers,
    required super.activeUsers,
    required super.totalTrades,
    required super.activeTrades,
    required super.openDisputes,
    required super.totalOffers,
    required super.totalVolume,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminStatsModel(
      totalUsers: json['total_users'] as int,
      activeUsers: json['active_users'] as int,
      totalTrades: json['total_trades'] as int,
      activeTrades: json['active_trades'] as int,
      openDisputes: json['open_disputes'] as int,
      totalOffers: json['total_offers'] as int,
      totalVolume: (json['total_volume'] as num).toDouble(),
    );
  }
}
