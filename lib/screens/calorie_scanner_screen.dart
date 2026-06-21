import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/ai_service.dart';
import '../services/tflite_service.dart';
import '../services/storage_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/error_card.dart';

class CalorieScannerScreen extends StatefulWidget {
  final UserProfile profile;
  const CalorieScannerScreen({super.key, required this.profile});

  @override
  State<CalorieScannerScreen> createState() => _CalorieScannerScreenState();
}

class _CalorieScannerScreenState extends State<CalorieScannerScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  ScanResult? _result;
  File? _pickedImage;
  bool _scanning = false;
  bool _logged = false;
  String? _error;
  String _selectedMealType = 'lunch';
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    // Pre-load TFLite model in background
    TFLiteService.init().catchError((_) {});
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  // ── Pick image from camera or gallery ────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 640,
      );
      if (picked == null) return;

      setState(() {
        _pickedImage = File(picked.path);
        _result = null;
        _logged = false;
        _error = null;
        _textCtrl.clear();
      });

      await _scanImage(_pickedImage!);
    } catch (e) {
      setState(() => _error = 'Could not open camera/gallery: $e');
    }
  }

  // ── Scan image via TFLite → enrich with AI ───────────────────
  Future<void> _scanImage(File imageFile) async {
    setState(() {
      _scanning = true;
      _error = null;
      _result = null;
      _logged = false;
    });

    try {
      // Step 1: TFLite classifies the food label
      final tfliteResult = await TFLiteService.classifyFood(imageFile);
      final foodName = tfliteResult['food'] as String;
      final calsPer100g = (tfliteResult['calories_per_100g'] as num).toDouble();
      final confidence = (tfliteResult['confidence'] as num).toDouble();

      // Step 2: Try to get richer data from AI, fall back to local table
      ScanResult result;
      try {
        result = await AIService.analyzeFoodText(foodName);
      } catch (_) {
        // Offline fallback — build ScanResult from TFLite + local tables
        final macros = TFLiteService.estimateMacros(foodName, calsPer100g);
        final scoreInt = TFLiteService.estimateHealthScore(foodName);
        final scoreStr = scoreInt >= 80 ? 'A' : scoreInt >= 65 ? 'B' : scoreInt >= 45 ? 'C' : 'D';
        result = ScanResult(
          foodName: _capitalize(foodName),
          calories: calsPer100g.round(),
          protein: macros['protein'] ?? 0,
          carbs: macros['carbs'] ?? 0,
          fat: macros['fat'] ?? 0,
          fiber: macros['fiber'] ?? 0,
          portionSize: '~100g serving',
          healthScore: scoreStr,
          tags: TFLiteService.getFoodTags(foodName),
          aiAnalysis:
          'Identified as $foodName with ${(confidence * 100).toStringAsFixed(0)}% '
              'confidence. Estimated ~${calsPer100g.round()} kcal per 100g.',
        );
      }

      setState(() {
        _result = result;
        _scanning = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Image scan failed: $e';
        _scanning = false;
      });
    }
  }

  // ── Scan from text input ──────────────────────────────────────
  Future<void> _scanText() async {
    if (_textCtrl.text.trim().isEmpty) return;
    setState(() {
      _scanning = true;
      _result = null;
      _pickedImage = null;
      _logged = false;
      _error = null;
    });
    try {
      final result = await AIService.analyzeFoodText(_textCtrl.text.trim());
      setState(() {
        _result = result;
        _scanning = false;
      });
    } on AIServiceException catch (e) {
      setState(() {
        _error = e.message;
        _scanning = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _scanning = false;
      });
    }
  }

  Future<void> _logMeal() async {
    if (_result == null) return;
    final meal = Meal(
      id: const Uuid().v4(),
      name: _result!.foodName,
      calories: _result!.calories,
      protein: _result!.protein,
      carbs: _result!.carbs,
      fat: _result!.fat,
      fiber: _result!.fiber,
      mealType: _selectedMealType,
      dateTime: DateTime.now(),
      aiNote: _result!.aiAnalysis,
    );
    await StorageService.saveMeal(meal);
    setState(() => _logged = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Text('✅  '),
            Text('${_result!.foodName} logged!'),
          ]),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // ── BUILD ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.background,
            title: const Text('Calorie Scanner'),
            centerTitle: false,
            floating: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 10),
                _buildScanInput(),
                const SizedBox(height: 20),
                if (_scanning) _buildScanning(),
                if (_error != null && !_scanning) ErrorCard(message: _error!),
                if (_result != null && !_scanning) _buildResult(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanInput() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.pinkGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.document_scanner_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Food Analyzer',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  Text('Describe or photograph your meal',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Camera / Gallery buttons ────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ImageSourceButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  gradient: AppTheme.primaryGradient,
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ImageSourceButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  gradient: AppTheme.pinkGradient,
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),

          // ── Preview of picked image ────────────────────────────
          if (_pickedImage != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                _pickedImage!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],

          const SizedBox(height: 16),
          Row(children: const [
            Expanded(child: Divider(color: Color(0xFF2A3A55))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('OR TYPE',
                  style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      letterSpacing: 1.5)),
            ),
            Expanded(child: Divider(color: Color(0xFF2A3A55))),
          ]),
          const SizedBox(height: 16),

          // ── Text input ─────────────────────────────────────────
          TextField(
            controller: _textCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
              'e.g. "2 eggs, toast with butter and a glass of OJ"',
              hintStyle:
              const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              filled: true,
              fillColor: AppTheme.cardLight,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                  const BorderSide(color: AppTheme.primary, width: 1.5)),
            ),
          ),
          const SizedBox(height: 16),

          // ── Quick picks ────────────────────────────────────────
          const Text('QUICK PICKS',
              style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.5)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              '🍕 Pizza slice',
              '🥗 Caesar salad',
              '🍌 Banana',
              '☕ Latte',
              '🍗 Grilled chicken',
              '🥤 Protein shake',
            ]
                .map((item) => GestureDetector(
              onTap: () {
                _textCtrl.text = item.substring(3);
                setState(() => _pickedImage = null);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.cardLight,
                  borderRadius: BorderRadius.circular(99),
                  border:
                  Border.all(color: const Color(0xFF2A3A55)),
                ),
                child: Text(item,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12)),
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 20),

          // ── Analyze button ─────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _scanning ? null : _scanText,
              icon: const Icon(Icons.auto_fix_high_rounded),
              label: const Text('Analyze with AI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanning() {
    return GlassCard(
      child: Column(
        children: [
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnim.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.psychology_alt_rounded,
                    color: Colors.white, size: 36),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('AI Analyzing...',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Calculating macros & nutrition score',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final r = _result!;
    return Column(
      children: [
        GlassCard(
          borderColor: AppTheme.primary.withOpacity(0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ANALYZED FOOD',
                            style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                                letterSpacing: 1.5)),
                        const SizedBox(height: 6),
                        Text(r.foodName,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(r.portionSize,
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                  HealthScoreBadge(score: r.healthScore, size: 56),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Text('${r.calories} Calories',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _MacroChip(
                      label: 'Protein',
                      value: r.protein,
                      color: AppTheme.accentBlue),
                  const SizedBox(width: 10),
                  _MacroChip(
                      label: 'Carbs',
                      value: r.carbs,
                      color: AppTheme.accentYellow),
                  const SizedBox(width: 10),
                  _MacroChip(
                      label: 'Fat', value: r.fat, color: AppTheme.accent),
                  const SizedBox(width: 10),
                  _MacroChip(
                      label: 'Fiber',
                      value: r.fiber,
                      color: AppTheme.success),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: r.tags
                    .map((tag) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.accentBlue.withOpacity(0.3)),
                  ),
                  child: Text(tag,
                      style: const TextStyle(
                          color: AppTheme.accentBlue, fontSize: 11)),
                ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🤖', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(r.aiAnalysis,
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              height: 1.6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('LOG THIS MEAL',
                  style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['breakfast', 'lunch', 'dinner', 'snack']
                      .map((type) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: MealTypeChip(
                      type: type,
                      selected: _selectedMealType == type,
                      onTap: () =>
                          setState(() => _selectedMealType = type),
                    ),
                  ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logged ? null : _logMeal,
                  icon: Icon(_logged
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded),
                  label: Text(_logged ? 'Logged!' : 'Add to Food Log'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    _logged ? AppTheme.success : AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Camera / Gallery source button ───────────────────────────────
class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ── Macro chip ────────────────────────────────────────────────────
class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MacroChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text('${value.toStringAsFixed(1)}g',
                style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}