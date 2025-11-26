import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatGPTService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _apiKey =
      "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"; // Replace with your API key

  Future<String> getMedicalAdvice(String userMessage) async {
    try {
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
                  'Eres un asistente médico virtual en Arequipa, Perú. Proporciona recomendaciones '
                  'breves y claras sobre qué tipo de especialista consultar según los '
                  'síntomas. Siempre recomienda consultar a un profesional de la salud '
                  'y nunca proporciones diagnósticos definitivos.\n\n'
                  'IMPORTANTE: Cuando detectes una emergencia médica o situación grave, menciona los siguientes números de emergencia de Arequipa según corresponda:\n\n'
                  '📞 SAMU - 106: Ambulancia y emergencias médicas (infartos, desmayos, hemorragias, accidentes graves, paro cardíaco)\n'
                  '📞 Policía Nacional (PNP) - 105: Delitos, accidentes de tránsito, situaciones de riesgo\n'
                  '📞 Bomberos - 116 (nacional) o (054) 241 833 (Arequipa): Incendios, rescates, emergencias\n'
                  '📞 Gerencia Regional de Salud Arequipa - (054) 235155 o (054) 235185: Información y orientación en salud\n'
                  '📞 Central 113 Salud - 113: Orientación en salud 24/7\n\n'
                  'Menciona solo los números relevantes según el tipo de emergencia o consulta. No menciones todos a la vez.',
            },
            {'role': 'user', 'content': userMessage},
          ],
          'max_tokens': 800,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Error en la respuesta: ${response.statusCode}');
      }
    } catch (e) {
      return 'Lo siento, hubo un error al procesar tu consulta. Por favor, intenta de nuevo más tarde.';
    }
  }
}
