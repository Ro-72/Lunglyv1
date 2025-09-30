import 'package:flutter/material.dart';

class MedicoPage extends StatelessWidget {
  const MedicoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.medical_services,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consulta Médica',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gestiona tus citas y consultas',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Opciones Médicas',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            context,
            icon: Icons.calendar_today,
            title: 'Agendar Cita',
            subtitle: 'Programa una nueva consulta',
            color: Colors.blue,
            onTap: () {
              // Navigate to schedule appointment
            },
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            context,
            icon: Icons.list_alt,
            title: 'Mis Citas',
            subtitle: 'Ver citas programadas',
            color: Colors.green,
            onTap: () {
              // Navigate to appointments list
            },
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            context,
            icon: Icons.history,
            title: 'Historial Médico',
            subtitle: 'Consulta tu historial',
            color: Colors.orange,
            onTap: () {
              // Navigate to medical history
            },
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            context,
            icon: Icons.description,
            title: 'Recetas',
            subtitle: 'Ver recetas médicas',
            color: Colors.purple,
            onTap: () {
              // Navigate to prescriptions
            },
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            context,
            icon: Icons.emergency,
            title: 'Emergencia',
            subtitle: 'Contacto de emergencia',
            color: Colors.red,
            onTap: () {
              // Navigate to emergency contact
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
