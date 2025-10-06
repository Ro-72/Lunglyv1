import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/payment_method.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Métodos de Pago'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Text('Debes iniciar sesión para ver tus métodos de pago'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Métodos de Pago'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('payment_methods')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final paymentMethods = snapshot.data?.docs
                  .map((doc) =>
                      PaymentMethod.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                  .toList() ??
              [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Tus métodos de pago guardados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Agrega y administra tus métodos de pago para agilizar tus reservas de citas.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ...paymentMethods.map((method) => _buildPaymentMethodCard(method)),
              const SizedBox(height: 16),
              _buildAddMethodButton(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    IconData icon;
    switch (method.type) {
      case PaymentType.creditCard:
        icon = Icons.credit_card;
        break;
      case PaymentType.paypal:
        icon = Icons.paypal;
        break;
      case PaymentType.bankTransfer:
        icon = Icons.account_balance;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue[700], size: 28),
        ),
        title: Text(
          method.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(method.getTypeString()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (method.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Text(
                  'Principal',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'default') {
                  _setAsDefault(method.id);
                } else if (value == 'edit') {
                  _editPaymentMethod(method);
                } else if (value == 'delete') {
                  _deletePaymentMethod(method.id);
                }
              },
              itemBuilder: (context) => [
                if (!method.isDefault)
                  const PopupMenuItem(
                    value: 'default',
                    child: Row(
                      children: [
                        Icon(Icons.star, size: 18),
                        SizedBox(width: 8),
                        Text('Establecer como principal'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMethodButton(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 8),
        const Text(
          'Agregar nuevo método de pago',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAddMethodCard(
                icon: Icons.credit_card,
                title: 'Tarjeta',
                type: PaymentType.creditCard,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAddMethodCard(
                icon: Icons.paypal,
                title: 'PayPal',
                type: PaymentType.paypal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAddMethodCard(
                icon: Icons.account_balance,
                title: 'Banco',
                type: PaymentType.bankTransfer,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddMethodCard({
    required IconData icon,
    required String title,
    required PaymentType type,
  }) {
    return InkWell(
      onTap: () => _addPaymentMethod(type),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Colors.blue[700]),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addPaymentMethod(PaymentType type) async {
    _showPaymentMethodForm(type: type);
  }

  Future<void> _editPaymentMethod(PaymentMethod method) async {
    _showPaymentMethodForm(type: method.type, existingMethod: method);
  }

  Future<void> _showPaymentMethodForm({
    required PaymentType type,
    PaymentMethod? existingMethod,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final details = <String, String>{};

    if (existingMethod != null) {
      nameController.text = existingMethod.name;
      details.addAll(existingMethod.details.map((k, v) => MapEntry(k, v.toString())));
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            existingMethod != null ? 'Editar Método de Pago' : 'Agregar Método de Pago',
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (type == PaymentType.creditCard) ...[
                    TextFormField(
                      initialValue: details['cardNumber'],
                      decoration: const InputDecoration(
                        labelText: 'Número de Tarjeta',
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 16,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el número de tarjeta';
                        }
                        if (value.length != 16) {
                          return 'Debe tener 16 dígitos';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        details['cardNumber'] = value!;
                        // Crear nombre amigable con últimos 4 dígitos
                        nameController.text = 'Tarjeta **** ${value.substring(12)}';
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: details['cardholderName'],
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Titular',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el nombre del titular';
                        }
                        return null;
                      },
                      onSaved: (value) => details['cardholderName'] = value!,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: details['expiryDate'],
                            decoration: const InputDecoration(
                              labelText: 'Vencimiento (MM/AA)',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            keyboardType: TextInputType.datetime,
                            maxLength: 5,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Requerido';
                              }
                              return null;
                            },
                            onSaved: (value) => details['expiryDate'] = value!,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: details['cvv'],
                            decoration: const InputDecoration(
                              labelText: 'CVV',
                              prefixIcon: Icon(Icons.lock),
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 3,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Requerido';
                              }
                              return null;
                            },
                            onSaved: (value) => details['cvv'] = value!,
                          ),
                        ),
                      ],
                    ),
                  ] else if (type == PaymentType.paypal) ...[
                    TextFormField(
                      initialValue: details['email'],
                      decoration: const InputDecoration(
                        labelText: 'Correo de PayPal',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu correo de PayPal';
                        }
                        if (!value.contains('@')) {
                          return 'Ingresa un correo válido';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        details['email'] = value!;
                        nameController.text = 'PayPal - $value';
                      },
                    ),
                  ] else if (type == PaymentType.bankTransfer) ...[
                    TextFormField(
                      initialValue: details['bankName'],
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Banco',
                        prefixIcon: Icon(Icons.account_balance),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el nombre del banco';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        details['bankName'] = value!;
                        nameController.text = value;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: details['accountNumber'],
                      decoration: const InputDecoration(
                        labelText: 'Número de Cuenta',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el número de cuenta';
                        }
                        return null;
                      },
                      onSaved: (value) => details['accountNumber'] = value!,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: details['accountHolder'],
                      decoration: const InputDecoration(
                        labelText: 'Titular de la Cuenta',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el titular de la cuenta';
                        }
                        return null;
                      },
                      onSaved: (value) => details['accountHolder'] = value!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  Navigator.pop(context);
                  await _savePaymentMethod(
                    type: type,
                    name: nameController.text,
                    details: details,
                    existingId: existingMethod?.id,
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _savePaymentMethod({
    required PaymentType type,
    required String name,
    required Map<String, String> details,
    String? existingId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Verificar si es el primer método de pago
      final existingMethods = await _firestore
          .collection('payment_methods')
          .where('userId', isEqualTo: user.uid)
          .get();

      final isFirstMethod = existingMethods.docs.isEmpty;

      bool isDefault = isFirstMethod;
      if (existingId != null) {
        final doc = await _firestore
            .collection('payment_methods')
            .doc(existingId)
            .get();
        final data = doc.data();
        isDefault = (data?['isDefault'] as bool?) ?? isFirstMethod;
      }

      final paymentMethod = PaymentMethod(
        id: existingId ?? '',
        userId: user.uid,
        type: type,
        name: name,
        details: details,
        isDefault: isDefault,
        createdAt: DateTime.now(),
      );

      if (existingId != null) {
        // Actualizar método existente
        await _firestore
            .collection('payment_methods')
            .doc(existingId)
            .update(paymentMethod.toMap());
      } else {
        // Crear nuevo método
        await _firestore.collection('payment_methods').add(paymentMethod.toMap());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existingId != null
                  ? 'Método de pago actualizado'
                  : 'Método de pago agregado',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setAsDefault(String methodId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Desmarcar todos los métodos como predeterminados
      final allMethods = await _firestore
          .collection('payment_methods')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (var doc in allMethods.docs) {
        await _firestore
            .collection('payment_methods')
            .doc(doc.id)
            .update({'isDefault': false});
      }

      // Marcar el seleccionado como predeterminado
      await _firestore
          .collection('payment_methods')
          .doc(methodId)
          .update({'isDefault': true});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Método de pago principal actualizado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePaymentMethod(String methodId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Método de Pago'),
        content: const Text('¿Estás seguro de que deseas eliminar este método de pago?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestore.collection('payment_methods').doc(methodId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Método de pago eliminado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
