import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/nutri_logo.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'profile_setup_screen.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _loading = false;
  String? _error;

  // Login
  final _loginEmail    = TextEditingController();
  final _loginPassword = TextEditingController();
  bool _loginObscure   = true;

  // Signup
  final _signupName     = TextEditingController();
  final _signupEmail    = TextEditingController();
  final _signupPassword = TextEditingController();
  final _signupConfirm  = TextEditingController();
  bool _signupObscure   = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _loginEmail.dispose(); _loginPassword.dispose();
    _signupName.dispose(); _signupEmail.dispose();
    _signupPassword.dispose(); _signupConfirm.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    final err = await AuthService.logIn(_loginEmail.text, _loginPassword.text);
    if (!mounted) return;
    if (err != null) { setState(() { _error = err; _loading = false; }); return; }
    _navigate();
  }

  Future<void> _signup() async {
    if (_signupPassword.text != _signupConfirm.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final err = await AuthService.signUp(
        _signupEmail.text, _signupPassword.text, _signupName.text);
    if (!mounted) return;
    if (err != null) { setState(() { _error = err; _loading = false; }); return; }
    _navigate();
  }

  Future<void> _navigate() async {
    final hasProfile = await AuthService.hasProfile();
    if (!mounted) return;
    if (!hasProfile) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileSetupScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppShell()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero header
            Container(
              height: size.height * 0.32,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppTheme.heroBgGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const NutriLogo(size: 72),
                    const SizedBox(height: 14),
                    Text('NutriAI', style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800,
                    )),
                    const SizedBox(height: 6),
                    Text('Your AI Nutrition Companion', style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8), fontSize: 14,
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEE8FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabs,
                  indicator: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [BoxShadow(
                        color: AppTheme.primary.withOpacity(0.35),
                        blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textSecondary,
                  dividerColor: Colors.transparent,
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
                  unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14),
                  tabs: const [Tab(text: 'Log In'), Tab(text: 'Sign Up')],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Error banner
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!,
                        style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                  ]),
                ),
              ),
            // Forms
            SizedBox(
              height: 380,
              child: TabBarView(
                controller: _tabs,
                children: [_buildLoginForm(), _buildSignupForm()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _Field(ctrl: _loginEmail, hint: 'Email address',
              icon: Icons.email_outlined, type: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _Field(ctrl: _loginPassword, hint: 'Password',
              icon: Icons.lock_outline_rounded, obscure: _loginObscure,
              onToggle: () => setState(() => _loginObscure = !_loginObscure)),
          const SizedBox(height: 24),
          _loading
              ? const CircularProgressIndicator(color: AppTheme.primary)
              : _GradientButton(label: 'Log In  🚀', onTap: _login),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _tabs.animateTo(1),
            child: RichText(text: TextSpan(
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
              children: [
                const TextSpan(text: "Don't have an account? "),
                TextSpan(text: 'Sign up', style: TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.w700)),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _Field(ctrl: _signupName, hint: 'Full name', icon: Icons.person_outline_rounded),
          const SizedBox(height: 12),
          _Field(ctrl: _signupEmail, hint: 'Email address',
              icon: Icons.email_outlined, type: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _Field(ctrl: _signupPassword, hint: 'Password (min 6 chars)',
              icon: Icons.lock_outline_rounded, obscure: _signupObscure,
              onToggle: () => setState(() => _signupObscure = !_signupObscure)),
          const SizedBox(height: 12),
          _Field(ctrl: _signupConfirm, hint: 'Confirm password',
              icon: Icons.lock_outline_rounded, obscure: _signupObscure),
          const SizedBox(height: 20),
          _loading
              ? const CircularProgressIndicator(color: AppTheme.primary)
              : _GradientButton(label: 'Create Account ✨', onTap: _signup),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _tabs.animateTo(0),
            child: RichText(text: TextSpan(
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
              children: [
                const TextSpan(text: "Already have an account? "),
                TextSpan(text: 'Log in', style: TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.w700)),
              ],
            )),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType type;
  final bool obscure;
  final VoidCallback? onToggle;
  const _Field({required this.ctrl, required this.hint, required this.icon,
    this.type = TextInputType.text, this.obscure = false, this.onToggle});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
        suffixIcon: onToggle != null ? IconButton(
          onPressed: onToggle,
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppTheme.textMuted, size: 18),
        ) : null,
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label; final VoidCallback onTap;
  const _GradientButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 54,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.4),
              blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Center(child: Text(label, style: GoogleFonts.poppins(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
      ),
    );
  }
}