import 'package:flutter/material.dart';
import 'medico_page.dart';

class SpecialtySelectionPage extends StatelessWidget {
  const SpecialtySelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Doctor'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner superior con búsqueda
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Encuentra Doctores',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecciona una especialidad',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Barra de búsqueda
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Buscar especialidades...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Icon(Icons.mic, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Sección de Respuestas de Especialistas
            _buildSpecialistsAnswersSection(context),

            const SizedBox(height: 24),

            // Sección de especialidades
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buscar Doctor por Especialidad',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Grid de especialidades
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                    children: [
                      _buildSpecialtyCard(
                        context,
                        icon: Icons.local_hospital,
                        label: 'Medicina\nGeneral',
                        specialty: 'Medicina General',
                        color: Colors.blue,
                      ),
                      _buildSpecialtyCard(
                        context,
                        icon: Icons.face,
                        label: 'Dermatología',
                        specialty: 'Dermatología',
                        color: Colors.pink,
                      ),
                      _buildSpecialtyCard(
                        context,
                        icon: Icons.psychology,
                        label: 'Psiquiatría',
                        specialty: 'Psiquiatría',
                        color: Colors.purple,
                      ),
                      _buildSpecialtyCard(
                        context,
                        icon: Icons.hearing,
                        label: 'ENT',
                        specialty: 'Otorrinolaringología',
                        color: Colors.orange,
                      ),
                      _buildSpecialtyCard(
                        context,
                        icon: Icons.pregnant_woman,
                        label: 'Salud\nFemenina',
                        specialty: 'Ginecología',
                        color: Colors.red[300]!,
                      ),
                      _buildSpecialtyCard(
                        context,
                        icon: Icons.favorite,
                        label: 'Cardiología',
                        specialty: 'Cardiología',
                        color: Colors.red,
                      ),
                      _buildSpecialtyCard(
                        context,
                        icon: Icons.air,
                        label: 'Neumología',
                        specialty: 'Neumología',
                        color: Colors.teal,
                      ),
                      _buildSpecialtyCard(
                        context,
                        icon: Icons.child_care,
                        label: 'Pediatría',
                        specialty: 'Pediatría',
                        color: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Sección de consultas online
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                color: Theme.of(context).colorScheme.primary,
                child: InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.video_call,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Consultas Online',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Atención médica desde casa',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Sección de Opiniones más recientes
            _buildRecentOpinionsSection(context),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Sección de Respuestas de Especialistas
  Widget _buildSpecialistsAnswersSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Respuestas de especialistas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Acción para agregar comentario
                  _showAddCommentDialog(context);
                },
                icon: const Icon(Icons.add_comment, size: 20),
                label: const Text('Agregar'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Card de ejemplo de pregunta
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hola el ovulo ginothyl tiene cositas blancas adentro, es normal?',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'RESPUESTA DEL PROFESIONAL:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue[100],
                        child: const Icon(Icons.person, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dra. Mirkell Marrufo Peralta',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Hola, el Ginothyl es policesuleno, ayuda a regenerar y cauterizar lesiones inflamatorias...',
                              style: TextStyle(fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Ver más'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sección de Opiniones más recientes
  Widget _buildRecentOpinionsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Opiniones más recientes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          // Opinión 1
          _buildOpinionCard(
            context,
            name: 'Víctor Valdivia Calderón',
            opinion: 'A mi Madre le gusto mucho la experiencia, explicación detallada',
            author: 'Marco Precilla',
            rating: 5,
          ),
          const SizedBox(height: 12),
          // Opinión 2
          _buildOpinionCard(
            context,
            name: 'Jorge Antonio Delgado Castillo',
            opinion: 'Mientras atendía a mi hijo me dijo, yo soy cojito, y no permito que un niño se quede sin caminar...',
            author: 'mcaa',
            rating: 5,
          ),
          const SizedBox(height: 12),
          // Opinión 3
          _buildOpinionCard(
            context,
            name: 'Amanda Rivera Bustamante',
            opinion: 'Es todo lo que esperas de una consulta, un especialista que escuche y se tome el tiempo necesario...',
            author: 'Licero',
            rating: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildOpinionCard(
    BuildContext context, {
    required String name,
    required String opinion,
    required String author,
    required int rating,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue[100],
                  child: const Icon(Icons.person, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(
                          rating,
                          (index) => const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              opinion,
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              author,
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCommentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Agregar Comentario'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Tu pregunta',
                  hintText: 'Escribe tu pregunta aquí...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // Lógica para enviar comentario
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Comentario enviado'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpecialtyCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String specialty,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MedicoPage(
              selectedSpecialty: specialty,
            ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
