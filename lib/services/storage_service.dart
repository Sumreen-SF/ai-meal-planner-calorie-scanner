import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const String _mealsKey = 'logged_meals';
  static const String _profileKey = 'user_profile';

  // ── Meals ─────────────────────────────────────────────────────
  static Future<List<Meal>> getMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_mealsKey);
    if (data == null) return [];
    final List<dynamic> json = jsonDecode(data);
    return json.map((j) => Meal.fromJson(j)).toList();
  }

  static Future<void> saveMeal(Meal meal) async {
    final meals = await getMeals();
    meals.add(meal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mealsKey, jsonEncode(meals.map((m) => m.toJson()).toList()));
  }

  static Future<void> deleteMeal(String id) async {
    final meals = await getMeals();
    meals.removeWhere((m) => m.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mealsKey, jsonEncode(meals.map((m) => m.toJson()).toList()));
  }

  static Future<List<Meal>> getMealsForDate(DateTime date) async {
    final all = await getMeals();
    return all.where((m) =>
    m.dateTime.year == date.year &&
        m.dateTime.month == date.month &&
        m.dateTime.day == date.day).toList();
  }

  static Future<Map<String, int>> getWeeklyCalories() async {
    final all = await getMeals();
    final Map<String, int> weekly = {};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = '${day.month}/${day.day}';
      final dayMeals = all.where((m) =>
      m.dateTime.year == day.year &&
          m.dateTime.month == day.month &&
          m.dateTime.day == day.day);
      weekly[key] = dayMeals.fold(0, (sum, m) => sum + m.calories);
    }
    return weekly;
  }

  // ── Profile ───────────────────────────────────────────────────
  static Future<UserProfile> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_profileKey);
    if (data == null) return UserProfile.defaultProfile;
    return UserProfile.fromJson(jsonDecode(data));
  }

  static Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }
}