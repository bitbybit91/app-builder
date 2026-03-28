import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/dispute.dart';

class DisputeDetailScreen extends StatelessWidget {
  const DisputeDetailScreen({super.key, required this.args});
  final Map<String, dynamic> args;

  @override
  Widget build(BuildContext context) {
    final dispute = args['dispute'] as Dispute?;

    if (dispute == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dispute Detail')),
        body: const Center(child: Text('Dispute not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Dispute #${dispute.id}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(dispute.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _statusColor(dispute.status).withOpacity(0.5)),
                ),
                child: Text(
                  dispute.status.toUpperCase(),
                  style: TextStyle(
                    color: _statusColor(dispute.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Dispute info
            _InfoCard(
              title: 'Dispute Information',
              children: [
                _InfoRow('Trade ID', dispute.tradeId.toString()),
                _InfoRow('Opened By', 'User #${dispute.openedBy}'),
                _InfoRow(
                    'Opened',
                    '${dispute.createdAt.day}/${dispute.createdAt.month}/${dispute.createdAt.year}'),
                _InfoRow('Reason', dispute.reason),
              ],
            ),
            const SizedBox(height: 12),

            // Evidence
            if (dispute.evidenceText != null &&
                dispute.evidenceText!.isNotEmpty) ...[
              _InfoCard(
                title: 'Evidence',
                children: [
                  Text(
                    dispute.evidenceText!,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Trade info
            if (dispute.trade != null) ...[
              _InfoCard(
                title: 'Trade Details',
                children: [
                  _InfoRow('Trade ID', dispute.trade!.tradeId),
                  _InfoRow(
                    'Amount',
                    '${dispute.trade!.cryptoAmount.toStringAsFixed(6)} ${dispute.trade!.crypto}',
                  ),
                  _InfoRow(
                    'Value',
                    '${dispute.trade!.fiatCurrency} ${dispute.trade!.fiatAmount.toStringAsFixed(2)}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Resolution
            if (dispute.resolution != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.success.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: AppColors.success, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Resolved',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Winner: ${dispute.resolution!}',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600)),
                    if (dispute.resolutionNotes != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        dispute.resolutionNotes!,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                    if (dispute.resolvedAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Resolved on ${dispute.resolvedAt!.day}/${dispute.resolvedAt!.month}/${dispute.resolvedAt!.year}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
        return AppColors.success;
      case 'open':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
