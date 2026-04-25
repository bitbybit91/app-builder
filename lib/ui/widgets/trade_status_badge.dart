import 'package:flutter/material.dart';

enum TradeStatus { open, active, escrow, complete, dispute, cancelled }

extension _TradeStatusDisplay on TradeStatus {
  String get label => switch (this) {
        TradeStatus.open => 'Open',
        TradeStatus.active => 'Active',
        TradeStatus.escrow => 'Escrow',
        TradeStatus.complete => 'Complete',
        TradeStatus.dispute => 'Dispute',
        TradeStatus.cancelled => 'Cancelled',
      };

  Color get color => switch (this) {
        TradeStatus.open => Colors.blue.shade600,
        TradeStatus.active => Colors.orange.shade600,
        TradeStatus.escrow => Colors.purple.shade600,
        TradeStatus.complete => Colors.green.shade600,
        TradeStatus.dispute => Colors.red.shade600,
        TradeStatus.cancelled => Colors.grey.shade600,
      };
}

class TradeStatusBadge extends StatelessWidget {
  final String status;

  const TradeStatusBadge({super.key, required this.status});

  TradeStatus _parse() => switch (status.toLowerCase()) {
        'open' => TradeStatus.open,
        'active' => TradeStatus.active,
        'escrow' => TradeStatus.escrow,
        'complete' => TradeStatus.complete,
        'dispute' => TradeStatus.dispute,
        'cancelled' || 'canceled' => TradeStatus.cancelled,
        _ => TradeStatus.open,
      };

  @override
  Widget build(BuildContext context) {
    final parsed = _parse();
    final color = parsed.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        parsed.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
      ),
    );
  }
}
