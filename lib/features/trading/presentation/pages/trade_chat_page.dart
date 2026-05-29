import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/trade.dart';
import '../bloc/trade_bloc.dart';

class TradeChatPage extends StatelessWidget {
  const TradeChatPage({super.key, required this.tradeId});
  final String tradeId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TradeBloc>(
      create: (_) => sl<TradeBloc>()..add(TradeLoadRequested(tradeId)),
      child: _ChatView(tradeId: tradeId),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView({required this.tradeId});
  final String tradeId;
  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final TextEditingController _ctrl = TextEditingController();
  bool _encrypt = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send(String me) {
    final String body = _ctrl.text.trim();
    if (body.isEmpty) return;
    context.read<TradeBloc>().add(TradeMessageSent(
          tradeId: widget.tradeId,
          fromUsername: me,
          body: body,
          encrypted: _encrypt,
        ));
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AuthState authState = context.watch<AuthBloc>().state;
    final String me = authState is AuthAuthenticated
        ? authState.session.user.username
        : 'guest';
    return Scaffold(
      appBar: AppBar(title: Text(l.tradeChat)),
      body: BlocBuilder<TradeBloc, TradeState>(
        builder: (BuildContext context, TradeState state) {
          if (state is! TradeLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<TradeMessage> messages = state.messages;
          return Column(
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (BuildContext context, int i) {
                    final TradeMessage m =
                        messages[messages.length - 1 - i];
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
                      icon: Icon(
                        _encrypt ? Icons.lock : Icons.lock_open,
                        color: _encrypt
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      tooltip: l.encryptWithPgp,
                      onPressed: () => setState(() => _encrypt = !_encrypt),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        decoration: InputDecoration(hintText: l.messagePlaceholder),
                        minLines: 1,
                        maxLines: 5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _send(me),
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
