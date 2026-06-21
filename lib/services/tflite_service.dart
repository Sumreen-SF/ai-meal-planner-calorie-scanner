import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/models.dart';

class TFLiteService {
  static Interpreter? _interpreter;
  static List<String> _labels = [];
  static bool _initialized = false;

  // ── Init (call once at app start) ─────────────────────────────
  static Future<void> init() async {
    if (_initialized) return;
    try {
      _interpreter = await Interpreter.fromAsset('assets/model_unquant.tflite');
      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelData
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      _initialized = true;
    } catch (e) {
      _initialized = false;
      rethrow;
    }
  }

  // ── Image classification via TFLite ───────────────────────────
  static Future<Map<String, dynamic>> classifyFood(File imageFile) async {
    if (!_initialized) await init();
    if (_interpreter == null || _labels.isEmpty) {
      throw Exception('TFLite model not loaded. Check assets/model_unquant.tflite');
    }

    // Decode and resize to 224×224 (standard MobileNet input size)
    final bytes = imageFile.readAsBytesSync();
    final rawImage = img.decodeImage(bytes);
    if (rawImage == null) throw Exception('Could not decode image.');
    final resized = img.copyResize(rawImage, width: 224, height: 224);

    // ── FIX: image 4.x uses pixel.r / pixel.g / pixel.b as num, not int ──
    // Build input tensor [1, 224, 224, 3] normalized to [0.0, 1.0]
    final input = List.generate(
      1,
          (_) => List.generate(
        224,
            (y) => List.generate(
          224,
              (x) {
            final pixel = resized.getPixel(x, y);
            // image 4.x: r/g/b are num (0–255), divide to normalize
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    // Output tensor [1, numLabels]
    final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));
    _interpreter!.run(input, output);

    final scores = output[0];
    int maxIdx = 0;
    double maxScore = scores[0];
    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        maxIdx = i;
      }
    }

    final foodName = _labels[maxIdx].toLowerCase();
    final calories = _localCalorieTable[foodName] ?? 120;

    return {
      'food': foodName,
      'confidence': maxScore,
      'calories_per_100g': calories,
    };
  }

  // ── Text-based lookup (no API, instant, offline) ──────────────
  static ScanResult analyzeFoodText(String input) {
    final lower = input.toLowerCase();

    String matchedKey = '';
    int matchScore = 0;
    for (final key in _nutritionTable.keys) {
      final words = key.split(' ');
      final hits = words.where((w) => lower.contains(w)).length;
      if (hits > matchScore) {
        matchScore = hits;
        matchedKey = key;
      }
    }

    final data = matchScore > 0
        ? _nutritionTable[matchedKey]!
        : _nutritionTable['mixed meal']!;

    final foodName = matchScore > 0
        ? _capitalize(matchedKey)
        : _capitalize(input.split(' ').take(4).join(' '));

    final scoreInt = estimateHealthScore(matchedKey.isNotEmpty ? matchedKey : input);
    // Convert numeric score to letter grade A/B/C/D
    final scoreStr = scoreInt >= 80 ? 'A' : scoreInt >= 65 ? 'B' : scoreInt >= 45 ? 'C' : 'D';

    return ScanResult(
      foodName: foodName,
      calories: data['calories']!.round(),
      protein: data['protein']!,
      carbs: data['carbs']!,
      fat: data['fat']!,
      fiber: data['fiber']!,
      portionSize: data['portion'] != null
          ? '~${data['portion']!.round()}g serving'
          : '1 serving',
      healthScore: scoreStr,
      aiAnalysis: _generateNote(foodName, data),
      tags: getFoodTags(matchedKey.isNotEmpty ? matchedKey : input),
    );
  }

