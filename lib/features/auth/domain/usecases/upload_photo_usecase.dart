import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../repositories/auth_repository.dart';
import '../entities/user_entity.dart';

class UploadPhotoUseCase {
  final AuthRepository repository;

  UploadPhotoUseCase(this.repository);

  Future<Either<Failure, UserEntity>> execute(String userId, String filePath) {
    return repository.uploadPhoto(userId, filePath);
  }
}
