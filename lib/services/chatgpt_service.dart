import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatGPTService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _apiKey =
      "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"; // Replace with your API key

  // Emergency contact definitions
  static const Map<String, Map<String, dynamic>> _emergencyContacts = {
    'samu': {
      'number': '106',
      'name': 'SAMU (Sistema de Atención Móvil de Urgencia)',
      'description': 'Ambulancia y emergencias médicas',
      'keywords': [
        'ambulancia',
        'emergencia médica',
        'urgencia médica',
        'infarto',
        'desmayo',
        'hemorragia',
        'accidente grave',
        'paro cardíaco',
        'no respira',
        'inconsciente'
      ],
    },
    'police': {
      'number': '105',
      'name': 'Policía Nacional del Perú (PNP)',
      'description': 'Delitos, accidentes de tránsito, situaciones de riesgo',
      'keywords': [
        'policía',
        'robo',
        'asalto',
        'accidente de tránsito',
        'choque',
        'delito',
        'violencia',
        'agresión',
        'inseguridad'
      ],
    },
    'bomberos': {
      'number': '116 (nacional) o (054) 241 833 (Arequipa)',
      'name': 'Bomberos',
      'description': 'Incendios, rescates y emergencias',
      'keywords': [
        'incendio',
        'fuego',
        'quemadura grave',
        'rescate',
        'atrapado',
        'bomberos',
        'explosión'
      ],
    },
    'salud_arequipa': {
      'number': '(054) 235155 o (054) 235185',
      'name': 'Gerencia Regional de Salud Arequipa',
      'description': 'Información y orientación en salud',
      'keywords': [
        'información de salud',
        'orientación médica arequipa',
        'salud arequipa',
        'hospital arequipa'
      ],
    },
    'central_113': {
      'number': '113',
      'name': 'Central 113 Salud',
      'description': 'Orientación en salud 24/7',
      'keywords': [
        'orientación médica',
        'consulta de salud',
        'síntomas',
        'consejos de salud',
        'duda médica',
        'qué hacer'
      ],
    },
  };

  /// Detects emergency keywords in user message and returns relevant contacts
  String _detectEmergencyContacts(String userMessage) {
    final messageLower = userMessage.toLowerCase();
    final relevantContacts = <String>[];

    // Check each emergency contact for keyword matches
    _emergencyContacts.forEach((key, contact) {
      final keywords = contact['keywords'] as List<String>;
      for (final keyword in keywords) {
        if (messageLower.contains(keyword.toLowerCase())) {
          relevantContacts.add(
            '\n📞 ${contact['name']}\n'
            '   Número: ${contact['number']}\n'
            '   ${contact['description']}'
          );
          break; // Don't add the same contact multiple times
        }
      }
    });

    if (relevantContacts.isNotEmpty) {
      return '\n\n🚨 NÚMEROS DE EMERGENCIA:\n${relevantContacts.join('\n')}';
    }

    return '';
  }

  Future<String> getMedicalAdvice(String userMessage) async {
    try {
      // Detect if emergency contacts are needed
      final emergencyInfo = _detectEmergencyContacts(userMessage);

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4.1-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Eres un asistente médico virtual. Proporciona recomendaciones '
                  'breves y claras sobre qué tipo de especialista consultar según los '
                  'síntomas. Siempre recomienda consultar a un profesional de la salud '
                  'y nunca proporciones diagnósticos definitivos. Si detectas una emergencia '
                  'médica grave, enfatiza la importancia de llamar a servicios de emergencia.',
            },
            {'role': 'user', 'content': userMessage},
          ],
          'max_tokens': 800,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];

        // Append emergency contacts if relevant
        return aiResponse + emergencyInfo;
      } else {
        throw Exception('Error en la respuesta: ${response.statusCode}');
      }
    } catch (e) {
      return 'Lo siento, hubo un error al procesar tu consulta. Por favor, intenta de nuevo más tarde.';
    }
  }
}
