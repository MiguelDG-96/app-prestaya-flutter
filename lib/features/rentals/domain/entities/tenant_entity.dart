import 'package:equatable/equatable.dart';

class TenantEntity extends Equatable {
  final String? id;
  final String name;
  final String phone;
  final String dni;
  final String? address;
  final String roomNumber;
  final String? email;

  const TenantEntity({
    this.id,
    required this.name,
    required this.phone,
    required this.dni,
    this.address,
    required this.roomNumber,
    this.email,
  });

  @override
  List<Object?> get props => [id, name, phone, dni, address, roomNumber, email];
}
