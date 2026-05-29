import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/user.dart';
import '../bloc/profile_bloc.dart';

class PublicProfilePage extends StatelessWidget {
  const PublicProfilePage({super.key, required this.username});
  final String username;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return BlocProvider<ProfileBloc>(
      create: (_) => sl<ProfileBloc>()..add(ProfileLoadRequested(username)),
      child: Scaffold(
        appBar: AppBar(title: Text(username)),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (BuildContext context, ProfileState state) {
            if (state is ProfileLoading || state is ProfileInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ProfileError) {
              return Center(child: Text(state.failure.message));
            }
            final ProfileLoaded loaded = state as ProfileLoaded;
            final User u = loaded.user;
            return ListView(
              children: <Widget>[
                ListTile(
                  leading: CircleAvatar(child: Text(u.username[0].toUpperCase())),
                  title: Text(u.username),
                  subtitle: Text('${l.memberSince} ${Formatters.dateOnly(u.createdAt)}'),
                ),
                ListTile(title: Text(l.trustLevel), trailing: Text(u.trustLevel.name)),
                ListTile(title: Text(l.trades), trailing: Text(u.tradeCount.toString())),
                ListTile(
                  title: Text(l.feedbackScore),
                  trailing: Text('${u.feedbackScore}%'),
                ),
                if (u.lastSeen != null)
                  ListTile(
                    title: Text(l.lastSeen),
                    trailing: Text(Formatters.timeAgo(u.lastSeen!)),
                  ),
                if (u.country != null)
                  ListTile(title: Text(l.country), trailing: Text(u.country!)),
                if (u.languages.isNotEmpty)
                  ListTile(
                    title: Text(l.languages),
                    trailing: Text(u.languages.join(', ')),
                  ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Feedback', style: Theme.of(context).textTheme.titleMedium),
                ),
                for (final f in loaded.feedback)
                  ListTile(
                    leading: Icon(
                      f.positive ? Icons.thumb_up_alt : Icons.thumb_down_alt,
                      color: f.positive ? Colors.green : Colors.red,
                    ),
                    title: Text(f.fromUsername),
                    subtitle: Text(f.comment),
                    trailing: Text(Formatters.timeAgo(f.createdAt)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
