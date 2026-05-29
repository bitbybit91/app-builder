import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.profile)),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (BuildContext context, AuthState state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }
          final User u = state.session.user;
          return ListView(
            children: <Widget>[
              ListTile(
                leading: CircleAvatar(child: Text(u.username[0].toUpperCase())),
                title: Text(u.username),
                subtitle: Text('${l.memberSince} ${Formatters.dateOnly(u.createdAt)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/profile/edit'),
                ),
              ),
              const Divider(),
              ListTile(
                title: Text(l.trustLevel),
                trailing: Text(u.trustLevel.name),
              ),
              ListTile(
                title: Text(l.trades),
                trailing: Text(u.tradeCount.toString()),
              ),
              ListTile(
                title: Text(l.feedbackScore),
                trailing: Text('${u.feedbackScore}%'),
              ),
              ListTile(
                title: Text(l.tradeHistory),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/trades'),
              ),
              ListTile(
                title: Text(l.twoFactorSetup),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/2fa-setup'),
              ),
              if (u.role == UserRole.admin || u.role == UserRole.moderator)
                ListTile(
                  title: Text(l.adminPanel),
                  trailing: const Icon(Icons.shield_outlined),
                  onTap: () => context.push('/admin'),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(l.signOut),
                onTap: () =>
                    context.read<AuthBloc>().add(const AuthLogoutRequested()),
              ),
            ],
          );
        },
      ),
    );
  }
}
