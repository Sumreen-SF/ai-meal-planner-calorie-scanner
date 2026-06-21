import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../main.dart';

class ProfileSetupScreen extends StatefulWidget {
  /// When opened from the profile edit sheet, these are provided.
  /// When opened as initial setup, both are null.
  final UserProfile? profile;
  final void Function(UserProfile)? onSave;

  const ProfileSetupScreen({
    super.key,
    this.profile,
    this.onSave,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _pageCtrl = PageController();
  int _step = 0;

  // Form state
  late final TextEditingController _nameCtrl;
  late int _age;
  late double _weight;
  late double _height;
  late String _gender;
  late String _goal;
  late int _activityLevel;

  final _activityLabels = ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active'];
  final _activityEmojis = ['🛋️', '🚶', '🏃', '🏋️'];
  final _activityMults  = [1.2, 1.375, 1.55, 1.725];

  final _goals = [
    {'key': 'lose_weight', 'label': 'Lose Weight',    'emoji': '⚡', 'desc': 'Burn fat, feel lighter'},
    {'key': 'gain_muscle', 'label': 'Gain Muscle',    'emoji': '💪', 'desc': 'Build strength & size'},
    {'key': 'maintain',    'label': 'Stay Healthy',   'emoji': '⚖️', 'desc': 'Balanced lifestyle'},
    {'key': 'keto',        'label': 'Keto Diet',      'emoji': '🥑', 'desc': 'Low carb, high fat'},
    {'key': 'vegan',       'label': 'Vegan',          'emoji': '🌱', 'desc': 'Plant-based eating'},
  ];

  /// Whether we're editing an existing profile (vs. first-time setup)
  bool get _isEditing => widget.profile != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill from existing profile if editing, otherwise use defaults
    final p = widget.profile;
    _nameCtrl     = TextEditingController(text: p?.name ?? '');
    _age          = p?.age ?? 25;
    _weight       = p?.weight ?? 70;
    _height       = p?.height ?? 170;
    _gender       = p?.gender ?? 'male';
    _goal         = p?.goal ?? 'maintain';
    _activityLevel = 1; // default; UserProfile doesn't store this, keep as-is
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  int get _calculatedCalories {
    double bmr = _gender == 'male'
        ? 10 * _weight + 6.25 * _height - 5 * _age + 5
        : 10 * _weight + 6.25 * _height - 5 * _age - 161;
    double tdee = bmr * _activityMults[_activityLevel];
    switch (_goal) {
      case 'lose_weight': return (tdee - 400).round();
      case 'gain_muscle': return (tdee + 300).round();
      default: return tdee.round();
    }
  }

  Future<void> _finish() async {
    final cals    = _calculatedCalories;
    final protein = _goal == 'gain_muscle' ? 180.0 : 130.0;
    final carbs   = _goal == 'keto' ? 30.0 : (_goal == 'lose_weight' ? 150.0 : 250.0);
    final fat     = _goal == 'keto' ? 150.0 : 65.0;

    final updated = UserProfile(
      name: _nameCtrl.text.trim().isEmpty ? 'User' : _nameCtrl.text.trim(),
      age: _age, weight: _weight, height: _height,
      gender: _gender, goal: _goal,
      dailyCalorieGoal: cals,
      proteinGoal: protein, carbsGoal: carbs, fatGoal: fat,
    );

    await StorageService.saveProfile(updated);

    if (!mounted) return;

    if (_isEditing) {
      // Return updated profile to caller and close the sheet
      widget.onSave?.call(updated);
      Navigator.pop(context);
    } else {
      // First-time setup — go to the main app
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    }
  }

  void _next() {
    if (_step < 2) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) {
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 20, 24, 20),
            decoration: const BoxDecoration(
              gradient: AppTheme.heroBgGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_step > 0)
                  GestureDetector(
                    onTap: _back,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 18),
                    ),
                  )
                else if (_isEditing)
                // Show a close button when editing via the sheet
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 18),
                    ),
                  )
                else
                  const SizedBox(height: 34),
                const SizedBox(height: 12),
                Text(
                  ['Tell us about yourself', 'Your body metrics', 'Your fitness goal'][_step],
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  ['Step 1 of 3 — Basic info', 'Step 2 of 3 — Body data', 'Step 3 of 3 — Goal'][_step],
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 13),
                ),
                const SizedBox(height: 16),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (_step + 1) / 3,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _step = i),
              children: [_buildStep1(), _buildStep2(), _buildStep3()],
            ),
          ),
          // Next / Save button
          Padding(
            padding: EdgeInsets.fromLTRB(
                24, 0, 24, MediaQuery.of(context).padding.bottom + 20),
            child: GestureDetector(
              onTap: _next,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.primary.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: Center(
                  child: Text(
                    _step == 2
                        ? (_isEditing ? 'Save Changes ✓' : "Let's Go! 🚀")
                        : 'Continue →',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        _Label('YOUR NAME'),
        const SizedBox(height: 10),
        TextField(
          controller: _nameCtrl,
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'What should we call you?',
            prefixIcon:
            Icon(Icons.person_outline_rounded, color: AppTheme.primary),
          ),
        ),
        const SizedBox(height: 24),
        _Label('AGE'),
        const SizedBox(height: 10),
        _StepperCard(
          value: _age,
          unit: 'years',
          onDec: () => setState(() => _age = (_age - 1).clamp(10, 100)),
          onInc: () => setState(() => _age = (_age + 1).clamp(10, 100)),
        ),
        const SizedBox(height: 24),
        _Label('GENDER'),
        const SizedBox(height: 10),
        Row(
            children: ['male', 'female']
                .map((g) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: g == 'male' ? 8 : 0),
                child: GestureDetector(
                  onTap: () => setState(() => _gender = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _gender == g
                          ? AppTheme.primary.withOpacity(0.1)
                          : AppTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _gender == g
                            ? AppTheme.primary
                            : const Color(0xFFEEE8FF),
                        width: _gender == g ? 2 : 1,
                      ),
                      boxShadow: _gender == g
                          ? [
                        BoxShadow(
                          color:
                          AppTheme.primary.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                          : [],
                    ),
                    child: Column(children: [
                      Text(g == 'male' ? '👨' : '👩',
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 6),
                      Text(
                        g == 'male' ? 'Male' : 'Female',
                        style: TextStyle(
                          color: _gender == g
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                          fontWeight: _gender == g
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ))
                .toList()),
      ]),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        _Label('WEIGHT'),
        const SizedBox(height: 10),
        _SliderCard(
          value: _weight,
          min: 30,
          max: 200,
          unit: 'kg',
          onChanged: (v) => setState(() => _weight = v),
          color: AppTheme.accent,
        ),
        const SizedBox(height: 20),
        _Label('HEIGHT'),
        const SizedBox(height: 10),
        _SliderCard(
          value: _height,
          min: 100,
          max: 250,
          unit: 'cm',
          onChanged: (v) => setState(() => _height = v),
          color: AppTheme.accentBlue,
        ),
        const SizedBox(height: 20),
        _Label('ACTIVITY LEVEL'),
        const SizedBox(height: 10),
        ...List.generate(
            4,
                (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _activityLevel = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _activityLevel == i
                        ? AppTheme.primary.withOpacity(0.08)
                        : AppTheme.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _activityLevel == i
                          ? AppTheme.primary
                          : const Color(0xFFEEE8FF),
                      width: _activityLevel == i ? 2 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Text(_activityEmojis[i],
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 14),
                    Text(
                      _activityLabels[i],
                      style: TextStyle(
                        color: _activityLevel == i
                            ? AppTheme.primary
                            : AppTheme.textPrimary,
                        fontWeight: _activityLevel == i
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    if (_activityLevel == i)
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 14),
                      ),
                  ]),
                ),
              ),
            )),
      ]),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        ..._goals.map((g) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => setState(() => _goal = g['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _goal == g['key']
                    ? AppTheme.primary.withOpacity(0.08)
                    : AppTheme.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _goal == g['key']
                      ? AppTheme.primary
                      : const Color(0xFFEEE8FF),
                  width: _goal == g['key'] ? 2 : 1,
                ),
                boxShadow: _goal == g['key']
                    ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
                    : [],
              ),
              child: Row(children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _goal == g['key']
                        ? AppTheme.primary.withOpacity(0.12)
                        : const Color(0xFFF5F0FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                      child: Text(g['emoji']!,
                          style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g['label']!,
                            style: TextStyle(
                              color: _goal == g['key']
                                  ? AppTheme.primary
                                  : AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(g['desc']!,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                        ])),
                if (_goal == g['key'])
                  Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14)),
              ]),
            ),
          ),
        )),
        const SizedBox(height: 8),
        // Calculated result preview
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(children: [
            const Text('🎯', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Your daily calorie goal',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(
                '$_calculatedCalories kcal / day',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600));
}

