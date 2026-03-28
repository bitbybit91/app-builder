import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/app_theme.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';

class TradeChatScreen extends StatefulWidget {
  const TradeChatScreen({super.key, required this.args});
  final Map<String, dynamic> args;

  @override
  State<TradeChatScreen> createState() => _TradeChatScreenState();
}

class _TradeChatScreenState extends State<TradeChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final tradeId = widget.args['trade_id'] as String;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().startPolling(tradeId);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    context.read<MessageProvider>().stopPolling();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final tradeId = widget.args['trade_id'] as String;
    _messageController.clear();
    await context.read<MessageProvider>().sendMessage(tradeId, text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final tradeId = widget.args['trade_id'] as String;
    final counterparty = widget.args['counterparty'] as String?;
    final auth = context.watch<AuthProvider>();
    final msgProvider = context.watch<MessageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trade #${tradeId.substring(0, 8)}'),
            if (counterparty != null)
              Text(
                '@$counterparty',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: msgProvider.messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: msgProvider.messages.length,
                    itemBuilder: (context, index) {
                      final msg = msgProvider.messages[index];
                      final isMine =
                          msg.senderId == auth.user?.id;
                      return _ChatBubble(
                          message: msg, isMine: isMine);
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
            decoration: const BoxDecoration(
              color: AppColors.bgSecondary,
              border: Border(
                  top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            message.body,
            style:
                const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.bgInput,
              child: Text(
                message.sender?.username.isNotEmpty == true
                    ? message.sender!.username[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: AppColors.accent, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.70,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? AppColors.accent : AppColors.bgCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft:
                      Radius.circular(isMine ? 14 : 2),
                  bottomRight:
                      Radius.circular(isMine ? 2 : 14),
                ),
                border: isMine
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMine && message.sender != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '@${message.sender!.username}',
                        style: TextStyle(
                          color: isMine
                              ? Colors.white70
                              : AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Text(
                    message.body,
                    style: TextStyle(
                      color: isMine
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
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
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
