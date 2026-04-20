import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:app_prestaya_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_prestaya_flutter/features/auth/domain/entities/user_entity.dart';
import 'package:app_prestaya_flutter/features/auth/domain/usecases/login_usecase.dart';
import 'package:app_prestaya_flutter/features/auth/domain/usecases/upload_photo_usecase.dart';

// Eventos
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class GoogleLoginRequested extends AuthEvent {
  final String idToken;
  GoogleLoginRequested(this.idToken);
  @override
  List<Object?> get props => [idToken];
}

class PhotoUploadRequested extends AuthEvent {
  final String userId;
  final String filePath;
  PhotoUploadRequested(this.userId, this.filePath);
  @override
  List<Object?> get props => [userId, filePath];
}

class UpdateProfileRequested extends AuthEvent {
  final String? name;
  final String? phone;
  UpdateProfileRequested({this.name, this.phone});
  @override
  List<Object?> get props => [name, phone];
}

class AuthCheckRequested extends AuthEvent {}

class LogoutRequested extends AuthEvent {}

// Estados
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Authenticated extends AuthState {
  final UserEntity user;
  Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}
class Unauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final UploadPhotoUseCase uploadPhotoUseCase;
  final AuthRepository repository;

  AuthBloc({
    required this.loginUseCase,
    required this.uploadPhotoUseCase,
    required this.repository,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>((event, emit) async {
      final userOption = await repository.getLoggedInUser();
      userOption.fold(
        () => emit(Unauthenticated()),
        (user) => emit(Authenticated(user)),
      );
    });

    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await loginUseCase.execute(event.email, event.password);
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) => emit(Authenticated(user)),
      );
    });

    on<GoogleLoginRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await repository.loginWithGoogle(event.idToken);
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) => emit(Authenticated(user)),
      );
    });

    on<PhotoUploadRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await uploadPhotoUseCase.execute(event.userId, event.filePath);
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) => emit(Authenticated(user)),
      );
    });

    on<UpdateProfileRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await repository.updateProfile(name: event.name, phone: event.phone);
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) => emit(Authenticated(user)),
      );
    });

    on<LogoutRequested>((event, emit) async {
      await repository.logout();
      emit(Unauthenticated());
    });
  }
}
