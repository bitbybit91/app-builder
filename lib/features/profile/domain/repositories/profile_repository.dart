import '../entities/profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> getProfile(String username);
  Future<UserProfile> updateProfile(UserProfile profile);
  Future<void> submitFeedback(String userId, bool isPositive, String? comment);
}
