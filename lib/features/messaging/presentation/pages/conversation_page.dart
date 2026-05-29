import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/message.dart';
import '../bloc/messaging_bloc.dart';

class ConversationPage extends StatelessWidget {
  const ConversationPage({super.key, required this.peerUsername});
  final String peerUsername;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MessagingBloc>(
      create: (_) => sl<MessagingBloc>()
        ..add(MessagingThreadRequested(peerUsername)),
      child: _ConversationView(peerUsername: peerUsername),
    );
  }
}

class _ConversationView extends StatefulWidget {
  const _ConversationView({required this.peerUsername});
  final String peerUsername;
  @override
  State<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<_ConversationView> {
  final TextEditingController _ctrl = TextEditingController();
  bool _encrypt = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AuthState authState = context.watch<AuthBloc>().state;
    final String me = authState is AuthAuthenticated
        ? authState.session.user.username
        : 'me';
    return Scaffold(
      appBar: AppBar(title: Text(widget.peerUsername)),
      body: BlocBuilder<MessagingBloc, MessagingState>(
        builder: (BuildContext context, MessagingState state) {
          if (state is! MessagingThreadLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<DirectMessage> msgs = state.messages;
          return Column(
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: msgs.length,
                  itemBuilder: (BuildContext context, int i) {
                    final DirectMessage m = msgs[msgs.length - 1 - i];
                    final bool mine = m.fromUsername == me;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Card(
                        color: mine
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(m.body),
                              const SizedBox(height: 2),
                              Text(
                                '${m.encrypted ? "PGP " : ""}${Formatters.timeAgo(m.sentAt)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(children: <Widget>[
                    IconButton(
                      icon: Icon(_encrypt ? Icons.lock : Icons.lock_open),
                      onPressed: () => setState(() => _encrypt = !_encrypt),
                      tooltip: l.encryptWithPgp,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        decoration: InputDecoration(hintText: l.messagePlaceholder),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        if (_ctrl.text.trim().isEmpty) return;
                        context.read<MessagingBloc>().add(MessagingSendRequested(
                              fromUsername: me,
                              toUsername: widget.peerUsername,
                              body: _ctrl.text.trim(),
                              encrypted: _encrypt,
                            ));
                        _ctrl.clear();
                      },
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
