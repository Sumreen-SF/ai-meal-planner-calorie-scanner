import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/ai_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/error_card.dart';

class MoodMealsScreen extends StatefulWidget {
  final UserProfile profile;
  const MoodMealsScreen({super.key, required this.profile});

  @override
  State<MoodMealsScreen> createState() => _MoodMealsScreenState();
}

class _MoodMealsScreenState extends State<MoodMealsScreen> {
  static const List<Map<String, dynamic>> _moods = [
    {'label': 'Energized', 'emoji': '⚡', 'color': 0xFFF59E0B, 'desc': 'Full of energy'},
    {'label': 'Stressed', 'emoji': '😤', 'color': 0xFFEF4444, 'desc': 'Feeling tense'},
    {'label': 'Happy', 'emoji': '😄', 'color': 0xFF10B981, 'desc': 'In a great mood'},
    {'label': 'Tired', 'emoji': '😴', 'color': 0xFF6366F1, 'desc': 'Low energy'},
    {'label': 'Sad', 'emoji': '😢', 'color': 0xFF3B82F6, 'desc': 'Need comfort'},
    {'label': 'Focused', 'emoji': '🎯', 'color': 0xFF00D4AA, 'desc': 'Deep work mode'},
    {'label': 'Romantic', 'emoji': '💕', 'color': 0xFFEC4899, 'desc': 'Feeling lovey'},
    {'label': 'Adventurous', 'emoji': '🌍', 'color': 0xFFF97316, 'desc': 'Try something new'},
    {'label': 'Anxious', 'emoji': '😰', 'color': 0xFF8B5CF6, 'desc': 'Feeling worried'},
    {'label': 'Chill', 'emoji': '😎', 'color': 0xFF06B6D4, 'desc': 'Relaxed & calm'},
  ];

  String? _selectedMood;
  String? _selectedEmoji;
  MoodMealSuggestion? _suggestion;
  bool _loading = false;

  String? _error;

  Future<void> _getSuggestion(String mood, String emoji) async {
    setState(() {
      _selectedMood = mood;
      _selectedEmoji = emoji;
      _loading = true;
      _suggestion = null;
      _error = null;
    });

    // AIService.getMoodMealSuggestion now NEVER throws —
    // it always returns either AI data or local fallback content.
    final s = await AIService.getMoodMealSuggestion(
      mood: mood,
      emoji: emoji,
      profile: widget.profile,
    );
    setState(() {
      _suggestion = s;
      _loading = false;
    });
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
                      'Mood Meals',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                      gradient: AppTheme.pinkGradient,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Eat for how you feel — science-backed suggestions',
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
                const SizedBox(height: 16),
                _buildMoodGrid(),
                const SizedBox(height: 20),
                if (_loading) _buildLoadingCard(),
                if (_error != null && !_loading) ErrorCard(message: _error!),
                if (_suggestion != null && !_loading) _buildSuggestionCard(),
                if (_selectedMood == null) _buildIntroCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return GlassCard(
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Text('🧠', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 16),
          const Text(
            'Food & Mood Science',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Different nutrients affect neurotransmitters like serotonin, dopamine, and cortisol. Select your current mood to get personalized food recommendations backed by nutritional psychology.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.7),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SciencePill(label: 'Serotonin', emoji: '😊'),
              _SciencePill(label: 'Dopamine', emoji: '⚡'),
              _SciencePill(label: 'Cortisol', emoji: '😤'),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildMoodGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _moods.length,
      itemBuilder: (_, i) {
        final mood = _moods[i];
        final color = Color(mood['color'] as int);
        final selected = _selectedMood == mood['label'];

        return GestureDetector(
          onTap: () => _getSuggestion(mood['label'] as String, mood['emoji'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: selected ? color.withOpacity(0.2) : AppTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? color : const Color(0xFFEEE8FF),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, spreadRadius: 1)]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(mood['emoji'] as String, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 6),
                Text(
                  mood['label'] as String,
                  style: TextStyle(
                    color: selected ? color : AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return GlassCard(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            _selectedEmoji ?? '🤔',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing your $_selectedMood mood...',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Consulting nutritional psychology database',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            strokeWidth: 2,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard() {
    final s = _suggestion!;
    return Column(
      children: [
        GlassCard(
          borderColor: AppTheme.accent.withOpacity(0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MOOD-MATCHED MEALS',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'For ${s.mood} Mood',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Reasoning box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🧠', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.reasoning,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'RECOMMENDED MEALS',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...s.suggestions.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEEE8FF)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: AppTheme.pinkGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          e.value,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.add_circle_outline_rounded,
                          color: AppTheme.primary, size: 22),
                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tap any meal to add it to your food log, or use the Calorie Scanner to analyze it first.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SciencePill extends StatelessWidget {
  final String label;
  final String emoji;
  const _SciencePill({required this.label, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFEEE8FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}