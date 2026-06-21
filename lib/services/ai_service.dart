import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class AIServiceException implements Exception {
  final String message;
  final int? statusCode;
  AIServiceException(this.message, {this.statusCode});
  @override
  String toString() =>
      statusCode != null ? 'AI Error $statusCode: $message' : 'AI Error: $message';
}

class AIService {
  static const String _openRouterToken = const String.fromEnvironment('OPENROUTER_API_KEY');
  static const String _model = 'google/gemini-2.5-flash';
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  // ── Core HTTP call ────────────────────────────────────────────
  static Future<String> _callGrok(
      String userPrompt, {
        String systemPrompt = '',
        int maxTokens = 512,
      }) async {
    final token = _openRouterToken.trim();
    if (token.isEmpty || token.contains('YOUR_')) {
      throw AIServiceException(
        'OpenRouter API key not set. Please update lib/services/ai_service.dart with your key from openrouter.ai/keys',
      );
    }

    final messages = <Map<String, String>>[
      if (systemPrompt.isNotEmpty) {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt},
    ];

    debugPrint('[AIService] Requesting OpenRouter with $_model...');

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'HTTP-Referer': 'https://localhost:8080',
          'X-Title': 'Flutter Nutrition App',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': 0.7,
          'stream': false,
        }),
      ).timeout(const Duration(seconds: 45));

      debugPrint('[AIService] Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] as String?;
        if (content == null || content.isEmpty) {
          throw AIServiceException('The AI returned an empty response.');
        }
        return content.trim();
      }

      String errorMessage = response.body;
      try {
        final errorBody = jsonDecode(response.body);
        errorMessage = errorBody['error']?.toString() ?? response.body;
      } catch (_) {}

      if (response.statusCode == 401) throw AIServiceException('Unauthorized: Your OpenRouter API key is invalid or has expired.', statusCode: 401);
      if (response.statusCode == 429) throw AIServiceException('Rate limit exceeded or insufficient OpenRouter credits.', statusCode: 429);
      if (response.statusCode == 404) throw AIServiceException('Model not found or unavailable on OpenRouter.', statusCode: 404);

      throw AIServiceException(errorMessage, statusCode: response.statusCode);

    } on TimeoutException {
      throw AIServiceException('Request timed out. Please check your connection.');
    } on SocketException {
      throw AIServiceException('No internet connection. Please check your network.');
    } catch (e) {
      if (e is AIServiceException) rethrow;
      throw AIServiceException('Unexpected error: $e');
    }
  }

  // ── JSON extractor ────────────────────────────────────────────
  static dynamic _parseJson(String raw, String context) {
    // 1. Direct parse
    try { return jsonDecode(raw.trim()); } catch (_) {}

    // 2. Strip ```json ... ``` fences
    final fenceMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(raw);
    if (fenceMatch != null) {
      try { return jsonDecode(fenceMatch.group(1)!.trim()); } catch (_) {}
    }

    // 3. Extract first { } or [ ] block (handles preamble text)
    final blockMatch = RegExp(r'(\{[\s\S]*\}|\[[\s\S]*\])').firstMatch(raw);
    if (blockMatch != null) {
      try { return jsonDecode(blockMatch.group(1)!.trim()); } catch (_) {}
    }

    throw AIServiceException('Failed to process $context data. The AI returned an invalid format.');
  }

  // ── Food Scanner ──────────────────────────────────────────────
  static Future<ScanResult> analyzeFoodText(String food) async {
    const system = 'You are a professional nutritionist. Respond ONLY with valid JSON, no markdown, no extra text.';
    final prompt =
        'Analyze "$food". Return ONLY this JSON with real values:\n'
        '{"foodName":"$food","calories":250,"protein":12.0,"carbs":30.0,"fat":8.0,"fiber":3.0,'
        '"portionSize":"1 serving (200g)","healthScore":"B","tags":["Balanced"],'
        '"aiAnalysis":"A balanced meal providing essential nutrients."}';

    final raw = await _callGrok(prompt, systemPrompt: system, maxTokens: 400);
    final j = _parseJson(raw, 'food analysis');

    return ScanResult(
      foodName:    j['foodName']    ?? food,
      calories:    (j['calories']   as num?)?.toInt()    ?? 0,
      protein:     (j['protein']    as num?)?.toDouble() ?? 0,
      carbs:       (j['carbs']      as num?)?.toDouble() ?? 0,
      fat:         (j['fat']        as num?)?.toDouble() ?? 0,
      fiber:       (j['fiber']      as num?)?.toDouble() ?? 0,
      portionSize: j['portionSize'] ?? '1 serving',
      healthScore: j['healthScore'] ?? 'B',
      tags:        List<String>.from(j['tags'] ?? []),
      aiAnalysis:  j['aiAnalysis']  ?? '',
    );
  }

  // ── Meal Plan ─────────────────────────────────────────────────
  static Future<List<PlannedMeal>> generateDayPlan({
    required UserProfile profile,
    required String preferences,
  }) async {
    const system = 'You are a professional dietitian. Respond ONLY with a valid JSON array, no markdown, no extra text.';
    final prompt =
        'Create a 4-meal plan for ${profile.dailyCalorieGoal} kcal. '
        'Goal: ${profile.goal}. Prefs: $preferences.\n'
        'Return ONLY a JSON array:\n'
        '[{"name":"","mealType":"breakfast","calories":0,"description":"","ingredients":[]}]';

    final raw = await _callGrok(prompt, systemPrompt: system, maxTokens: 800);
    final list = _parseJson(raw, 'meal plan') as List<dynamic>;
    return list.map((j) => PlannedMeal.fromJson(j as Map<String, dynamic>)).toList();
  }

  // ── Mood Meals — NEVER throws, always returns content ─────────
  static Future<MoodMealSuggestion> getMoodMealSuggestion({
    required String mood,
    required String emoji,
    required UserProfile profile,
  }) async {
    // Always get local fallback ready first
    final fallback = _moodFallbacks[mood] ?? _moodFallbacks['Chill']!;

    try {
      const system =
          'You are a nutritional psychologist and chef. '
          'Respond ONLY with valid JSON. No markdown, no explanation, no extra text.';
      final prompt =
          'The user feels $mood. Their diet goal is ${profile.goal}.\n'
          'Suggest exactly 3 specific meal names backed by nutrition science for this mood.\n'
          'Return ONLY this JSON:\n'
          '{"suggestions":["Meal Name One","Meal Name Two","Meal Name Three"],'
          '"reasoning":"One or two sentences about why these foods help with $mood."}';

      final raw = await _callGrok(prompt, systemPrompt: system, maxTokens: 400);
      debugPrint('[Mood] Raw response: $raw');

      // Try to parse
      dynamic j;
      try {
        j = _parseJson(raw, 'mood meals');
      } catch (_) {
        debugPrint('[Mood] Parse failed — using local fallback');
        return _buildFallback(mood, emoji, fallback);
      }

      // Validate suggestions is a proper non-empty list of strings
      final rawSuggestions = j['suggestions'];
      List<String> suggestions = [];
      if (rawSuggestions is List) {
        suggestions = rawSuggestions
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty && e.length > 2)
            .toList();
      }

      // If AI gave bad suggestions, use fallback meals but keep AI reasoning
      if (suggestions.isEmpty) {
        suggestions = fallback['suggestions']!;
      }

      final reasoning = (j['reasoning'] as String?)?.trim();

      return MoodMealSuggestion(
        mood: mood,
        emoji: emoji,
        suggestions: suggestions,
        reasoning: (reasoning != null && reasoning.length > 10)
            ? reasoning
            : fallback['reasoning']!.first,
      );
    } catch (e) {
      // Any network/API error — silently use local fallback, no error shown
      debugPrint('[Mood] Error — using fallback: $e');
      return _buildFallback(mood, emoji, fallback);
    }
  }

  static MoodMealSuggestion _buildFallback(
      String mood, String emoji, Map<String, List<String>> data) {
    return MoodMealSuggestion(
      mood: mood,
      emoji: emoji,
      suggestions: data['suggestions']!,
      reasoning: data['reasoning']!.first,
    );
  }

  // ── Pantry Oracle ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getPantryMealIdeas({
    required List<String> ingredients,
    required UserProfile profile,
    required int maxCalories,
  }) async {
    const system = 'You are a creative chef. Respond ONLY with a valid JSON array, no markdown, no extra text.';
    final prompt =
        'Create 3 recipes using these ingredients: ${ingredients.join(", ")}.\n'
        'Max $maxCalories kcal per meal. Diet goal: ${profile.goal}.\n'
        'Return ONLY a JSON array:\n'
        '[{"name":"","prepTime":"15 min","calories":0,"difficulty":"Easy",'
        '"steps":["step1","step2"],"missingIngredients":[],"nutritionHighlight":""}]';

    final raw = await _callGrok(prompt, systemPrompt: system, maxTokens: 800);
    final list = _parseJson(raw, 'pantry recipes') as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  // ── Daily Insight ─────────────────────────────────────────────
  static Future<String> getDailyInsight({
    required int caloriesConsumed,
    required int caloriesGoal,
    required double proteinConsumed,
    required List<String> mealsEaten,
  }) async {
    const system = 'You are a friendly nutritionist. Respond ONLY with a JSON object.';
    final prompt =
        'Today: $caloriesConsumed/$caloriesGoal kcal, '
        '${proteinConsumed.toStringAsFixed(0)}g protein. '
        'Meals: ${mealsEaten.isEmpty ? "none yet" : mealsEaten.join(", ")}.\n'
        'Return ONLY: {"insight":"2 motivating sentences + 1 actionable tip"}';

    try {
      final raw = await _callGrok(prompt, systemPrompt: system, maxTokens: 200);
      final j = _parseJson(raw, 'insight');
      final text = j['insight'] as String?;
      return (text != null && text.length > 10) ? text : _fallbackInsight(caloriesConsumed, caloriesGoal);
    } catch (_) {
      return _fallbackInsight(caloriesConsumed, caloriesGoal);
    }
  }

  static String _fallbackInsight(int consumed, int goal) {
    final pct = goal > 0 ? consumed / goal : 0.0;
    if (consumed == 0) return 'Start logging meals to get AI insights! Every meal tracked brings you closer to your goal.';
    if (pct < 0.5)    return 'You\'re off to a light start — fuel your body! Aim for a balanced lunch with protein and complex carbs.';
    if (pct < 0.9)    return 'Great progress! You\'re on track with your calorie goal. Consider a healthy snack if you feel hungry.';
    if (pct < 1.1)    return 'You\'ve hit your calorie goal — well done! Focus on hydration for the rest of the day.';
    return 'Slightly over today — that\'s okay! Balance it out tomorrow with lighter meals and some extra activity.';
  }

  // ── Local mood fallbacks — shown when AI fails or parses badly ─
  static const Map<String, Map<String, List<String>>> _moodFallbacks = {
    'Energized': {
      'suggestions': ['Banana & Peanut Butter Toast', 'Greek Yogurt with Granola & Berries', 'Chicken & Quinoa Power Bowl'],
      'reasoning': ['Carbohydrates and protein together sustain energy and support dopamine production, keeping you feeling powerful all day.'],
    },
    'Stressed': {
      'suggestions': ['Dark Chocolate & Walnut Snack', 'Spinach & Avocado Salad', 'Warm Oatmeal with Chamomile Tea'],
      'reasoning': ['Magnesium in dark chocolate and walnuts lowers cortisol levels. Leafy greens provide folate which supports serotonin synthesis.'],
    },
    'Happy': {
      'suggestions': ['Salmon with Roasted Vegetables', 'Mixed Berry Smoothie Bowl', 'Turkey & Hummus Wrap'],
      'reasoning': ['Omega-3 fatty acids in salmon and tryptophan in turkey sustain serotonin, helping you stay in a positive mood longer.'],
    },
    'Tired': {
      'suggestions': ['Lentil & Spinach Soup', 'Whole Grain Toast with Eggs', 'Apple with Almond Butter'],
      'reasoning': ['Iron-rich lentils combat fatigue while complex carbohydrates provide steady glucose for sustained brain energy without a crash.'],
    },
    'Sad': {
      'suggestions': ['Warm Oatmeal with Honey & Banana', 'Dark Chocolate with Strawberries', 'Salmon & Sweet Potato Bowl'],
      'reasoning': ['Foods rich in tryptophan and omega-3s boost serotonin and endorphins, providing genuine neurochemical mood uplift.'],
    },
    'Focused': {
      'suggestions': ['Blueberry & Walnut Oatmeal', 'Green Tea with Boiled Eggs & Avocado', 'Whole Grain Toast with Smoked Salmon'],
      'reasoning': ['Blueberries improve blood flow to the brain. Choline in eggs supports acetylcholine production for sharp, sustained focus.'],
    },
    'Romantic': {
      'suggestions': ['Dark Chocolate Covered Strawberries', 'Salmon with Lemon Butter Sauce', 'Cheese & Fruit Platter with Sparkling Water'],
      'reasoning': ['Phenylethylamine in dark chocolate mimics the chemistry of attraction. Zinc supports mood-enhancing hormone balance.'],
    },
    'Adventurous': {
      'suggestions': ['Thai Green Curry with Jasmine Rice', 'Mediterranean Mezze Platter', 'Spicy Korean Bibimbap Bowl'],
      'reasoning': ['Exploring global cuisines stimulates novelty-seeking dopamine pathways and exposes you to a wider range of beneficial nutrients.'],
    },
    'Anxious': {
      'suggestions': ['Greek Yogurt with Honey & Walnuts', 'Warm Chamomile Oatmeal', 'Banana & Almond Butter Smoothie'],
      'reasoning': ['Probiotics in yogurt support the gut-brain axis. Magnesium in bananas and almonds activates GABA receptors, calming the nervous system.'],
    },
    'Chill': {
      'suggestions': ['Warm Tomato Basil Soup', 'Herbal Tea with Whole Grain Crackers & Cheese', 'Avocado & Cucumber Rice Bowl'],
      'reasoning': ['Light, easy-to-digest foods maintain relaxed energy. L-theanine in herbal teas promotes calm alertness without drowsiness.'],
    },
  };
}