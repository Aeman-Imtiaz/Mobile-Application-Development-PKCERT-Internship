import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_key.dart';

class CategorizationService {
  static const List<String> categories = [
  'Food',
  'Fee',
  'Oil',
  'Fare',
  'Donation',
  'Utilities',
  'Shopping',
  'Bills',
  'Entertainment',
  'Health',
  'Other',
];

  static Future<String> categorize(String description) async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey',
      );

      final prompt =
          "Classify this expense description into exactly ONE of these categories: "
          "${categories.join(', ')}. "
          "Reply with ONLY the category word, nothing else. "
          "Description: \"$description\"";

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text']
            .toString()
            .trim();

        for (final cat in categories) {
          if (text.toLowerCase().contains(cat.toLowerCase())) {
            return cat;
          }
        }
        return 'Other';
      } else {
        return _keywordFallback(description);
      }
    } catch (e) {
      return _keywordFallback(description);
    }
  }

  static String _keywordFallback(String description) {
  final desc = description.toLowerCase();

  const foodWords = [
    'pizza',
    'burger',
    'lunch',
    'dinner',
    'coffee',
    'restaurant',
    'food',
    'breakfast'
  ];

  const feeWords = [
    'fee',
    'tuition',
    'school fee',
    'college fee',
    'university fee',
    'admission'
  ];

  const oilWords = [
    'petrol',
    'diesel',
    'fuel',
    'oil',
    'cng',
    'gas station'
  ];

  const fareWords = [
    'bus',
    'uber',
    'careem',
    'taxi',
    'rickshaw',
    'train',
    'ticket',
    'fare'
  ];

  const donationWords = [
    'donation',
    'charity',
    'zakat',
    'sadqa',
    'masjid',
    'ngo'
  ];

  const utilityWords = [
    'electricity',
    'wapda',
    'gas bill',
    'water bill',
    'internet',
    'wifi',
    'phone bill'
  ];

  const shoppingWords = [
    'clothes',
    'shoes',
    'mall',
    'amazon',
    'shopping',
    'store'
  ];

  const billWords = [
    'rent',
    'installment'
  ];

  const entertainmentWords = [
    'movie',
    'netflix',
    'game',
    'concert',
    'cinema'
  ];

  const healthWords = [
    'doctor',
    'medicine',
    'pharmacy',
    'hospital',
    'gym'
  ];

  if (foodWords.any((w) => desc.contains(w))) return 'Food';
  if (feeWords.any((w) => desc.contains(w))) return 'Fee';
  if (oilWords.any((w) => desc.contains(w))) return 'Oil';
  if (fareWords.any((w) => desc.contains(w))) return 'Fare';
  if (donationWords.any((w) => desc.contains(w))) return 'Donation';
  if (utilityWords.any((w) => desc.contains(w))) return 'Utilities';
  if (shoppingWords.any((w) => desc.contains(w))) return 'Shopping';
  if (billWords.any((w) => desc.contains(w))) return 'Bills';
  if (entertainmentWords.any((w) => desc.contains(w))) return 'Entertainment';
  if (healthWords.any((w) => desc.contains(w))) return 'Health';

  return 'Other';
}
}