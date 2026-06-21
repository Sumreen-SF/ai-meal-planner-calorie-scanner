import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _usersKey    = 'nutri_users';
  static const _loggedInKey = 'nutri_logged_in';
  static const _currentKey  = 'nutri_current_user';

  static String _hash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  static Future<Map<String, dynamic>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  static Future<void> _saveUsers(Map<String, dynamic> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  // ── Sign Up ───────────────────────────────────────────────────
  static Future<String?> signUp(String email, String password, String name) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty || password.length < 6) return 'Password must be at least 6 characters';
    if (!e.contains('@')) return 'Enter a valid email address';
    final users = await _loadUsers();
    if (users.containsKey(e)) return 'Account already exists. Please log in.';
    users[e] = {'name': name.trim(), 'passwordHash': _hash(password), 'email': e};
    await _saveUsers(users);
    await _setLoggedIn(e);
    return null; // null = success
  }

  // ── Log In ────────────────────────────────────────────────────
  static Future<String?> logIn(String email, String password) async {
    final e = email.trim().toLowerCase();
    final users = await _loadUsers();
    if (!users.containsKey(e)) return 'No account found. Please sign up first.';
    final stored = users[e] as Map<String, dynamic>;
    if (stored['passwordHash'] != _hash(password)) return 'Incorrect password.';
    await _setLoggedIn(e);
    return null;
  }

  // ── Log Out ───────────────────────────────────────────────────
  static Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
    await prefs.remove(_currentKey);
  }

  // ── Session ───────────────────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  static Future<String?> currentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentKey);
  }

  static Future<String?> currentUserName() async {
    final email = await currentUserEmail();
    if (email == null) return null;
    final users = await _loadUsers();
    return (users[email] as Map<String, dynamic>?)?['name'] as String?;
  }

  static Future<void> _setLoggedIn(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_currentKey, email);
  }

  // ── Check if onboarding was shown ────────────────────────────
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seen_onboarding') ?? false;
  }

  static Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
  }

  // ── Check if profile was set up ───────────────────────────────
  static Future<bool> hasProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('user_profile');
  }
}