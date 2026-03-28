import 'user.dart';

class Review {
  final int id;
  final int tradeId;
  final int reviewerId;
  final int reviewedId;
  final int rating;
  final String? comment;
  final User? reviewer;
  final User? reviewed;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.tradeId,
    required this.reviewerId,
    required this.reviewedId,
    required this.rating,
    this.comment,
    this.reviewer,
    this.reviewed,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int,
      tradeId: json['trade_id'] as int,
      reviewerId: json['reviewer_id'] as int,
      reviewedId: json['reviewed_id'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      reviewer: json['reviewer'] != null
          ? User.fromJson(json['reviewer'] as Map<String, dynamic>)
          : null,
      reviewed: json['reviewed'] != null
          ? User.fromJson(json['reviewed'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trade_id': tradeId,
      'reviewer_id': reviewerId,
      'reviewed_id': reviewedId,
      'rating': rating,
      'comment': comment,
      'reviewer': reviewer?.toJson(),
      'reviewed': reviewed?.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Review copyWith({
    int? id,
    int? tradeId,
    int? reviewerId,
    int? reviewedId,
    int? rating,
    String? comment,
    User? reviewer,
    User? reviewed,
    DateTime? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      tradeId: tradeId ?? this.tradeId,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewedId: reviewedId ?? this.reviewedId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      reviewer: reviewer ?? this.reviewer,
      reviewed: reviewed ?? this.reviewed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Review && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Review(id: $id, tradeId: $tradeId, rating: $rating)';
}
