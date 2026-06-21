import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends StatefulWidget {
  final UserProfile profile;
  const HomeScreen({super.key, required this.profile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Meal> _todayMeals = [];
  Map<String, int> _weeklyData = {};
  String _aiInsight = '';
  bool _loadingInsight = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final meals = await StorageService.getMealsForDate(DateTime.now());
    final weekly = await StorageService.getWeeklyCalories();
    setState(() {
      _todayMeals = meals;
      _weeklyData = weekly;
      _loading = false;
    });
    _fetchInsight();
  }

  Future<void> _fetchInsight() async {
    setState(() => _loadingInsight = true);
    final total = _todayMeals.fold(0, (s, m) => s + m.calories);
    final protein = _todayMeals.fold(0.0, (s, m) => s + m.protein);
    final insight = await AIService.getDailyInsight(
      caloriesConsumed: total,
      caloriesGoal: widget.profile.dailyCalorieGoal,
      proteinConsumed: protein,
      mealsEaten: _todayMeals.map((m) => m.name).toList(),
    );
    setState(() {
      _aiInsight = insight;
      _loadingInsight = false;
    });
  }

  int get _totalCalories => _todayMeals.fold(0, (s, m) => s + m.calories);
  double get _totalProtein => _todayMeals.fold(0.0, (s, m) => s + m.protein);
  double get _totalCarbs => _todayMeals.fold(0.0, (s, m) => s + m.carbs);
  double get _totalFat => _todayMeals.fold(0.0, (s, m) => s + m.fat);

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: AppTheme.card,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(greeting),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 24),
                  _buildCalorieCard(),
                  const SizedBox(height: 20),
                  _buildMacrosCard(),
                  const SizedBox(height: 20),
                  _buildAIInsightCard(),
                  const SizedBox(height: 20),
                  _buildWeeklyChart(),
                  const SizedBox(height: 20),
                  _buildTodayMeals(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(String greeting) {
    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: AppTheme.background,
      floating: true,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GradientText(
                        widget.profile.name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.person_rounded, color: AppTheme.background, size: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalorieCard() {
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CalorieRing(
            consumed: _totalCalories,
            goal: widget.profile.dailyCalorieGoal,
            size: 126,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TODAY\'S CALORIES',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _StatRow(
                  label: 'Goal',
                  value: '${widget.profile.dailyCalorieGoal}',
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 4),
                _StatRow(
                  label: 'Consumed',
                  value: '$_totalCalories',
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 4),
                _StatRow(
                  label: 'Remaining',
                  value: '${(widget.profile.dailyCalorieGoal - _totalCalories).clamp(0, 9999)}',
                  color: AppTheme.accentBlue,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _goalColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _goalColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    _goalLabel,
                    style: TextStyle(
                      color: _goalColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _goalColor {
    final pct = _totalCalories / widget.profile.dailyCalorieGoal;
    if (pct < 0.5) return AppTheme.accentBlue;
    if (pct < 0.9) return AppTheme.success;
    if (pct < 1.1) return AppTheme.warning;
    return AppTheme.error;
  }

  String get _goalLabel {
    final pct = _totalCalories / widget.profile.dailyCalorieGoal;
    if (pct < 0.5) return '⚡ Eat more';
    if (pct < 0.9) return '✅ On track';
    if (pct < 1.1) return '🎯 At goal';
    return '⚠️ Over goal';
  }

  Widget _buildMacrosCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MACRONUTRIENTS',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          MacroBar(
            label: 'Protein',
            value: _totalProtein,
            goal: widget.profile.proteinGoal,
            color: AppTheme.accentBlue,
          ),
          const SizedBox(height: 14),
          MacroBar(
            label: 'Carbs',
            value: _totalCarbs,
            goal: widget.profile.carbsGoal,
            color: AppTheme.accentYellow,
          ),
          const SizedBox(height: 14),
          MacroBar(
            label: 'Fat',
            value: _totalFat,
            goal: widget.profile.fatGoal,
            color: AppTheme.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE8FF), // light lilac background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('✨', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI Daily Insight',
                style: TextStyle(
                  color: Color(0xFF2D1B69), // deep purple, readable on lilac
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loadingInsight)
            Column(
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: double.infinity * 0.7,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ],
            )
          else
            Text(
              _aiInsight.isEmpty
                  ? 'Log your first meal to get personalized AI insights!'
                  : _aiInsight,
              style: const TextStyle(
                color: Color(0xFF3D2785), // dark purple text, very readable on lilac
                fontSize: 13,
                height: 1.7,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final entries = _weeklyData.entries.toList();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '7-DAY OVERVIEW',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: entries.isEmpty
                ? const Center(
              child: Text('No data yet', style: TextStyle(color: AppTheme.textMuted)),
            )
                : BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (widget.profile.dailyCalorieGoal * 1.3).toDouble(),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        if (val.toInt() >= entries.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            entries[val.toInt()].key,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.divider,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: entries.asMap().entries.map((e) {
                  final isToday = e.key == entries.length - 1;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value.toDouble(),
                        gradient: isToday
                            ? AppTheme.primaryGradient
                            : const LinearGradient(
                          colors: [Color(0xFF2A3A55), Color(0xFF1A2235)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        width: 22,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayMeals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "TODAY'S MEALS",
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (_todayMeals.isEmpty)
          GlassCard(
            child: Center(
              child: Column(
                children: [
                  const Text('🍽️', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 12),
                  const Text('No meals logged yet today',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Use the + button to add meals',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
          )
        else
          ..._todayMeals.map((meal) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MealTile(meal: meal, onDelete: () => _deleteMeal(meal.id)),
          )),
      ],
    );
  }

  Future<void> _deleteMeal(String id) async {
    await StorageService.deleteMeal(id);
    _load();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        Text(
          '$value kcal',
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _MealTile extends StatelessWidget {
  final Meal meal;
  final VoidCallback onDelete;

  const _MealTile({required this.meal, required this.onDelete});

  String get _emoji {
    switch (meal.mealType) {
      case 'breakfast': return '🌅';
      case 'lunch': return '☀️';
      case 'dinner': return '🌙';
      case 'snack': return '🍎';
      default: return '🍽️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.cardLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(_emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${meal.mealType} • ${DateFormat('h:mm a').format(meal.dateTime)}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${meal.calories}',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const Text('kcal', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.delete_outline_rounded,
                color: AppTheme.textMuted, size: 18),
          ),
        ],
      ),
    );
  }
}