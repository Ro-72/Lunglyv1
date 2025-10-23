import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentType {
  creditCard,
  paypal,
  bankTransfer,
}

class PaymentMethod {
  final String id;
  final String userId;
  final PaymentType type;
  final String name; // Nombre del método (ej: "Visa **** 1234")
  final Map<String, dynamic> details; // Detalles específicos del método
  final bool isDefault;
  final DateTime createdAt;

  PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    required this.details,
    this.isDefault = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'name': name,
      'details': details,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map, String id) {
    PaymentType type;
    switch (map['type']) {
      case 'creditCard':
        type = PaymentType.creditCard;
        break;
      case 'paypal':
        type = PaymentType.paypal;
        break;
      case 'bankTransfer':
        type = PaymentType.bankTransfer;
        break;
      default:
        type = PaymentType.creditCard;
    }

    return PaymentMethod(
      id: id,
      userId: map['userId'] ?? '',
      type: type,
      name: map['name'] ?? '',
      details: Map<String, dynamic>.from(map['details'] ?? {}),
      isDefault: map['isDefault'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String getTypeString() {
    switch (type) {
      case PaymentType.creditCard:
        return 'Tarjeta de Crédito';
      case PaymentType.paypal:
        return 'PayPal';
      case PaymentType.bankTransfer:
        return 'Transferencia Bancaria';
    }
  }

  String getIconName() {
    switch (type) {
      case PaymentType.creditCard:
        return 'credit_card';
      case PaymentType.paypal:
        return 'paypal';
      case PaymentType.bankTransfer:
        return 'account_balance';
    }
  }
}
