import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String email, String password);
  Future<Either<Failure, UserEntity>> loginWithGoogle(String idToken);
  Future<void> logout();
  Future<Option<UserEntity>> getLoggedInUser();
  Future<Either<Failure, UserEntity>> uploadPhoto(String userId, String filePath);
  Future<Either<Failure, UserEntity>> updateProfile({String? name, String? phone});
}
