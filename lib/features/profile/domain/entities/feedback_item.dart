import 'package:equatable/equatable.dart';

class FeedbackItem extends Equatable {
  final String id;
  final String fromUsername;
  final String tradeId;
  final bool isPositive;
  final String? comment;
  final DateTime createdAt;

  const FeedbackItem({
    required this.id,
    required this.fromUsername,
    required this.tradeId,
    required this.isPositive,
    this.comment,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, fromUsername, isPositive];
}
