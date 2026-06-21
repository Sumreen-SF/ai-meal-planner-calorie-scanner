import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      gradient: AppTheme.onboardGradient1,
      emoji: '🥗',
      art: _FoodArt1(),
      title: 'Welcome to NutriAI',
      subtitle: 'Your personal AI-powered nutrition companion that understands your body and goals.',
      badge: '✨ Smart Nutrition',
    ),
    _Slide(
      gradient: AppTheme.onboardGradient2,
      emoji: '📸',
      art: _FoodArt2(),
      title: 'Scan Any Food Instantly',
      subtitle: 'Describe any meal and get full calorie & macro breakdown in seconds — powered by AI.',
      badge: '⚡ Instant Analysis',
    ),
    _Slide(
      gradient: AppTheme.onboardGradient3,
      emoji: '🗓️',
      art: _FoodArt3(),
      title: 'AI Meal Plans Made For You',
      subtitle: 'Get a personalised daily meal plan based on your goal, preferences, and calorie needs.',
      badge: '🎯 Personalised',
    ),
    _Slide(
      gradient: AppTheme.onboardGradient4,
      emoji: '😄',
      art: _FoodArt4(),
      title: 'Eat For Your Mood',
      subtitle: 'Select how you feel — get science-backed meal suggestions that match your emotions.',
      badge: '🧠 Mood Science',
    ),
    _Slide(
      gradient: AppTheme.onboardGradient5,
      emoji: '🔮',
      art: _FoodArt5(),
      title: 'Your Pantry, Your Recipes',
      subtitle: 'Tell us what\'s in your fridge. We\'ll create delicious recipes from what you already have.',
      badge: '🌟 Zero Waste',
    ),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await AuthService.markOnboardingSeen();
    if (mounted) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const AuthScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
          ),
          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 24,
            child: _page < _slides.length - 1
                ? GestureDetector(
              onTap: _finish,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                ),
                child: Text('Skip', style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            )
                : const SizedBox(),
          ),
          // Bottom controls
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(32, 24, 32, MediaQuery.of(context).padding.bottom + 28),
              child: Row(
                children: [
                  SmoothPageIndicator(
                    controller: _ctrl,
                    count: _slides.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: Colors.white,
                      dotColor: Colors.white.withOpacity(0.35),
                      dotHeight: 8, dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _next,
                    child: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15),
                              blurRadius: 16, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Icon(
                        _page == _slides.length - 1
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        color: _slides[_page].gradient.colors.first,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  final LinearGradient gradient;
  final String emoji;
  final Widget art;
  final String title;
  final String subtitle;
  final String badge;
  const _Slide({required this.gradient, required this.emoji,
    required this.art, required this.title,
    required this.subtitle, required this.badge});
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({super.key, required this.slide});
  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Container(
      decoration: BoxDecoration(gradient: slide.gradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Badge chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.white.withOpacity(0.4)),
              ),
              child: Text(slide.badge,
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            SizedBox(height: h * 0.04),
            // Art panel (card)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                height: h * 0.35,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: slide.art,
                ),
              ),
            ),
            SizedBox(height: h * 0.05),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(slide.title,
                style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 28,
                  fontWeight: FontWeight.w800, height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Text(slide.subtitle,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 15, height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// ── Illustration art widgets (drawn in Flutter, no image files needed) ──

class _FoodArt1 extends StatelessWidget {
  const _FoodArt1();
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background circles
        Positioned(top: -20, left: -20,
            child: _Circle(80, Colors.white.withOpacity(0.1))),
        Positioned(bottom: -30, right: -30,
            child: _Circle(100, Colors.white.withOpacity(0.08))),
        // Food emoji grid
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _EmojiCard('🥗', 56), const SizedBox(width: 12),
            _EmojiCard('🍎', 56), const SizedBox(width: 12),
            _EmojiCard('🥑', 56),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _EmojiCard('🫐', 48), const SizedBox(width: 12),
            _EmojiCard('🥦', 60, highlighted: true), const SizedBox(width: 12),
            _EmojiCard('🍇', 48),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _EmojiCard('🥕', 48), const SizedBox(width: 12),
            _EmojiCard('🍓', 56), const SizedBox(width: 12),
            _EmojiCard('🥒', 48),
          ]),
        ]),
        // AI sparkle overlay
        Positioned(top: 18, right: 28,
            child: _SparkleTag('AI Powered ✨')),
      ],
    );
  }
}

