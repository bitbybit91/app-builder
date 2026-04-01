import 'package:equatable/equatable.dart';

class AdminStats extends Equatable {
  final int totalUsers;
  final int activeUsers;
  final int totalTrades;
  final int activeTrades;
  final int openDisputes;
  final int totalOffers;
  final double totalVolume;

  const AdminStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalTrades,
    required this.activeTrades,
    required this.openDisputes,
    required this.totalOffers,
    required this.totalVolume,
  });

  @override
  List<Object?> get props => [totalUsers, totalTrades, openDisputes];
}
