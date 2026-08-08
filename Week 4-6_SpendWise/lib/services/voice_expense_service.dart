import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_key.dart';

class VoiceExpenseResult {
  final double? amount;
  final String type; // 'cash_in' or 'cash_out'
  final String? description;

  VoiceExpenseResult({
    this.amount,
    this.type = 'cash_out',
    this.description,
  });

  factory VoiceExpenseResult.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] as String?)?.toLowerCase().trim();
    return VoiceExpenseResult(
      amount: (json['amount'] as num?)?.toDouble(),
      type: rawType == 'cash_in' ? 'cash_in' : 'cash_out',
      description: json['description'] as String?,
    );
  }
}

class VoiceExpenseException implements Exception {
  final String message;
  VoiceExpenseException(this.message);

  @override
  String toString() => message;
}

class VoiceExpenseService {
  static const _model = 'gemini-3.5-flash-lite';

  static const _promptTemplate = '''
You are extracting structured expense data from a spoken sentence. The sentence may mix Urdu and English (Roman Urdu or Urdu script), and may mention money in "rupay" / "Rs" / "PKR".

Spoken text: "{TEXT}"

Return ONLY a valid JSON object (no markdown fences, no explanation, no extra text) with exactly these keys:

{
  "amount": <number, the amount of money mentioned, or null if not clear>,
  "type": "<'cash_in' if the person received/earned money (e.g. salary, refund, received from someone), otherwise 'cash_out'>",
  "description": "<short 3-6 word English description of what the money was for, e.g. 'Tea at cafe', 'Grocery shopping'>"
}

Do not include any text outside the JSON object.
''';

  /// Sends transcribed speech text to Gemini and returns extracted expense data.
  static Future<VoiceExpenseResult> parse(String spokenText) async {
    if (spokenText.trim().isEmpty) {
      throw VoiceExpenseException('Kuch sunayi nahi diya. Dobara try karein.');
    }

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$geminiApiKey',
      );

      final prompt = _promptTemplate.replaceAll('{TEXT}', spokenText.trim());

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
            ]
          }
        ]
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        throw VoiceExpenseException('AI se baat nahi ho saki (${response.statusCode}). Dobara try karein.');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      String? text;
      final candidates = decoded['candidates'];
      if (candidates is List && candidates.isNotEmpty) {
        final firstCandidate = candidates[0] as Map<String, dynamic>;
        final content = firstCandidate['content'] as Map<String, dynamic>?;
        final parts = content?['parts'];
        if (parts is List && parts.isNotEmpty) {
          final firstPart = parts[0] as Map<String, dynamic>;
          text = firstPart['text'] as String?;
        }
      }

      if (text == null || text.trim().isEmpty) {
        throw VoiceExpenseException('AI se koi response nahi mila. Dobara try karein.');
      }

      final cleaned = text.replaceAll(RegExp(r'```json|```'), '').trim();
      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      return VoiceExpenseResult.fromJson(parsed);
    } on VoiceExpenseException {
      rethrow;
    } catch (e) {
      throw VoiceExpenseException('Samajh nahi saka. Dobara try karein ya manually add karein.');
    }
  }
}