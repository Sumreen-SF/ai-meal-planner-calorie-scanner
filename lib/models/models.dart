import 'dart:convert';

// ─── Meal Model ───────────────────────────────────────────────
class Meal {
  final String id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String mealType; // breakfast, lunch, dinner, snack
  final String? imagePath;
  final DateTime dateTime;
  final String? aiNote;

  Meal({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.mealType,
    this.imagePath,
    required this.dateTime,
    this.aiNote,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
    'mealType': mealType,
    'imagePath': imagePath,
    'dateTime': dateTime.toIso8601String(),
    'aiNote': aiNote,
  };

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
    id: json['id'],
    name: json['name'],
    calories: json['calories'],
    protein: (json['protein'] as num).toDouble(),
    carbs: (json['carbs'] as num).toDouble(),
    fat: (json['fat'] as num).toDouble(),
    fiber: (json['fiber'] as num).toDouble(),
    mealType: json['mealType'],
    imagePath: json['imagePath'],
    dateTime: DateTime.parse(json['dateTime']),
    aiNote: json['aiNote'],
  );
}

// ─── User Profile Model ───────────────────────────────────────
class UserProfile {
  final String name;
  final int age;
  final double weight; // kg
  final double height; // cm
  final String gender;
  final String goal; // lose_weight, gain_muscle, maintain, keto, vegan
  final int dailyCalorieGoal;
  final double proteinGoal;
  final double carbsGoal;
  final double fatGoal;

  UserProfile({
    required this.name,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.goal,
    required this.dailyCalorieGoal,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatGoal,
  });

  // Calculate BMR using Mifflin-St Jeor
  double get bmr {
    if (gender == 'male') {
      return 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      return 10 * weight + 6.25 * height - 5 * age - 161;
    }
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'weight': weight,
    'height': height,
    'gender': gender,
    'goal': goal,
    'dailyCalorieGoal': dailyCalorieGoal,
    'proteinGoal': proteinGoal,
    'carbsGoal': carbsGoal,
    'fatGoal': fatGoal,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'],
    age: json['age'],
    weight: (json['weight'] as num).toDouble(),
    height: (json['height'] as num).toDouble(),
    gender: json['gender'],
    goal: json['goal'],
    dailyCalorieGoal: json['dailyCalorieGoal'],
    proteinGoal: (json['proteinGoal'] as num).toDouble(),
    carbsGoal: (json['carbsGoal'] as num).toDouble(),
    fatGoal: (json['fatGoal'] as num).toDouble(),
  );

  static UserProfile get defaultProfile => UserProfile(
    name: 'User',
    age: 25,
    weight: 70,
    height: 170,
    gender: 'male',
    goal: 'maintain',
    dailyCalorieGoal: 2000,
    proteinGoal: 150,
    carbsGoal: 250,
    fatGoal: 65,
  );
}

// ─── Meal Plan Model ─────────────────────────────────────────
class DayMealPlan {
  final DateTime date;
  final List<PlannedMeal> meals;
  final String? aiInsight;

  DayMealPlan({
    required this.date,
    required this.meals,
    this.aiInsight,
  });

  int get totalCalories => meals.fold(0, (sum, m) => sum + m.calories);
}

class PlannedMeal {
  final String name;
  final String mealType;
  final int calories;
  final String? description;
  final List<String> ingredients;

  PlannedMeal({
    required this.name,
    required this.mealType,
    required this.calories,
    this.description,
    required this.ingredients,
  });

  factory PlannedMeal.fromJson(Map<String, dynamic> json) => PlannedMeal(
    name: json['name'] ?? '',
    mealType: json['mealType'] ?? 'lunch',
    calories: (json['calories'] as num?)?.toInt() ?? 0,
    description: json['description'],
    ingredients: List<String>.from(json['ingredients'] ?? []),
  );
}

// ─── Mood Meal Suggestion ─────────────────────────────────────
class MoodMealSuggestion {
  final String mood;
  final String emoji;
  final List<String> suggestions;
  final String reasoning;

  MoodMealSuggestion({
    required this.mood,
    required this.emoji,
    required this.suggestions,
    required this.reasoning,
  });
}

// ─── Scan Result ─────────────────────────────────────────────
class ScanResult {
  final String foodName;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String portionSize;
  final String healthScore; // A, B, C, D
  final List<String> tags;
  final String aiAnalysis;

  ScanResult({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.portionSize,
    required this.healthScore,
    required this.tags,
    required this.aiAnalysis,
  });
}