class _FoodArt2 extends StatelessWidget {
  const _FoodArt2();
  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      Positioned(top: -15, right: -15, child: _Circle(90, Colors.white.withOpacity(0.1))),
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        _EmojiCard('🍕', 72, highlighted: true),
        const SizedBox(height: 14),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            _MacroRow('🔥 Calories', '285 kcal'),
            const SizedBox(height: 6),
            _MacroRow('💪 Protein', '12g'),
            const SizedBox(height: 6),
            _MacroRow('🌾 Carbs', '34g'),
            const SizedBox(height: 6),
            _MacroRow('🥑 Fat', '11g'),
          ]),
        ),
      ]),
      Positioned(bottom: 18, right: 28, child: _SparkleTag('Health Score: A')),
    ]);
  }
}

class _FoodArt3 extends StatelessWidget {
  const _FoodArt3();
  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      Positioned(bottom: -20, left: -20, child: _Circle(80, Colors.white.withOpacity(0.1))),
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        _PlanRow('🌅 Breakfast', 'Oatmeal & Berries', '380 kcal'),
        const SizedBox(height: 8),
        _PlanRow('☀️ Lunch', 'Grilled Chicken Salad', '450 kcal', highlighted: true),
        const SizedBox(height: 8),
        _PlanRow('🌙 Dinner', 'Salmon & Quinoa', '520 kcal'),
        const SizedBox(height: 8),
        _PlanRow('🍎 Snack', 'Greek Yogurt', '180 kcal'),
      ]),
    ]);
  }
}

class _FoodArt4 extends StatelessWidget {
  const _FoodArt4();
  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('😄', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
          _MoodChip('⚡ Energized'),
          _MoodChip('😤 Stressed'),
          _MoodChip('😴 Tired'),
          _MoodChip('🎯 Focused', active: true),
          _MoodChip('😢 Sad'),
          _MoodChip('🌍 Adventurous'),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('🧠 ', style: TextStyle(fontSize: 16)),
            Text('Serotonin-boosting meals →',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    ]);
  }
}

class _FoodArt5 extends StatelessWidget {
  const _FoodArt5();
  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🔮', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
          _IngChip('🥚 Eggs'), _IngChip('🧀 Cheese'),
          _IngChip('🥕 Carrot'), _IngChip('🍅 Tomato'),
          _IngChip('🧄 Garlic'), _IngChip('🥛 Milk'),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('→', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('3 Recipes Found!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    ]);
  }
}

// ── Small reusable art pieces ─────────────────────────────────

class _Circle extends StatelessWidget {
  final double size; final Color color;
  const _Circle(this.size, this.color);
  @override
  Widget build(BuildContext context) =>
      Container(width: size, height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _EmojiCard extends StatelessWidget {
  final String emoji; final double size; final bool highlighted;
  const _EmojiCard(this.emoji, this.size, {this.highlighted = false});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: highlighted ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(14),
      border: highlighted ? Border.all(color: Colors.white, width: 2) : null,
    ),
    child: Center(child: Text(emoji, style: TextStyle(fontSize: size * 0.55))),
  );
}

class _SparkleTag extends StatelessWidget {
  final String text;
  const _SparkleTag(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.25),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white.withOpacity(0.5)),
    ),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
  );
}

class _MacroRow extends StatelessWidget {
  final String label; final String value;
  const _MacroRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    ],
  );
}

class _PlanRow extends StatelessWidget {
  final String type, name, cals; final bool highlighted;
  const _PlanRow(this.type, this.name, this.cals, {this.highlighted = false});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: highlighted ? Colors.white.withOpacity(0.28) : Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      border: highlighted ? Border.all(color: Colors.white.withOpacity(0.6), width: 1.5) : null,
    ),
    child: Row(children: [
      Text(type, style: const TextStyle(fontSize: 12, color: Colors.white)),
      const SizedBox(width: 8),
      Expanded(child: Text(name,
          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600))),
      Text(cals, style: const TextStyle(fontSize: 11, color: Colors.white)),
    ]),
  );
}

class _MoodChip extends StatelessWidget {
  final String label; final bool active;
  const _MoodChip(this.label, {this.active = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: active ? Colors.white.withOpacity(0.35) : Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(99),
      border: active ? Border.all(color: Colors.white, width: 1.5) : null,
    ),
    child: Text(label,
        style: TextStyle(color: Colors.white, fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
  );
}

class _IngChip extends StatelessWidget {
  final String text;
  const _IngChip(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white.withOpacity(0.4)),
    ),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}