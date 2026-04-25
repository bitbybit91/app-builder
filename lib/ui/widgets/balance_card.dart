import 'package:flutter/material.dart';

class BalanceCard extends StatefulWidget {
  final String currency;
  final String balance;
  final String? fiatValue;
  final bool isLoading;

  const BalanceCard({
    super.key,
    required this.currency,
    required this.balance,
    this.fiatValue,
    this.isLoading = false,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surfaceContainerHighest,
              colorScheme.secondaryContainer,
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CurrencyMonogram(currency: widget.currency),
                const SizedBox(width: 10),
                Text(
                  widget.currency,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tooltip: _hidden ? 'Show balance' : 'Hide balance',
                  onPressed: () => setState(() => _hidden = !_hidden),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.isLoading)
              const SizedBox(
                height: 36,
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Text(
                _hidden ? '••••••' : widget.balance,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            if (widget.fiatValue != null) ...[
              const SizedBox(height: 6),
              Text(
                _hidden ? '••••' : widget.fiatValue!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CurrencyMonogram extends StatelessWidget {
  final String currency;

  const _CurrencyMonogram({required this.currency});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 18,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        currency.length >= 2 ? currency.substring(0, 2) : currency,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