class _StepperCard extends StatelessWidget {
  final int value;
  final String unit;
  final VoidCallback onDec, onInc;
  const _StepperCard(
      {required this.value,
        required this.unit,
        required this.onDec,
        required this.onInc});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    decoration: BoxDecoration(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEEE8FF)),
    ),
    child: Row(children: [
      GestureDetector(
          onTap: onDec,
          child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: const Color(0xFFF5F0FF),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.remove_rounded,
                  color: AppTheme.primary))),
      Expanded(
          child: Center(
              child: RichText(
                  text: TextSpan(children: [
                    TextSpan(
                        text: '$value',
                        style: GoogleFonts.poppins(
                            color: AppTheme.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800)),
                    TextSpan(
                        text: ' $unit',
                        style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary, fontSize: 14)),
                  ])))),
      GestureDetector(
          onTap: onInc,
          child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white))),
    ]),
  );
}

class _SliderCard extends StatelessWidget {
  final double value, min, max;
  final String unit;
  final Color color;
  final ValueChanged<double> onChanged;
  const _SliderCard(
      {required this.value,
        required this.min,
        required this.max,
        required this.unit,
        required this.color,
        required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
    decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEE8FF))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RichText(
          text: TextSpan(children: [
            TextSpan(
                text: value.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
            TextSpan(
                text: ' $unit',
                style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary, fontSize: 14)),
          ])),
      SliderTheme(
        data: SliderThemeData(
          activeTrackColor: color,
          thumbColor: color,
          inactiveTrackColor: color.withOpacity(0.15),
          overlayColor: color.withOpacity(0.12),
          trackHeight: 5,
        ),
        child: Slider(value: value, min: min, max: max, onChanged: onChanged),
      ),
    ]),
  );
}