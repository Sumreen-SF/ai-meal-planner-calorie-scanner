import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'models/models.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/calorie_scanner_screen.dart';
import 'screens/meal_plan_screen.dart';
import 'screens/mood_meals_screen.dart';
import 'screens/pantry_oracle_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'widgets/log_meal_sheet.dart';
import 'widgets/nutri_logo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const NutriAIApp());
}

class NutriAIApp extends StatelessWidget {
  const NutriAIApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _Splash(),
    );
  }
}

// ── Splash — decides where to navigate ───────────────────────
class _Splash extends StatefulWidget {
  const _Splash();
  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 1800), _route);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _route() async {
    final seenOnboarding = await AuthService.hasSeenOnboarding();
    final loggedIn       = await AuthService.isLoggedIn();
    final hasProfile     = await AuthService.hasProfile();
    if (!mounted) return;

    Widget dest;
    if (!seenOnboarding)       dest = const OnboardingScreen();
    else if (!loggedIn)        dest = const AuthScreen();
    else if (!hasProfile)      dest = const ProfileSetupScreen();
    else                       dest = const AppShell();

    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => dest,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroBgGradient),
        child: Center(
          child: FadeTransition(opacity: _fade,
            child: ScaleTransition(scale: _scale,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const NutriLogo(size: 96, showText: false),
                const SizedBox(height: 20),
                Text('NutriAI', style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800,
                )),
                const SizedBox(height: 8),
                Text('Eat Smart. Live Better.', style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7), fontSize: 15,
                )),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Main App Shell ────────────────────────────────────────────
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  UserProfile _profile = UserProfile.defaultProfile;

  @override
  void initState() { super.initState(); _loadProfile(); }

  Future<void> _loadProfile() async {
    final p = await StorageService.getProfile();
    setState(() => _profile = p);
  }

  void _openLog() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogMealSheet(onLogged: () => setState(() {})),
    );
  }

  void _openProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92, maxChildSize: 0.95, minChildSize: 0.5,
        builder: (_, ctrl) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: ProfileSetupScreen(
            profile: _profile,
            onSave: (p) => setState(() => _profile = p),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(profile: _profile),
      MealPlanScreen(profile: _profile),
      CalorieScannerScreen(profile: _profile),
      MoodMealsScreen(profile: _profile),
      PantryOracleScreen(profile: _profile),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(index: _tab, children: screens),
      floatingActionButton: _tab == 0
          ? _GlowFAB(onPressed: _openLog)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _BottomNav(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        onProfileTap: _openProfile,
      ),
    );
  }
}

// ── Glowing FAB ───────────────────────────────────────────────
class _GlowFAB extends StatefulWidget {
  final VoidCallback onPressed;
  const _GlowFAB({required this.onPressed});
  @override
  State<_GlowFAB> createState() => _GlowFABState();
}
class _GlowFABState extends State<_GlowFAB> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _g;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _g = Tween<double>(begin: 6, end: 18).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _g,
    builder: (_, __) => GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        width: 58, height: 58,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
              color: AppTheme.primary.withOpacity(0.5),
              blurRadius: _g.value, spreadRadius: 2)],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    ),
  );
}

// ── Bottom Nav Bar ────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onProfileTap;
  const _BottomNav({required this.currentIndex, required this.onTap, required this.onProfileTap});

  static const _items = [
    {'icon': Icons.home_rounded,            'label': 'Home'},
    {'icon': Icons.calendar_month_rounded,  'label': 'Plan'},
    {'icon': Icons.document_scanner_rounded,'label': 'Scan'},
    {'icon': Icons.mood_rounded,            'label': 'Mood'},
    {'icon': Icons.kitchen_rounded,         'label': 'Pantry'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFEEE8FF), width: 1)),
        boxShadow: [BoxShadow(
            color: AppTheme.primary.withOpacity(0.08),
            blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              ...List.generate(_items.length, (i) {
                final sel = currentIndex == i;
                final icon = _items[i]['icon'] as IconData;
                final label = _items[i]['label'] as String;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.primary.withOpacity(0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon,
                            color: sel ? AppTheme.primary : AppTheme.textMuted,
                            size: sel ? 24 : 22),
                      ),
                      const SizedBox(height: 1),
                      Text(label, style: TextStyle(
                        color: sel ? AppTheme.primary : AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      )),
                    ]),
                  ),
                );
              }),
              // Profile avatar button
              GestureDetector(
                onTap: onProfileTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}