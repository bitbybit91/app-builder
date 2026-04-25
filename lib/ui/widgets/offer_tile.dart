import 'package:flutter/material.dart';

enum OfferType { buy, sell }

class OfferTile extends StatelessWidget {
  final OfferType type;
  final String currency;
  final String fiatCurrency;
  final double minAmount;
  final double maxAmount;
  final double price;
  final String paymentMethod;
  final String traderName;
  final double reputationScore;
  final VoidCallback onTap;

  const OfferTile({
    super.key,
    required this.type,
    required this.currency,
    required this.fiatCurrency,
    required this.minAmount,
    required this.maxAmount,
    required this.price,
    required this.paymentMethod,
    required this.traderName,
    required this.reputationScore,
    required this.onTap,
  });

  Color _typeColor(BuildContext context) =>
      type == OfferType.buy ? Colors.green.shade600 : Colors.red.shade600;

  String get _typeLabel => type == OfferType.buy ? 'BUY' : 'SELL';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final typeColor = _typeColor(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _typeLabel,
                  style: textTheme.labelMedium?.copyWith(
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Main info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          traderName,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade600),
                        const SizedBox(width: 2),
                        Text(
                          reputationScore.toStringAsFixed(1),
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Price: ${price.toStringAsFixed(2)} $fiatCurrency',
                      style: textTheme.bodySmall?.copyWith(
                        color: typeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Limits: ${minAmount.toStringAsFixed(2)} – ${maxAmount.toStringAsFixed(2)} $fiatCurrency',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Chip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      label: Text(paymentMethod),
                      labelStyle: textTheme.labelSmall,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              // Currency label
              Text(
                currency,
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
