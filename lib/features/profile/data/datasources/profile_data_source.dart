import '../../../../core/errors/exceptions.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';

abstract class ProfileDataSource {
  Future<User> publicProfile(String username);
  Future<List<Feedback>> feedback(String username);
  Future<User> update(User user);
}

class InMemoryProfileDataSource implements ProfileDataSource {
  InMemoryProfileDataSource() {
    _seed();
  }

  final Map<String, User> _users = <String, User>{};
  final Map<String, List<Feedback>> _feedback = <String, List<Feedback>>{};

  void _seed() {
    final DateTime now = DateTime.now();
    _users['satoshi'] = User(
      id: 'u-satoshi',
      username: 'satoshi',
      role: UserRole.user,
      createdAt: now.subtract(const Duration(days: 1500)),
      tradeCount: 312,
      feedbackScore: 99,
      lastSeen: now.subtract(const Duration(minutes: 12)),
      country: 'JP',
      languages: const <String>['en', 'ja'],
      twoFactorEnabled: true,
    );
    _users['alice'] = User(
      id: 'u-alice',
      username: 'alice',
      role: UserRole.user,
      createdAt: now.subtract(const Duration(days: 220)),
      tradeCount: 47,
      feedbackScore: 100,
      lastSeen: now.subtract(const Duration(hours: 3)),
      country: 'DE',
      languages: const <String>['de', 'en'],
    );
    _users['bob'] = User(
      id: 'u-bob',
      username: 'bob',
      role: UserRole.user,
      createdAt: now.subtract(const Duration(days: 90)),
      tradeCount: 18,
      feedbackScore: 92,
      lastSeen: now.subtract(const Duration(days: 1)),
      country: 'US',
      languages: const <String>['en'],
    );
    _feedback['satoshi'] = <Feedback>[
      Feedback(
        fromUsername: 'alice',
        positive: true,
        comment: 'Fast and reliable.',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      Feedback(
        fromUsername: 'bob',
        positive: true,
        comment: 'Great communication.',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
    ];
  }

  @override
  Future<User> publicProfile(String username) async {
    final User? u = _users[username];
    if (u == null) throw NotFoundException('User $username');
    return u;
  }

  @override
  Future<List<Feedback>> feedback(String username) async {
    return List<Feedback>.unmodifiable(
        _feedback[username] ?? const <Feedback>[]);
  }

  @override
  Future<User> update(User user) async {
    _users[user.username] = user;
    return user;
  }
}
