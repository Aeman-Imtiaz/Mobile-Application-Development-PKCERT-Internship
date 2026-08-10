import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Stores extra profile/settings data locally (per user), since Firebase Auth
/// only natively supports name, email & photo URL — not age or budget.
class UserPrefsService {
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static String _key(String field) => '${_uid}_$field';

  static Future<void> setAge(int age) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key('age'), age);
  }

  static Future<int?> getAge() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key('age'));
  }

  static Future<void> setPhotoPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key('photoPath'), path);
  }

  static Future<String?> getPhotoPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key('photoPath'));
  }

  static Future<void> setMonthlyBudget(double budget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key('monthlyBudget'), budget);
  }

  static Future<double?> getMonthlyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_key('monthlyBudget'));
  }
  static Future<void> setDailyBudget(double budget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key('dailyBudget'), budget);
  }

  static Future<double?> getDailyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_key('dailyBudget'));
  }
  
}
