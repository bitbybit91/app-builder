import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  const ChatPage({super.key, required this.conversationId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  bool _encryptionEnabled = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: Icon(_encryptionEnabled ? Icons.lock : Icons.lock_open),
            onPressed: () => setState(() => _encryptionEnabled = !_encryptionEnabled),
            tooltip: _encryptionEnabled ? 'PGP Encryption: ON' : 'PGP Encryption: OFF',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_encryptionEnabled)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.green.withOpacity(0.1),
              child: const Row(children: [
                Icon(Icons.lock, size: 16, color: Colors.green),
                SizedBox(width: 8),
                Text('End-to-end encrypted', style: TextStyle(color: Colors.green, fontSize: 12)),
              ]),
            ),
          const Expanded(child: Center(child: Text('No messages yet'))),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  maxLines: null,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (_messageController.text.isNotEmpty) {
                    _messageController.clear();
                  }
                },
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
