import 'package:flutter/material.dart';
import 'package:capitalmonero_app/config/app_theme.dart';
import 'package:capitalmonero_app/models/offer.dart';
import 'package:capitalmonero_app/widgets/crypto_icon.dart';

class OfferCard extends StatelessWidget {
  final Offer offer;
  final VoidCallback? onTap;

  const OfferCard({super.key, required this.offer, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isBuy = offer.type == 'buy';
    final typeColor = isBuy ? AppColors.success : AppColors.danger;
    final typeLabel = isBuy ? 'BUY' : 'SELL';

    final priceDisplay = offer.priceType == 'margin'
        ? '+${offer.priceMargin?.toStringAsFixed(2) ?? '0.00'}% Market'
        : '${offer.fiatCurrency} ${offer.fixedPrice?.toStringAsFixed(2) ?? '0.00'}';

    final trader = offer.user;

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
                  // BUY/SELL badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      typeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CryptoIcon(crypto: offer.crypto, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    offer.crypto,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    priceDisplay,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.payment, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    offer.paymentMethod,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.swap_vert, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${offer.fiatCurrency} ${offer.minAmount.toStringAsFixed(0)} – ${offer.maxAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (trader != null) ...[
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.accent,
                      child: Text(
                        trader.username.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      trader.username,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${trader.completedTrades} trades',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.thumb_up_outlined, size: 12, color: AppColors.success),
                    const SizedBox(width: 2),
                    Text(
                      '${trader.feedbackScore.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const Spacer(),
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(isBuy ? 'Sell' : 'Buy'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
