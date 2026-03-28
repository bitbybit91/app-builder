import 'package:flutter/material.dart';
import 'package:capitalmonero_app/config/constants.dart';

class TradeStatusBadge extends StatelessWidget {
  final String status;

  const TradeStatusBadge({super.key, required this.status});

  Color _colorForStatus(String status) {
    switch (status) {
      case TradeStatus.pending:
        return Colors.orange;
      case TradeStatus.funded:
        return Colors.blue;
      case TradeStatus.paymentSent:
        return Colors.deepOrange;
      case TradeStatus.completed:
        return Colors.green;
      case TradeStatus.disputed:
        return Colors.red;
      case TradeStatus.cancelled:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _colorForStatus(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
