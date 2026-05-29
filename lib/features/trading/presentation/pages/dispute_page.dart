import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/trade_bloc.dart';

class DisputePage extends StatefulWidget {
  const DisputePage({super.key, required this.tradeId});
  final String tradeId;

  @override
  State<DisputePage> createState() => _DisputePageState();
}

class _DisputePageState extends State<DisputePage> {
  final TextEditingController _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return BlocProvider<TradeBloc>(
      create: (_) => sl<TradeBloc>(),
      child: Scaffold(
        appBar: AppBar(title: Text(l.openDispute)),
        body: BlocConsumer<TradeBloc, TradeState>(
          listener: (BuildContext context, TradeState state) {
            if (state is TradeError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.failure.message)),
              );
            } else if (state is TradeLoaded) {
              context.pop();
            }
          },
          builder: (BuildContext context, TradeState state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Explain what went wrong with this trade. An admin will '
                    'review the chat history and decide an outcome.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reasonCtrl,
                    minLines: 4,
                    maxLines: 12,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      if (_reasonCtrl.text.trim().isEmpty) return;
                      context.read<TradeBloc>().add(TradeActionRequested(
                            widget.tradeId,
                            TradeAction.dispute,
                            disputeReason: _reasonCtrl.text.trim(),
                          ));
                    },
                    child: Text(l.openDispute),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
