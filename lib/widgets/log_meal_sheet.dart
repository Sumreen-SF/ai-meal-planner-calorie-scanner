import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../widgets/common_widgets.dart';

class LogMealSheet extends StatefulWidget {
  final VoidCallback onLogged;
  const LogMealSheet({super.key, required this.onLogged});

  @override
  State<LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends State<LogMealSheet> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _calCtrl = TextEditingController();
  final TextEditingController _protCtrl = TextEditingController();
  final TextEditingController _carbCtrl = TextEditingController();
  final TextEditingController _fatCtrl = TextEditingController();

  String _mealType = 'lunch';
  bool _aiMode = true;
  bool _analyzing = false;
  String? _aiInsight;

  @override
  void dispose() {
    _nameCtrl.dispose(); _calCtrl.dispose();
    _protCtrl.dispose(); _carbCtrl.dispose(); _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _analyzeWithAI() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _analyzing = true);

    final result = await AIService.analyzeFoodText(_nameCtrl.text.trim());

    setState(() {
      _calCtrl.text = result.calories.toString();
      _protCtrl.text = result.protein.toStringAsFixed(1);
      _carbCtrl.text = result.carbs.toStringAsFixed(1);
      _fatCtrl.text = result.fat.toStringAsFixed(1);
      _aiInsight = result.aiAnalysis;
      _analyzing = false;
    });
  }

  Future<void> _log() async {
    if (_nameCtrl.text.isEmpty || _calCtrl.text.isEmpty) return;

    final meal = Meal(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      calories: int.tryParse(_calCtrl.text) ?? 0,
      protein: double.tryParse(_protCtrl.text) ?? 0,
      carbs: double.tryParse(_carbCtrl.text) ?? 0,
      fat: double.tryParse(_fatCtrl.text) ?? 0,
      fiber: 0,
      mealType: _mealType,
      dateTime: DateTime.now(),
      aiNote: _aiInsight,
    );

    await StorageService.saveMeal(meal);
    if (mounted) Navigator.pop(context);
    widget.onLogged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_circle_outline_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Log a Meal',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18, fontWeight: FontWeight.w800,
                        )),
                    Text('AI auto-fills nutrition info',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                // AI toggle
                GestureDetector(
                  onTap: () => setState(() => _aiMode = !_aiMode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _aiMode
                          ? AppTheme.primary.withOpacity(0.15)
                          : AppTheme.cardLight,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: _aiMode ? AppTheme.primary : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          'AI',
                          style: TextStyle(
                            color: _aiMode ? AppTheme.primary : AppTheme.textMuted,
                            fontSize: 12, fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Meal type selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['breakfast', 'lunch', 'dinner', 'snack'].map((type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: MealTypeChip(
                    type: type,
                    selected: _mealType == type,
                    onTap: () => setState(() => _mealType = type),
                  ),
                )).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Food name + AI button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Food name or description…',
                      prefixIcon: Icon(Icons.restaurant_rounded, color: AppTheme.textMuted),
                    ),
                  ),
                ),
                if (_aiMode) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _analyzing ? null : _analyzeWithAI,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        gradient: _analyzing
                            ? const LinearGradient(colors: [AppTheme.cardLight, AppTheme.cardLight])
                            : AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: _analyzing
                            ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                          ),
                        )
                            : const Text('✨', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // AI insight box
            if (_aiInsight != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🤖', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _aiInsight!,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12, height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Nutrition fields
            Row(
              children: [
                Expanded(
                  child: _NutritionField(
                    ctrl: _calCtrl, label: 'Calories', unit: 'kcal',
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NutritionField(
                    ctrl: _protCtrl, label: 'Protein', unit: 'g',
                    color: AppTheme.accentBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _NutritionField(
                    ctrl: _carbCtrl, label: 'Carbs', unit: 'g',
                    color: AppTheme.accentYellow,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NutritionField(
                    ctrl: _fatCtrl, label: 'Fat', unit: 'g',
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _log,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Log Meal'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String unit;
  final Color color;

  const _NutritionField({
    required this.ctrl,
    required this.label,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(color: color, fontSize: 11,
                    fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            suffixText: unit,
            suffixStyle: TextStyle(color: color.withOpacity(0.7), fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}