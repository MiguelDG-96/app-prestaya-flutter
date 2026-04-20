import '../../domain/entities/client_entity.dart';

class ClientModel extends ClientEntity {
  const ClientModel({
    required super.id,
    required super.name,
    super.phone,
    super.dni,
    super.address,
    super.email,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Sin nombre',
      phone: json['phone'],
      dni: json['dni'],
      address: json['address'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'dni': dni,
      'address': address,
      'email': email,
    };
  }
}
