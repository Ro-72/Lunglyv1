import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

enum PaymentType {
  creditCard,
  paypal,
  bankTransfer,
  yape,
}

extension PaymentTypeExtension on PaymentType {
  String get displayName {
    switch (this) {
      case PaymentType.creditCard:
        return 'Tarjeta de Crédito';
      case PaymentType.paypal:
        return 'PayPal';
      case PaymentType.bankTransfer:
        return 'Transferencia Bancaria';
      case PaymentType.yape:
        return 'Yape';
    }
  }

  String get shortName {
    switch (this) {
      case PaymentType.creditCard:
        return 'creditCard';
      case PaymentType.paypal:
        return 'paypal';
      case PaymentType.bankTransfer:
        return 'bankTransfer';
      case PaymentType.yape:
        return 'yape';
    }
  }
}

class PaymentMethod {
  final String id;
  final String userId;
  final PaymentType type;
  final String name;
  final Map<String, dynamic> details;
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

  String getTypeString() => type.displayName;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.shortName,
      'name': name,
      'details': details,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map, String id) {
    final typeString = map['type'] as String? ?? 'creditCard';
    PaymentType type;
    
    switch (typeString) {
      case 'paypal':
        type = PaymentType.paypal;
        break;
      case 'bankTransfer':
        type = PaymentType.bankTransfer;
        break;
      case 'yape':
        type = PaymentType.yape;
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
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  String getIconName() {
    switch (type) {
      case PaymentType.creditCard:
        return 'credit_card';
      case PaymentType.paypal:
        return 'paypal';
      case PaymentType.bankTransfer:
        return 'account_balance';
      case PaymentType.yape:
        return 'yape';
    }
  }
}
