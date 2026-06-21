import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/ai_service.dart';
import '../widgets/common_widgets.dart';

class MealPlanScreen extends StatefulWidget {
  final UserProfile profile;
  const MealPlanScreen({super.key, required this.profile});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  List<PlannedMeal> _meals = [];
  bool _loading = false;
  bool _generated = false;
  final TextEditingController _prefCtrl = TextEditingController();

  final List<String> _quickPrefs = [
    'No nuts', 'Gluten-free', 'Dairy-free', 'High protein',
    'Low carb', 'No seafood', 'Vegetarian', 'Quick meals',
  ];
  final Set<String> _selectedPrefs = {};

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _meals = [];
    });
    final prefs = [
      ..._selectedPrefs,
      if (_prefCtrl.text.trim().isNotEmpty) _prefCtrl.text.trim(),
    ].join(', ');

    final meals = await AIService.generateDayPlan(
      profile: widget.profile,
      preferences: prefs.isEmpty ? 'none' : prefs,
    );
    setState(() {
      _meals = meals;
      _loading = false;
      _generated = true;
    });
  }

  int get _totalPlannedCalories => _meals.fold(0, (s, m) => s + m.calories);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.background,
            title: const Text('Meal Plan'),
            centerTitle: false,
            floating: true,
            actions: [
              if (_generated)
                TextButton.icon(
                  onPressed: _generate,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Regenerate'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 10),
                _buildGoalBanner(),
                const SizedBox(height: 20),
                _buildPreferences(),
                const SizedBox(height: 20),
                if (_loading) _buildLoading(),
                if (_generated && !_loading) ...[
                  _buildSummaryBar(),
                  const SizedBox(height: 16),
                  ..._meals.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _MealPlanCard(meal: m),
                  )),
                ],
                if (!_loading && !_generated)
                  _buildEmptyState(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalBanner() {
    final goalEmoji = {
      'lose_weight': '⚡', 'gain_muscle': '💪',
      'maintain': '⚖️', 'keto': '🥑', 'vegan': '🌱',
    }[widget.profile.goal] ?? '🎯';

    final goalLabel = {
      'lose_weight': 'Weight Loss', 'gain_muscle': 'Muscle Gain',
      'maintain': 'Maintain Weight', 'keto': 'Keto Diet', 'vegan': 'Vegan',
    }[widget.profile.goal] ?? widget.profile.goal;

    return GlassCard(
      gradient: AppTheme.purpleGradient.scale(0.15),
      borderColor: AppTheme.accentPurple.withOpacity(0.4),
      child: Row(
        children: [
          Text(goalEmoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Current Goal',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              Text(
                goalLabel,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Daily Target',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              Text(
                '${widget.profile.dailyCalorieGoal} kcal',
                style: const TextStyle(
                  color: AppTheme.accentPurple,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferences() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DIETARY PREFERENCES',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickPrefs.map((pref) {
              final selected = _selectedPrefs.contains(pref);
              return GestureDetector(
                onTap: () => setState(() {
                  selected ? _selectedPrefs.remove(pref) : _selectedPrefs.add(pref);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary.withOpacity(0.15)
                        : AppTheme.cardLight,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: selected ? AppTheme.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    pref,
                    style: TextStyle(
                      color: selected ? AppTheme.primary : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _prefCtrl,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Any other requirements (e.g. "I love spicy food")',
              prefixIcon: Icon(Icons.edit_note_rounded, color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _generate,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(_generated ? 'Generate New Plan' : 'Generate AI Meal Plan'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: List.generate(4, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(width: 100, height: 14),
              const SizedBox(height: 12),
              ShimmerBox(width: double.infinity, height: 20),
              const SizedBox(height: 8),
              ShimmerBox(width: 200, height: 14),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildSummaryBar() {
    final pct = (_totalPlannedCalories / widget.profile.dailyCalorieGoal).clamp(0.0, 1.5);
    final diff = _totalPlannedCalories - widget.profile.dailyCalorieGoal;
    return GlassCard(
      borderColor: AppTheme.success.withOpacity(0.4),
      child: Column(
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Plan Summary',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '$_totalPlannedCalories kcal',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: AppTheme.cardLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                diff.abs() < 100 ? AppTheme.success : (diff > 0 ? AppTheme.warning : AppTheme.accentBlue),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            diff.abs() < 50
                ? '✅ Perfect match with your ${widget.profile.dailyCalorieGoal} kcal goal!'
                : diff > 0
                ? '⬆️ ${diff.abs()} kcal over your goal'
                : '⬇️ ${diff.abs()} kcal under your goal',
            style: TextStyle(
              color: diff.abs() < 100 ? AppTheme.success : AppTheme.warning,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return GlassCard(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text('🤖', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'Ready to plan your meals!',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select your preferences and let AI create a personalized meal plan tailored to your goals.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

extension on LinearGradient {
  LinearGradient scale(double opacity) => LinearGradient(
    colors: colors.map((c) => c.withOpacity(opacity)).toList(),
    begin: begin,
    end: end,
  );
}

class _MealPlanCard extends StatelessWidget {
  final PlannedMeal meal;
  const _MealPlanCard({required this.meal});

  String get _emoji {
    switch (meal.mealType) {
      case 'breakfast': return '🌅';
      case 'lunch': return '☀️';
      case 'dinner': return '🌙';
      case 'snack': return '🍎';
      default: return '🍽️';
    }
  }

  Color get _color {
    switch (meal.mealType) {
      case 'breakfast': return AppTheme.accentYellow;
      case 'lunch': return AppTheme.primary;
      case 'dinner': return AppTheme.accentPurple;
      case 'snack': return AppTheme.accent;
      default: return AppTheme.accentBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _color.withOpacity(0.3)),
                ),
                child: Center(child: Text(_emoji, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.mealType.toUpperCase(),
                      style: TextStyle(
                        color: _color,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      meal.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${meal.calories} kcal',
                  style: TextStyle(
                    color: _color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (meal.description != null) ...[
            const SizedBox(height: 12),
            Text(
              meal.description!,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
            ),
          ],
          if (meal.ingredients.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppTheme.divider),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: meal.ingredients.map((ing) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cardLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ing,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}