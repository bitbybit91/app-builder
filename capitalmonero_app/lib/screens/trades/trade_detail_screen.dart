import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/app_theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../models/message.dart';
import '../../models/trade.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/trade_provider.dart';

class TradeDetailScreen extends StatefulWidget {
  const TradeDetailScreen({super.key, required this.args});
  final Map<String, dynamic> args;

  @override
  State<TradeDetailScreen> createState() => _TradeDetailScreenState();
}

class _TradeDetailScreenState extends State<TradeDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _ratingController = TextEditingController();
  final _reviewCommentController = TextEditingController();
  int _rating = 5;
  Timer? _timer;
  Duration? _timeLeft;

  @override
  void initState() {
    super.initState();
    final tradeId = widget.args['trade_id'] as String;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TradeProvider>().fetchTrade(tradeId);
      context.read<MessageProvider>().startPolling(tradeId);
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final trade = context.read<TradeProvider>().selectedTrade;
      if (trade?.expiresAt != null) {
        final left = trade!.expiresAt!.difference(DateTime.now());
        if (mounted) setState(() => _timeLeft = left.isNegative ? Duration.zero : left);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _ratingController.dispose();
    _reviewCommentController.dispose();
    _timer?.cancel();
    context.read<MessageProvider>().stopPolling();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final tradeId = widget.args['trade_id'] as String;
    _messageController.clear();
    await context.read<MessageProvider>().sendMessage(tradeId, text);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _cancelTrade(String tradeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Trade'),
        content: const Text('Are you sure you want to cancel this trade?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Trade'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<TradeProvider>().cancelTrade(tradeId);
    }
  }

  Future<void> _openDispute(String tradeId) async {
    Navigator.pushNamed(context, AppRoutes.openDispute,
        arguments: {'trade_id': tradeId});
  }

  Future<void> _submitReview(String tradeId) async {
    final comment = _reviewCommentController.text.trim();
    if (comment.isEmpty) return;
    final success = await context
        .read<TradeProvider>()
        .submitReview(tradeId, _rating, comment);
    if (!mounted) return;
    if (success) {
      _reviewCommentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tradeProvider = context.watch<TradeProvider>();
    final msgProvider = context.watch<MessageProvider>();
    final trade = tradeProvider.selectedTrade;
    final tradeId = widget.args['trade_id'] as String;

    if (tradeProvider.loading && trade == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (trade == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trade')),
        body: const Center(child: Text('Trade not found')),
      );
    }

    final currentUserId = auth.user?.id;
    final isBuyer = currentUserId == trade.buyerId;
    final isSeller = currentUserId == trade.sellerId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Trade #${trade.tradeId.substring(0, 8)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_outlined),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.tradeChat,
              arguments: {'trade_id': trade.tradeId},
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor(trade.status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _statusColor(trade.status).withOpacity(0.5)),
              ),
              child: Text(
                trade.status.toUpperCase().replaceAll('_', ' '),
                style: TextStyle(
                  color: _statusColor(trade.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Timer
          if (_timeLeft != null &&
              (trade.status == TradeStatus.pending ||
                  trade.status == TradeStatus.funded))
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _timeLeft!.inMinutes < 10
                    ? AppColors.danger.withOpacity(0.1)
                    : AppColors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _timeLeft!.inMinutes < 10
                        ? AppColors.danger
                        : AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer,
                      color: _timeLeft!.inMinutes < 10
                          ? AppColors.danger
                          : AppColors.textMuted,
                      size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Time left: ${_timeLeft!.inMinutes.toString().padLeft(2, '0')}:${(_timeLeft!.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: _timeLeft!.inMinutes < 10
                          ? AppColors.danger
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Trade details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _DetailRow(
                  'Crypto Amount',
                  '${trade.cryptoAmount.toStringAsFixed(8)} ${trade.crypto}',
                ),
                _DetailRow(
                  'Fiat Amount',
                  '${trade.fiatCurrency} ${trade.fiatAmount.toStringAsFixed(2)}',
                ),
                _DetailRow('Payment Method', trade.paymentMethod),
                if (trade.escrowAddress != null)
                  _DetailRow('Escrow', trade.escrowAddress!,
                      mono: true, truncate: true),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Buyer/Seller cards
          Row(
            children: [
              Expanded(
                child: _UserCard(
                  role: 'Buyer',
                  username: trade.buyer?.username ?? 'Unknown',
                  highlight: isBuyer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _UserCard(
                  role: 'Seller',
                  username: trade.seller?.username ?? 'Unknown',
                  highlight: isSeller,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons
          _buildActionButtons(
              context, trade, tradeId, isBuyer, isSeller, tradeProvider),

          // Dispute info
          if (trade.dispute != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.warning.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber, color: AppColors.warning),
                      SizedBox(width: 8),
                      Text('Dispute Opened',
                          style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    trade.dispute!.reason,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  if (trade.dispute!.resolution != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Winner: ${trade.dispute!.resolution}',
                      style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(),
          // Chat preview
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Trade Chat',
                    style: Theme.of(context).textTheme.headlineSmall),
                TextButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.tradeChat,
                    arguments: {'trade_id': trade.tradeId},
                  ),
                  child: const Text('Full Chat'),
                ),
              ],
            ),
          ),

          // Last 3 messages preview
          ...msgProvider.messages.reversed.take(3).toList().reversed.map(
                (m) => _ChatBubble(
                  message: m,
                  isMine: m.senderId == currentUserId,
                ),
              ),

          // Message input
          if (trade.status != TradeStatus.completed &&
              trade.status != TradeStatus.cancelled &&
              trade.status != TradeStatus.expired)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: AppColors.accent),
                  ),
                ],
              ),
            ),

          // Review section
          if (trade.status == TradeStatus.completed) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            Text('Leave a Review',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                5,
                (i) => IconButton(
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: AppColors.warning,
                  ),
                  onPressed: () => setState(() => _rating = i + 1),
                ),
              ),
            ),
            TextFormField(
              controller: _reviewCommentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Write your review...',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _submitReview(tradeId),
              child: const Text('Submit Review'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Trade trade,
    String tradeId,
    bool isBuyer,
    bool isSeller,
    TradeProvider provider,
  ) {
    final buttons = <Widget>[];

    if (trade.status == TradeStatus.funded && isBuyer) {
      buttons.add(ElevatedButton.icon(
        onPressed: provider.loading
            ? null
            : () async {
                final ok = await provider.markPaid(tradeId);
                if (!mounted) return;
                if (!ok && provider.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(provider.error!)),
                  );
                }
              },
        icon: const Icon(Icons.payment),
        label: const Text('Mark Payment Sent'),
        style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success),
      ));
    }

    if (trade.status == TradeStatus.paymentSent && isSeller) {
      buttons.add(ElevatedButton.icon(
        onPressed: provider.loading
            ? null
            : () async {
                final ok = await provider.completeTrade(tradeId);
                if (!mounted) return;
                if (!ok && provider.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(provider.error!)),
                  );
                }
              },
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Release & Complete'),
        style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success),
      ));
    }

    if ((trade.status == TradeStatus.pending ||
            trade.status == TradeStatus.funded) &&
        (isSeller || isBuyer)) {
      buttons.add(OutlinedButton.icon(
        onPressed: provider.loading
            ? null
            : () => _cancelTrade(tradeId),
        icon: const Icon(Icons.cancel_outlined,
            color: AppColors.danger),
        label: const Text('Cancel',
            style: TextStyle(color: AppColors.danger)),
        style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.danger)),
      ));
    }

    if ((trade.status == TradeStatus.funded ||
            trade.status == TradeStatus.paymentSent) &&
        isBuyer) {
      buttons.add(OutlinedButton.icon(
        onPressed: () => _openDispute(tradeId),
        icon: const Icon(Icons.gavel_outlined),
        label: const Text('Open Dispute'),
      ));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buttons
          .map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: b,
              ))
          .toList(),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case TradeStatus.completed:
        return AppColors.success;
      case TradeStatus.disputed:
        return AppColors.warning;
      case TradeStatus.cancelled:
      case TradeStatus.expired:
        return AppColors.danger;
      default:
        return AppColors.info;
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value,
      {this.mono = false, this.truncate = false});
  final String label;
  final String value;
  final bool mono;
  final bool truncate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13)),
          Flexible(
            child: Text(
              truncate && value.length > 16
                  ? '${value.substring(0, 8)}...${value.substring(value.length - 8)}'
                  : value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontFamily: mono ? 'monospace' : null,
                fontSize: mono ? 12 : null,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard(
      {required this.role,
      required this.username,
      required this.highlight});
  final String role;
  final String username;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.accent.withOpacity(0.1)
            : AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? AppColors.accent : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Text(role,
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text('@$username',
              style: TextStyle(
                color: highlight
                    ? AppColors.accent
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              )),
          if (highlight)
            const Text('(You)',
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isMine});
  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final isSystem = message.senderId == 0;
    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.body,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12),
          ),
        ),
      );
    }
    return Align(
      alignment:
          isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMine ? AppColors.accent : AppColors.bgCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMine ? 12 : 2),
            bottomRight: Radius.circular(isMine ? 2 : 12),
          ),
          border: isMine
              ? null
              : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMine && message.sender != null)
              Text(
                '@${message.sender!.username}',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 10),
              ),
            Text(
              message.body,
              style: TextStyle(
                color:
                    isMine ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              timeago.format(message.createdAt),
              style: TextStyle(
                color: isMine
                    ? Colors.white54
                    : AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
