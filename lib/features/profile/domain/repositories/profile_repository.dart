import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';
import '../entities/feedback_item.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserProfile>> getUserProfile(String username);
  Future<Either<Failure, UserProfile>> getMyProfile();
  Future<Either<Failure, void>> updateProfile({String? bio, String? pgpPublicKey});
  Future<Either<Failure, List<FeedbackItem>>> getUserFeedback(String username);
}
