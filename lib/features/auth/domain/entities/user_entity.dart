import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final String? role;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    this.role,
  });

  @override
  List<Object?> get props => [id, name, email, phone, photoUrl, role];

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? role,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
    );
  }
}