  // ── Macro estimation from calories for TFLite image results ───
  static Map<String, double> estimateMacros(String foodName, double cals) {
    final lower = foodName.toLowerCase();
    if (_containsAny(lower, ['chicken', 'beef', 'fish', 'salmon', 'tuna',
      'egg', 'turkey', 'shrimp', 'pork'])) {
      return {'protein': cals * 0.35 / 4, 'carbs': cals * 0.10 / 4,
        'fat': cals * 0.55 / 9, 'fiber': 0.0};
    }
    if (_containsAny(lower, ['bread', 'rice', 'pasta', 'pizza', 'potato',
      'cereal', 'oat', 'noodle', 'cake', 'cookie', 'donut'])) {
      return {'protein': cals * 0.10 / 4, 'carbs': cals * 0.70 / 4,
        'fat': cals * 0.20 / 9, 'fiber': cals * 0.02 / 2};
    }
    if (_containsAny(lower, ['apple', 'banana', 'orange', 'grape', 'mango',
      'salad', 'broccoli', 'carrot', 'spinach', 'tomato', 'cucumber'])) {
      return {'protein': cals * 0.08 / 4, 'carbs': cals * 0.80 / 4,
        'fat': cals * 0.05 / 9, 'fiber': cals * 0.07 / 2};
    }
    if (_containsAny(lower, ['cheese', 'milk', 'yogurt', 'butter', 'cream'])) {
      return {'protein': cals * 0.25 / 4, 'carbs': cals * 0.10 / 4,
        'fat': cals * 0.65 / 9, 'fiber': 0.0};
    }
    return {'protein': cals * 0.20 / 4, 'carbs': cals * 0.50 / 4,
      'fat': cals * 0.30 / 9, 'fiber': 1.5};
  }

  // ── Health score (returns int 0–100) ──────────────────────────
  static int estimateHealthScore(String foodName) {
    final lower = foodName.toLowerCase();
    if (_containsAny(lower, ['salad', 'broccoli', 'spinach', 'kale',
      'cucumber', 'tomato', 'carrot', 'apple', 'berry', 'fruit'])) return 90;
    if (_containsAny(lower, ['chicken breast', 'salmon', 'tuna', 'egg',
      'oat', 'quinoa', 'lentil', 'bean'])) return 80;
    if (_containsAny(lower, ['rice', 'pasta', 'bread', 'potato',
      'banana', 'milk', 'yogurt'])) return 65;
    if (_containsAny(lower, ['pizza', 'burger', 'sandwich', 'wrap',
      'stir fry', 'soup'])) return 52;
    if (_containsAny(lower, ['fries', 'fried', 'chips', 'donut',
      'cake', 'cookie', 'chocolate', 'candy', 'soda', 'juice'])) return 30;
    return 55;
  }

  // ── Food tags ─────────────────────────────────────────────────
  static List<String> getFoodTags(String foodName) {
    final lower = foodName.toLowerCase();
    final tags = <String>[];
    if (_containsAny(lower, ['chicken', 'beef', 'fish', 'salmon', 'tuna',
      'egg', 'turkey', 'shrimp'])) tags.add('High Protein');
    if (_containsAny(lower, ['salad', 'broccoli', 'spinach', 'apple',
      'banana', 'carrot', 'fruit', 'vegetable'])) tags.add('Whole Food');
    if (_containsAny(lower, ['pizza', 'burger', 'fries', 'chips',
      'donut', 'cake', 'candy'])) tags.add('Treat');
    if (_containsAny(lower, ['oat', 'quinoa', 'rice', 'bread',
      'pasta', 'potato', 'cereal'])) tags.add('Carb-Rich');
    if (_containsAny(lower, ['butter', 'cheese', 'fried', 'oil',
      'cream', 'mayo'])) tags.add('High Fat');
    if (_containsAny(lower, ['salad', 'vegetable', 'broccoli', 'spinach',
      'kale', 'lentil', 'bean', 'oat'])) tags.add('High Fiber');
    if (_containsAny(lower, ['vegan', 'plant', 'tofu', 'tempeh',
      'lentil', 'bean', 'fruit', 'vegetable', 'nut', 'seed',
      'oat', 'quinoa', 'rice', 'pasta'])) tags.add('Vegan-Friendly');
    if (tags.isEmpty) tags.add('Mixed Meal');
    return tags;
  }

