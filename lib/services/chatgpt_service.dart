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
                  'Eres un asistente médico virtual. Proporciona recomendaciones '
                  'breves y claras sobre qué tipo de especialista consultar según los '
                  'síntomas. Siempre recomienda consultar a un profesional de la salud '
                  'y nunca proporciones diagnósticos definitivos.',
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
