import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../config/api_key.dart';
import '../db/database_helper.dart';

class ChatService {
  /// Builds a text summary of the user's financial data to give Gemini context.
  static Future<String> _buildContext() async {
    final allExpenses = await DatabaseHelper.instance.getAllExpenses();
    final totals = await DatabaseHelper.instance.getTotals();

    if (allExpenses.isEmpty) {
      return "The user has no transactions recorded yet.";
    }

    final buffer = StringBuffer();
    buffer.writeln("Overall totals:");
    buffer.writeln("- Total Cash In: Rs. ${totals['cashIn']!.toStringAsFixed(0)}");
    buffer.writeln("- Total Cash Out: Rs. ${totals['cashOut']!.toStringAsFixed(0)}");
    buffer.writeln("- Net Balance: Rs. ${totals['balance']!.toStringAsFixed(0)}");
    buffer.writeln();
    buffer.writeln("Transaction list (date, type, amount, description, category, payment mode):");

    for (final e in allExpenses) {
      final date = DateFormat('dd MMM yyyy').format(DateTime.parse(e['date'] as String));
      final type = e['type'] == 'cash_in' ? 'Income' : 'Expense';
      buffer.writeln(
        "- $date | $type | Rs. ${(e['amount'] as double).toStringAsFixed(0)} | "
        "${e['description']} | ${e['category']} | ${e['paymentMode']}",
      );
    }

    return buffer.toString();
  }

  /// Sends the user's question + their financial data to Gemini and returns the answer.
  static Future<String> askQuestion(String question) async {
    try {
      final context = await _buildContext();

    final url = Uri.parse(
'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=$geminiApiKey',
);

      final prompt = """
You are "Wise" — a warm, friendly personal finance assistant inside a Pakistani
expense-tracking app called SpendWise. Your users are Pakistani, so respond in
the same style they write in: if they write in Roman Urdu (Urdu written in
English letters, e.g. "kitna kharcha hua"), reply naturally in a friendly mix
of Roman Urdu and English — the way Pakistanis casually text each other. If
they write in plain English, reply in English. Never use Urdu script, only
Roman Urdu.

Keep answers short, warm, and conversational — like a smart dost helping with
money matters, not a corporate report. Always use "Rs." for currency amounts.
Answer using ONLY the financial data given below. If the data isn't enough to
answer confidently, say so honestly instead of guessing.

FINANCIAL DATA:
$context

USER QUESTION:
$question
""";

      print('🔄 Sending request to Gemini API...');
      print('API Key length: ${geminiApiKey.length}');
      
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

      print('✅ API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'].toString().trim();
        return text;
      } else if (response.statusCode == 429) {
        print('⚠️ GEMINI QUOTA ERROR 429: ${response.body}');
        return "Gemini quota exhausted. Please wait a moment or check your API billing at https://console.cloud.google.com/";
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('❌ GEMINI AUTH ERROR ${response.statusCode}: ${response.body}');
        return "API key invalid or unauthorized. Please check your Gemini API key in app settings.";
      } else {
        print('❌ GEMINI ERROR ${response.statusCode}: ${response.body}');
        // Provide helpful fallback based on question
        return _getFallbackResponse(question, context);
      }
    } catch (e) {
      print('❌ GEMINI EXCEPTION: $e');
      return "Network error. Please check your internet connection and try again.";
    }
  }

  /// Provides smart fallback responses when API is unavailable
  static String _getFallbackResponse(String question, String context) {
    final lowerQuestion = question.toLowerCase();
    
    // Check for common questions
    if (lowerQuestion.contains('kharcha') || lowerQuestion.contains('expense') || lowerQuestion.contains('spend')) {
      return "📊 Main API temporarily unavailable. Check your Expenses or Summary tab for detailed spending breakdown.";
    }
    
    if (lowerQuestion.contains('saving') || lowerQuestion.contains('kitna bacha') || lowerQuestion.contains('balance')) {
      return "💰 Check your Summary tab to see your current balance and savings.";
    }
    
    if (lowerQuestion.contains('category') || lowerQuestion.contains('kategori')) {
      return "📁 View your spending by category in the Summary tab for detailed analysis.";
    }
    
    return "🔌 API temporarily unavailable. Please check:\n1. Your internet connection\n2. API key in settings\n3. Gemini API quota at https://ai.google.dev/quota";
  }

  /// Generates a longer, more detailed financial analysis — used as the
  /// "reward" after the user watches a rewarded ad.
  static Future<String> getDeepInsight() async {
    try {
      final context = await _buildContext();

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=$geminiApiKey',
      );

      final prompt = """
You are "Wise", a financial analyst for the Pakistani expense-tracking app
SpendWise. The user has just unlocked a "Deep Insight" by watching a reward
video ad — give them something genuinely valuable in return.
Write a detailed but easy-to-read financial analysis (5-8 sentences) covering:
1. Their overall spending pattern this period (which categories dominate).
2. Any category where spending looks unusually high compared to others.
3. One concrete, practical suggestion to save money next month.
4. An encouraging, warm closing line.
Respond in a natural mix of Roman Urdu and English (like a Pakistani texting
casually), never Urdu script. Use "Rs." for currency. Do not use markdown
headers or bullet points — write it as warm, flowing paragraphs.
FINANCIAL DATA:
$context
""";

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
        return (data['candidates'][0]['content']['parts'][0]['text'] as String).trim();
      }

      print('❌ GEMINI DEEP INSIGHT ERROR ${response.statusCode}: ${response.body}');
      return "Sorry, insight generate nahi ho saka. Please try again.";
    } catch (e) {
      print('❌ GEMINI DEEP INSIGHT EXCEPTION: $e');
      return "Something went wrong. Please check your internet connection.";
    }
  }
}