import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_key.dart';

class ReceiptScanResult {
  final double? amount;
  final String? merchant;
  final DateTime? date;
  final String category;
  final String? note;

  ReceiptScanResult({
    this.amount,
    this.merchant,
    this.date,
    this.category = 'Other',
    this.note,
  });

  factory ReceiptScanResult.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['date'];
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    return ReceiptScanResult(
      amount: (json['amount'] as num?)?.toDouble(),
      merchant: json['merchant'] as String?,
      date: parsedDate,
      category: (json['category'] as String?) ?? 'Other',
      note: json['note'] as String?,
    );
  }
}

class ReceiptScanException implements Exception {
  final String message;
  ReceiptScanException(this.message);

  @override
  String toString() => message;
}

class ReceiptScanService {
  static const _model = 'gemini-3.5-flash-lite';

  static const _prompt = '''
You are extracting structured expense data from a receipt image.
Return ONLY a valid JSON object (no markdown fences, no explanation, no extra text) with exactly these keys:

{
  "amount": <number, the final total paid, or null if unreadable>,
  "merchant": "<store/vendor name, or null>",
  "date": "<date on receipt in YYYY-MM-DD format, or null if not visible>",
  "category": "<one of exactly: Food, Groceries, Transport, Shopping, Bills, Entertainment, Health, Other>",
  "note": "<short 3-6 word summary of the purchase, e.g. 'Grocery shopping', 'Dinner with friends'>"
}

If the image is not a receipt or the data is not readable, still return the JSON with null/"Other" values as appropriate. Do not include any text outside the JSON object.
''';

  /// Sends a receipt image file to Gemini and returns the extracted expense data.
  static Future<ReceiptScanResult> scan(File imageFile, {String mimeType = 'image/jpeg'}) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$geminiApiKey',
      );

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": _prompt},
              {
                "inline_data": {
                  "mime_type": mimeType,
                  "data": base64Image,
                }
              }
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
        debugPrint('ReceiptScan HTTP error ${response.statusCode}: ${response.body}');
        throw ReceiptScanException('Receipt scan failed (${response.statusCode}). Try again.');
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
        debugPrint('ReceiptScan: no text in response. Full body: ${response.body}');
        throw ReceiptScanException('AI se koi response nahi mila. Dobara try karein.');
      }

      final cleaned = text.replaceAll(RegExp(r'```json|```'), '').trim();
      Map<String, dynamic> parsed;
      try {
        parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('ReceiptScan: JSON parse failed. Raw text was: $text');
        rethrow;
      }
      return ReceiptScanResult.fromJson(parsed);
    } on ReceiptScanException {
      rethrow;
    } catch (e, st) {
      debugPrint('ReceiptScan unexpected error: $e\n$st');
      throw ReceiptScanException('Receipt padh nahi saka. Dobara try karein ya manually add karein.');
    }
  }
}