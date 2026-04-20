import 'package:equatable/equatable.dart';

class ClientEntity extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final String? dni;
  final String? address;
  final String? email;

  const ClientEntity({
    required this.id,
    required this.name,
    this.phone,
    this.dni,
    this.address,
    this.email,
  });

  @override
  List<Object?> get props => [id, name, phone, dni, address, email];
}
