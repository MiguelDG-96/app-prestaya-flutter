import 'package:app_prestaya_flutter/features/rentals/domain/entities/tenant_entity.dart';

class TenantModel extends TenantEntity {
  const TenantModel({
    super.id,
    required super.name,
    required super.phone,
    required super.dni,
    super.address,
    required super.roomNumber,
    super.email,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      dni: json['dni'] ?? '',
      address: json['address'],
      roomNumber: json['roomNumber'] ?? json['room_number'] ?? '',
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'dni': dni,
      'address': address,
      'roomNumber': roomNumber,
      'email': email,
    };
  }
}