  static bool _containsAny(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String _generateNote(String food, Map<String, double> data) {
    final cals = data['calories']!.round();
    final protein = data['protein']!.toStringAsFixed(0);
    final fiber = data['fiber']!;
    if (cals < 200) {
      return '$food is a light option at $cals kcal with ${protein}g protein. '
          'Great for snacking without breaking your calorie budget.';
    } else if (data['protein']! > 25) {
      return 'Good protein source! $food provides ${protein}g protein '
          'and $cals kcal. Ideal for muscle recovery and satiety.';
    } else if (fiber > 4) {
      return '$food is fiber-rich which supports digestion and keeps '
          'you fuller longer. Contains $cals kcal per serving.';
    } else {
      return '$food provides $cals kcal per serving with ${protein}g protein. '
          'Adjust your portion based on your daily targets.';
    }
  }

  // ── Local nutrition table ─────────────────────────────────────
  static const Map<String, Map<String, double>> _nutritionTable = {
    'grilled chicken':  {'calories': 165, 'protein': 31,  'carbs': 0,    'fat': 3.6,  'fiber': 0,   'portion': 100},
    'chicken breast':   {'calories': 165, 'protein': 31,  'carbs': 0,    'fat': 3.6,  'fiber': 0,   'portion': 100},
    'fried chicken':    {'calories': 320, 'protein': 24,  'carbs': 14,   'fat': 19,   'fiber': 0.5, 'portion': 130},
    'salmon':           {'calories': 208, 'protein': 20,  'carbs': 0,    'fat': 13,   'fiber': 0,   'portion': 100},
    'tuna':             {'calories': 132, 'protein': 28,  'carbs': 0,    'fat': 1.4,  'fiber': 0,   'portion': 100},
    'egg':              {'calories': 155, 'protein': 13,  'carbs': 1.1,  'fat': 11,   'fiber': 0,   'portion': 100},
    'boiled egg':       {'calories': 155, 'protein': 13,  'carbs': 1.1,  'fat': 11,   'fiber': 0,   'portion': 100},
    'scrambled eggs':   {'calories': 200, 'protein': 14,  'carbs': 2,    'fat': 15,   'fiber': 0,   'portion': 120},
    'beef':             {'calories': 250, 'protein': 26,  'carbs': 0,    'fat': 15,   'fiber': 0,   'portion': 100},
    'steak':            {'calories': 271, 'protein': 26,  'carbs': 0,    'fat': 18,   'fiber': 0,   'portion': 100},
    'shrimp':           {'calories': 99,  'protein': 24,  'carbs': 0,    'fat': 0.3,  'fiber': 0,   'portion': 100},
    'protein shake':    {'calories': 160, 'protein': 30,  'carbs': 8,    'fat': 3,    'fiber': 1,   'portion': 300},
    'white rice':       {'calories': 130, 'protein': 2.7, 'carbs': 28,   'fat': 0.3,  'fiber': 0.4, 'portion': 100},
    'brown rice':       {'calories': 216, 'protein': 5,   'carbs': 45,   'fat': 1.8,  'fiber': 3.5, 'portion': 202},
    'pasta':            {'calories': 131, 'protein': 5,   'carbs': 25,   'fat': 1.1,  'fiber': 1.8, 'portion': 100},
    'bread':            {'calories': 265, 'protein': 9,   'carbs': 49,   'fat': 3.2,  'fiber': 2.7, 'portion': 100},
    'toast':            {'calories': 313, 'protein': 10,  'carbs': 57,   'fat': 4,    'fiber': 3,   'portion': 100},
    'oatmeal':          {'calories': 307, 'protein': 11,  'carbs': 55,   'fat': 5.4,  'fiber': 8,   'portion': 234},
    'oats':             {'calories': 307, 'protein': 11,  'carbs': 55,   'fat': 5.4,  'fiber': 8,   'portion': 234},
    'potato':           {'calories': 161, 'protein': 4.3, 'carbs': 37,   'fat': 0.2,  'fiber': 3.8, 'portion': 173},
    'sweet potato':     {'calories': 103, 'protein': 2.3, 'carbs': 24,   'fat': 0.1,  'fiber': 3.8, 'portion': 130},
    'quinoa':           {'calories': 222, 'protein': 8,   'carbs': 39,   'fat': 3.6,  'fiber': 5,   'portion': 185},
    'wrap':             {'calories': 300, 'protein': 12,  'carbs': 38,   'fat': 12,   'fiber': 3,   'portion': 150},
    'pizza slice':      {'calories': 285, 'protein': 12,  'carbs': 36,   'fat': 10,   'fiber': 2.5, 'portion': 107},
    'pepperoni pizza':  {'calories': 298, 'protein': 12,  'carbs': 34,   'fat': 13,   'fiber': 2,   'portion': 107},
    'burger':           {'calories': 354, 'protein': 20,  'carbs': 29,   'fat': 17,   'fiber': 1.5, 'portion': 150},
    'cheeseburger':     {'calories': 390, 'protein': 22,  'carbs': 30,   'fat': 20,   'fiber': 1.5, 'portion': 160},
    'french fries':     {'calories': 365, 'protein': 3.4, 'carbs': 48,   'fat': 17,   'fiber': 3.8, 'portion': 154},
    'fries':            {'calories': 365, 'protein': 3.4, 'carbs': 48,   'fat': 17,   'fiber': 3.8, 'portion': 154},
    'hot dog':          {'calories': 290, 'protein': 11,  'carbs': 24,   'fat': 17,   'fiber': 1,   'portion': 120},
    'sandwich':         {'calories': 330, 'protein': 18,  'carbs': 35,   'fat': 13,   'fiber': 2.5, 'portion': 200},
    'apple':            {'calories': 95,  'protein': 0.5, 'carbs': 25,   'fat': 0.3,  'fiber': 4.4, 'portion': 182},
    'banana':           {'calories': 105, 'protein': 1.3, 'carbs': 27,   'fat': 0.4,  'fiber': 3.1, 'portion': 118},
    'orange':           {'calories': 62,  'protein': 1.2, 'carbs': 15,   'fat': 0.2,  'fiber': 3.1, 'portion': 131},
    'mango':            {'calories': 201, 'protein': 2.8, 'carbs': 50,   'fat': 1.3,  'fiber': 5.4, 'portion': 336},
    'grapes':           {'calories': 104, 'protein': 1.1, 'carbs': 27,   'fat': 0.2,  'fiber': 1.4, 'portion': 151},
    'strawberry':       {'calories': 49,  'protein': 1,   'carbs': 12,   'fat': 0.5,  'fiber': 3,   'portion': 152},
    'caesar salad':     {'calories': 470, 'protein': 12,  'carbs': 22,   'fat': 38,   'fiber': 3,   'portion': 300},
    'garden salad':     {'calories': 100, 'protein': 3,   'carbs': 12,   'fat': 5,    'fiber': 3.5, 'portion': 200},
    'salad':            {'calories': 150, 'protein': 4,   'carbs': 14,   'fat': 8,    'fiber': 3,   'portion': 200},
    'broccoli':         {'calories': 31,  'protein': 2.6, 'carbs': 6,    'fat': 0.3,  'fiber': 2.4, 'portion': 91},
    'spinach':          {'calories': 7,   'protein': 0.9, 'carbs': 1.1,  'fat': 0.1,  'fiber': 0.7, 'portion': 30},
    'carrot':           {'calories': 52,  'protein': 1.2, 'carbs': 12,   'fat': 0.3,  'fiber': 3.6, 'portion': 100},
    'milk':             {'calories': 149, 'protein': 8,   'carbs': 12,   'fat': 8,    'fiber': 0,   'portion': 244},
    'cheese':           {'calories': 113, 'protein': 7,   'carbs': 0.4,  'fat': 9,    'fiber': 0,   'portion': 28},
    'yogurt':           {'calories': 150, 'protein': 8.5, 'carbs': 17,   'fat': 3.5,  'fiber': 0,   'portion': 200},
    'greek yogurt':     {'calories': 130, 'protein': 17,  'carbs': 9,    'fat': 0.7,  'fiber': 0,   'portion': 200},
    'butter':           {'calories': 102, 'protein': 0.1, 'carbs': 0,    'fat': 11.5, 'fiber': 0,   'portion': 14},
    'latte':            {'calories': 190, 'protein': 10,  'carbs': 19,   'fat': 7,    'fiber': 0,   'portion': 360},
    'coffee':           {'calories': 5,   'protein': 0.3, 'carbs': 0,    'fat': 0,    'fiber': 0,   'portion': 240},
    'orange juice':     {'calories': 112, 'protein': 1.7, 'carbs': 26,   'fat': 0.5,  'fiber': 0.5, 'portion': 240},
    'soda':             {'calories': 140, 'protein': 0,   'carbs': 39,   'fat': 0,    'fiber': 0,   'portion': 355},
    'chocolate':        {'calories': 546, 'protein': 5,   'carbs': 60,   'fat': 31,   'fiber': 7,   'portion': 100},
    'chips':            {'calories': 536, 'protein': 7,   'carbs': 53,   'fat': 35,   'fiber': 4.8, 'portion': 100},
    'donut':            {'calories': 452, 'protein': 5,   'carbs': 51,   'fat': 25,   'fiber': 1.5, 'portion': 100},
    'cake':             {'calories': 371, 'protein': 5,   'carbs': 57,   'fat': 14,   'fiber': 1,   'portion': 100},
    'cookie':           {'calories': 481, 'protein': 6,   'carbs': 64,   'fat': 22,   'fiber': 2.3, 'portion': 100},
    'granola bar':      {'calories': 193, 'protein': 4,   'carbs': 29,   'fat': 7.6,  'fiber': 2,   'portion': 47},
    'mixed meal':       {'calories': 450, 'protein': 22,  'carbs': 50,   'fat': 16,   'fiber': 4,   'portion': 300},
  };

  static const Map<String, int> _localCalorieTable = {
    'apple': 52,        'banana': 89,       'orange': 47,
    'mango': 60,        'grape': 69,        'strawberry': 32,
    'pineapple': 50,    'watermelon': 30,   'blueberry': 57,
    'peach': 39,        'pear': 57,         'cherry': 63,
    'broccoli': 34,     'carrot': 41,       'spinach': 23,
    'tomato': 18,       'cucumber': 16,     'potato': 77,
    'sweet potato': 86, 'corn': 86,         'peas': 81,
    'onion': 40,        'garlic': 149,      'pepper': 20,
    'rice': 130,        'pasta': 131,       'bread': 265,
    'pizza': 266,       'burger': 295,      'hot dog': 242,
    'french fries': 312,'sandwich': 250,    'sushi': 143,
    'chicken': 165,     'beef': 250,        'pork': 242,
    'salmon': 208,      'tuna': 132,        'shrimp': 99,
    'egg': 155,         'bacon': 541,       'ham': 145,
    'milk': 61,         'cheese': 402,      'yogurt': 59,
    'butter': 717,      'ice cream': 207,
    'chocolate': 546,   'cake': 371,        'cookie': 481,
    'donut': 452,       'chips': 536,       'candy': 380,
    'coffee': 2,        'juice': 45,        'soda': 41,
    'beer': 43,         'wine': 85,
    'salad': 15,        'soup': 45,         'stew': 120,
    'oatmeal': 68,      'cereal': 379,      'granola': 471,
    'tofu': 76,         'tempeh': 193,      'lentils': 116,
    'beans': 127,       'nuts': 607,        'peanut butter': 588,
  };
}