import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/message.dart';
import '../bloc/messaging_bloc.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return BlocProvider<MessagingBloc>(
      create: (_) => sl<MessagingBloc>()
        ..add(const MessagingConversationsRequested()),
      child: Scaffold(
        appBar: AppBar(title: Text(l.messages)),
        body: BlocBuilder<MessagingBloc, MessagingState>(
          builder: (BuildContext context, MessagingState state) {
            if (state is MessagingLoading || state is MessagingInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MessagingError) {
              return Center(child: Text(state.failure.message));
            }
            final List<Conversation> convs =
                (state as MessagingConversationsLoaded).conversations;
            if (convs.isEmpty) {
              return const Center(child: Text('No conversations yet'));
            }
            return ListView.separated(
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemCount: convs.length,
              itemBuilder: (BuildContext context, int i) {
                final Conversation c = convs[i];
                return ListTile(
                  leading: CircleAvatar(child: Text(c.peerUsername[0].toUpperCase())),
                  title: Text(c.peerUsername),
                  subtitle: Text(c.lastMessage,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(Formatters.timeAgo(c.updatedAt)),
                  onTap: () => context.push('/messages/${c.peerUsername}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
