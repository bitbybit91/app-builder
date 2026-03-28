import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/dispute.dart';
import '../../providers/admin_provider.dart';

class AdminDisputesScreen extends StatefulWidget {
  const AdminDisputesScreen({super.key});

  @override
  State<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends State<AdminDisputesScreen> {
  final _scrollController = ScrollController();
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchDisputes(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final p = context.read<AdminProvider>();
      if (!p.loading && p.hasMoreDisputes) p.fetchDisputes();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Disputes')),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.adminDisputes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.adminDisputes.isEmpty) {
            return const Center(
              child: Text('No open disputes',
                  style: TextStyle(color: AppColors.textMuted)),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchDisputes(refresh: true),
            color: AppColors.accent,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: provider.adminDisputes.length +
                  (provider.hasMoreDisputes ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.adminDisputes.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          color: AppColors.accent),
                    ),
                  );
                }
                final dispute = provider.adminDisputes[index];
                final isExpanded = _expandedIndex == index;
                return _DisputeCard(
                  dispute: dispute,
                  isExpanded: isExpanded,
                  onToggle: () => setState(() =>
                      _expandedIndex = isExpanded ? null : index),
                  onResolve: (winner, notes) async {
                    final ok = await provider.resolveDispute(
                        dispute.id, winner, notes);
                    if (!mounted) return;
                    if (ok) {
                      setState(() => _expandedIndex = null);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Dispute resolved'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                provider.error ?? 'Failed to resolve')),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DisputeCard extends StatefulWidget {
  const _DisputeCard({
    required this.dispute,
    required this.isExpanded,
    required this.onToggle,
    required this.onResolve,
  });
  final Dispute dispute;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Future<void> Function(String winner, String notes) onResolve;

  @override
  State<_DisputeCard> createState() => _DisputeCardState();
}

class _DisputeCardState extends State<_DisputeCard> {
  String _winner = 'buyer';
  final _notesController = TextEditingController();
  bool _resolving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dispute;
    return Card(
      child: Column(
        children: [
          ListTile(
            onTap: widget.onToggle,
            leading: const Icon(Icons.gavel_outlined,
                color: AppColors.warning),
            title: Text('Dispute #${d.id}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trade ID: ${d.tradeId}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
                Text(
                  d.reason,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Opened by: @${d.opener?.username ?? 'unknown'}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                d.status.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (widget.isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(),
                  if (d.evidenceText != null && d.evidenceText!.isNotEmpty) ...[
                    const Text('Evidence:',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(d.evidenceText!,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 12),
                  ],
                  const Text('Resolution Winner:',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _WinnerBtn(
                          label: 'Buyer',
                          selected: _winner == 'buyer',
                          onTap: () => setState(() => _winner = 'buyer'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _WinnerBtn(
                          label: 'Seller',
                          selected: _winner == 'seller',
                          onTap: () => setState(() => _winner = 'seller'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Resolution notes',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _resolving
                        ? null
                        : () async {
                            setState(() => _resolving = true);
                            await widget.onResolve(
                                _winner, _notesController.text);
                            if (mounted) {
                              setState(() => _resolving = false);
                            }
                          },
                    child: _resolving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Resolve Dispute'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WinnerBtn extends StatelessWidget {
  const _WinnerBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withOpacity(0.2)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.accent : AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
