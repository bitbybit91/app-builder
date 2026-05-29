import 'package:uuid/uuid.dart';

import '../../domain/entities/message.dart';

abstract class MessagingDataSource {
  Future<List<Conversation>> conversations();
  Future<List<DirectMessage>> thread(String peerUsername);
  Future<DirectMessage> send(DirectMessage draft);
}

class InMemoryMessagingDataSource implements MessagingDataSource {
  InMemoryMessagingDataSource() {
    _seed();
  }

  final Uuid _uuid = const Uuid();
  final Map<String, List<DirectMessage>> _threads =
      <String, List<DirectMessage>>{};

  void _seed() {
    final DateTime now = DateTime.now();
    _threads['satoshi'] = <DirectMessage>[
      DirectMessage(
        id: _uuid.v4(),
        fromUsername: 'satoshi',
        toUsername: 'me',
        body: 'Hello, I can accept SEPA same-name only.',
        sentAt: now.subtract(const Duration(hours: 5)),
      ),
      DirectMessage(
        id: _uuid.v4(),
        fromUsername: 'me',
        toUsername: 'satoshi',
        body: 'Sounds good. I will send EUR 250 in the morning.',
        sentAt: now.subtract(const Duration(hours: 4)),
      ),
    ];
    _threads['alice'] = <DirectMessage>[
      DirectMessage(
        id: _uuid.v4(),
        fromUsername: 'alice',
        toUsername: 'me',
        body: 'Trade #4f1 has been released.',
        sentAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  @override
  Future<List<Conversation>> conversations() async {
    final List<Conversation> result = <Conversation>[];
    _threads.forEach((String peer, List<DirectMessage> msgs) {
      final DirectMessage last = msgs.last;
      result.add(Conversation(
        peerUsername: peer,
        lastMessage: last.body,
        updatedAt: last.sentAt,
      ));
    });
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  @override
  Future<List<DirectMessage>> thread(String peerUsername) async {
    return List<DirectMessage>.unmodifiable(
        _threads[peerUsername] ?? const <DirectMessage>[]);
  }

  @override
  Future<DirectMessage> send(DirectMessage draft) async {
    final DirectMessage stored = DirectMessage(
      id: _uuid.v4(),
      fromUsername: draft.fromUsername,
      toUsername: draft.toUsername,
      body: draft.body,
      sentAt: DateTime.now(),
      encrypted: draft.encrypted,
    );
    _threads.putIfAbsent(draft.toUsername, () => <DirectMessage>[]).add(stored);
    return stored;
  }
}
