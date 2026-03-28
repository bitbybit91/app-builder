import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:capitalmonero_app/config/app_theme.dart';
import 'package:capitalmonero_app/models/trade.dart';
import 'package:capitalmonero_app/widgets/trade_status_badge.dart';

class TradeCard extends StatelessWidget {
  final Trade trade;
  final int currentUserId;
  final VoidCallback? onTap;

  const TradeCard({
    super.key,
    required this.trade,
    required this.currentUserId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isBuyer = trade.buyerId == currentUserId;
    final roleLabel = isBuyer ? 'BUYER' : 'SELLER';
    final roleColor = isBuyer ? Colors.blue : Colors.orange;

    final counterparty = isBuyer ? trade.seller : trade.buyer;
    final counterpartyName = counterparty?.username ?? 'Unknown';

    final shortId = trade.tradeId.length >= 8
        ? trade.tradeId.substring(0, 8)
        : trade.tradeId;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '#$shortId',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: roleColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      roleLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TradeStatusBadge(status: trade.status),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    counterpartyName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${trade.cryptoAmount.toStringAsFixed(8)} ${trade.crypto}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '≈ ${trade.fiatCurrency} ${trade.fiatAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                timeago.format(trade.createdAt),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
