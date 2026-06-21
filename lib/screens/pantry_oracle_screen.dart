import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/ai_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/error_card.dart';

class PantryOracleScreen extends StatefulWidget {
  final UserProfile profile;
  const PantryOracleScreen({super.key, required this.profile});

  @override
  State<PantryOracleScreen> createState() => _PantryOracleScreenState();
}

class _PantryOracleScreenState extends State<PantryOracleScreen> {
  final TextEditingController _ingredientCtrl = TextEditingController();
  final List<String> _ingredients = [];
  List<Map<String, dynamic>> _recipes = [];
  bool _loading = false;
  String? _error;
  int _maxCalories = 500;

  final List<String> _commonIngredients = [
    '🥚 Eggs', '🥛 Milk', '🧀 Cheese', '🍗 Chicken', '🥩 Beef',
    '🍚 Rice', '🍝 Pasta', '🥔 Potato', '🧅 Onion', '🧄 Garlic',
    '🍅 Tomato', '🥦 Broccoli', '🫑 Bell pepper', '🥕 Carrot',
    '🫘 Beans', '🥫 Canned tuna', '🫒 Olive oil', '🧈 Butter',
    '🍋 Lemon', '🌿 Herbs',
  ];

  void _addIngredient(String ing) {
    final clean = ing.replaceAll(RegExp(r'^[^\w]+'), '').trim();
    if (clean.isNotEmpty && !_ingredients.contains(clean)) {
      setState(() => _ingredients.add(clean));
    }
  }

  void _removeIngredient(String ing) {
    setState(() => _ingredients.remove(ing));
  }

  Future<void> _findRecipes() async {
    if (_ingredients.isEmpty) return;
    setState(() {
      _loading = true;
      _recipes = [];
      _error = null;
    });

    try {
      final recipes = await AIService.getPantryMealIdeas(
        ingredients: _ingredients,
        profile: widget.profile,
        maxCalories: _maxCalories,
      );
      setState(() {
        _recipes = recipes;
        _loading = false;
      });
    } on AIServiceException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.background,
            floating: true,
            expandedHeight: 130,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GradientText(
                      'Pantry Oracle',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                      gradient: AppTheme.purpleGradient,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tell me what you have → get meal ideas instantly',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 10),
                _buildIngredientInput(),
                const SizedBox(height: 16),
                _buildQuickAdd(),
                if (_ingredients.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildIngredientChips(),
                  const SizedBox(height: 16),
                  _buildCalorieSlider(),
                  const SizedBox(height: 16),
                  _buildFindButton(),
                ],
                const SizedBox(height: 20),
                if (_loading) _buildLoadingState(),
                if (_error != null && !_loading) ErrorCard(message: _error!),
                if (_recipes.isNotEmpty && !_loading) ..._buildRecipeCards(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientInput() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.purpleGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🔮', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What\'s in your fridge?',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Add available ingredients',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ingredientCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Type ingredient...',
                    prefixIcon: Icon(Icons.kitchen_rounded, color: AppTheme.textMuted),
                  ),
                  onSubmitted: (val) {
                    _addIngredient(val);
                    _ingredientCtrl.clear();
                  },
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  _addIngredient(_ingredientCtrl.text);
                  _ingredientCtrl.clear();
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppTheme.purpleGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAdd() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'COMMON INGREDIENTS',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _commonIngredients.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final ing = _commonIngredients[i];
              final clean = ing.substring(3);
              final added = _ingredients.contains(clean);
              return GestureDetector(
                onTap: () => added ? _removeIngredient(clean) : _addIngredient(ing),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: added
                        ? AppTheme.accentPurple.withOpacity(0.2)
                        : AppTheme.card,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: added ? AppTheme.accentPurple : const Color(0xFFE0D6FF),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      ing,
                      style: TextStyle(
                        color: added ? AppTheme.accentPurple : AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: added ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientChips() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'MY INGREDIENTS (${_ingredients.length})',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _ingredients.clear()),
                child: const Text(
                  'Clear all',
                  style: TextStyle(color: AppTheme.accent, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ingredients.map((ing) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppTheme.accentPurple.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ing,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _removeIngredient(ing),
                    child: const Icon(Icons.close_rounded,
                        color: AppTheme.textMuted, size: 14),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieSlider() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'MAX CALORIES PER MEAL',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '$_maxCalories kcal',
                style: const TextStyle(
                  color: AppTheme.accentPurple,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          Slider(
            value: _maxCalories.toDouble(),
            min: 200,
            max: 1000,
            divisions: 16,
            activeColor: AppTheme.accentPurple,
            inactiveColor: AppTheme.cardLight,
            onChanged: (v) => setState(() => _maxCalories = v.toInt()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('200', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              Text('1000', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFindButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _findRecipes,
        icon: const Text('🔮', style: TextStyle(fontSize: 16)),
        label: const Text('Find Recipes with My Ingredients'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return GlassCard(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text('🔮', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'Consulting the Pantry Oracle...',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Finding creative recipes with ${_ingredients.length} ingredients',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPurple),
            strokeWidth: 2,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> _buildRecipeCards() {
    return [
      const Text(
        'RECIPE IDEAS FOR YOU',
        style: TextStyle(
          color: AppTheme.textMuted,
          fontSize: 10,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 12),
      ..._recipes.asMap().entries.map((e) {
        final r = e.value;
        final colors = [AppTheme.primary, AppTheme.accentPurple, AppTheme.accent];
        final color = colors[e.key % colors.length];
        final difficulty = r['difficulty'] as String? ?? 'Easy';
        final diffColor = difficulty == 'Easy'
            ? AppTheme.success
            : difficulty == 'Medium'
            ? AppTheme.warning
            : AppTheme.error;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text('${e.key + 1}', style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      )),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r['name'] as String? ?? '',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.timer_outlined, color: AppTheme.textMuted, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                r['prepTime'] as String? ?? '20 min',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: diffColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  difficulty,
                                  style: TextStyle(color: diffColor, fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${r['calories']} kcal',
                        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                  ],
                ),

                if (r['nutritionHighlight'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.success.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Text('💚', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r['nutritionHighlight'] as String,
                            style: const TextStyle(color: AppTheme.success, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if ((r['steps'] as List?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'HOW TO MAKE IT',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...(r['steps'] as List).asMap().entries.map((step) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${step.key + 1}',
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            step.value as String,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],

                if ((r['missingIngredients'] as List?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.divider),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shopping_cart_outlined,
                          color: AppTheme.warning, size: 14),
                      const SizedBox(width: 6),
                      const Text(
                        'May also need: ',
                        style: TextStyle(color: AppTheme.warning, fontSize: 12),
                      ),
                      Expanded(
                        child: Text(
                          (r['missingIngredients'] as List).join(', '),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    ];
  }
}