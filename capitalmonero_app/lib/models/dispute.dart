import 'user.dart';
import 'trade.dart';

class Dispute {
  final int id;
  final int tradeId;
  final int openedBy;
  final int? resolvedBy;
  final int? assignedTo;
  final String reason;
  final String? evidenceText;
  final String? resolution;
  final String? resolutionNotes;
  final String status;
  final DateTime? resolvedAt;
  final Trade? trade;
  final User? opener;
  final DateTime createdAt;

  const Dispute({
    required this.id,
    required this.tradeId,
    required this.openedBy,
    this.resolvedBy,
    this.assignedTo,
    required this.reason,
    this.evidenceText,
    this.resolution,
    this.resolutionNotes,
    required this.status,
    this.resolvedAt,
    this.trade,
    this.opener,
    required this.createdAt,
  });

  factory Dispute.fromJson(Map<String, dynamic> json) {
    return Dispute(
      id: json['id'] as int,
      tradeId: json['trade_id'] as int,
      openedBy: json['opened_by'] as int,
      resolvedBy: json['resolved_by'] as int?,
      assignedTo: json['assigned_to'] as int?,
      reason: json['reason'] as String,
      evidenceText: json['evidence_text'] as String?,
      resolution: json['resolution'] as String?,
      resolutionNotes: json['resolution_notes'] as String?,
      status: json['status'] as String,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      trade: json['trade'] != null
          ? Trade.fromJson(json['trade'] as Map<String, dynamic>)
          : null,
      opener: json['opener'] != null
          ? User.fromJson(json['opener'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trade_id': tradeId,
      'opened_by': openedBy,
      'resolved_by': resolvedBy,
      'assigned_to': assignedTo,
      'reason': reason,
      'evidence_text': evidenceText,
      'resolution': resolution,
      'resolution_notes': resolutionNotes,
      'status': status,
      'resolved_at': resolvedAt?.toIso8601String(),
      'trade': trade?.toJson(),
      'opener': opener?.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Dispute copyWith({
    int? id,
    int? tradeId,
    int? openedBy,
    int? resolvedBy,
    int? assignedTo,
    String? reason,
    String? evidenceText,
    String? resolution,
    String? resolutionNotes,
    String? status,
    DateTime? resolvedAt,
    Trade? trade,
    User? opener,
    DateTime? createdAt,
  }) {
    return Dispute(
      id: id ?? this.id,
      tradeId: tradeId ?? this.tradeId,
      openedBy: openedBy ?? this.openedBy,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      assignedTo: assignedTo ?? this.assignedTo,
      reason: reason ?? this.reason,
      evidenceText: evidenceText ?? this.evidenceText,
      resolution: resolution ?? this.resolution,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      status: status ?? this.status,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      trade: trade ?? this.trade,
      opener: opener ?? this.opener,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Dispute && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Dispute(id: $id, tradeId: $tradeId, status: $status)';
}
