import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Gradient Text ────────────────────────────────────────────
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;
  const GradientText(this.text, {super.key, this.style, this.gradient = AppTheme.primaryGradient});
  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: (b) => gradient.createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
    child: Text(text, style: style),
  );
}

// ─── Glass Card ───────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final Color? borderColor;
  const GlassCard({super.key, required this.child, this.padding,
    this.radius = 20, this.gradient, this.onTap, this.borderColor});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? const Color(0xFFEEE8FF), width: 1),
        boxShadow: [BoxShadow(
          color: AppTheme.primary.withOpacity(0.07),
          blurRadius: 16, offset: const Offset(0, 4),
        )],
      ),
      child: child,
    ),
  );
}

// ─── Macro Bar ────────────────────────────────────────────────
class MacroBar extends StatelessWidget {
  final String label;
  final double value, goal;
  final Color color;
  final String unit;
  const MacroBar({super.key, required this.label, required this.value,
    required this.goal, required this.color, this.unit = 'g'});
  @override
  Widget build(BuildContext context) {
    final pct = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        RichText(text: TextSpan(children: [
          TextSpan(text: '${value.toStringAsFixed(0)}',
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          TextSpan(text: ' / ${goal.toStringAsFixed(0)}$unit',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ])),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: pct,
          backgroundColor: color.withOpacity(0.12),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 7,
        ),
      ),
    ]);
  }
}

// ─── Calorie Ring ─────────────────────────────────────────────
class CalorieRing extends StatelessWidget {
  final int consumed, goal;
  final double size;
  const CalorieRing({super.key, required this.consumed, required this.goal, this.size = 150});
  @override
  Widget build(BuildContext context) {
    final pct = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;
    final remaining = (goal - consumed).clamp(0, goal);
    return SizedBox(width: size, height: size,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(width: size, height: size,
          child: CircularProgressIndicator(
            value: pct, strokeWidth: 11,
            backgroundColor: const Color(0xFFF0EBFF),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$consumed', style: const TextStyle(
              color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w800)),
          const Text('kcal', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 2),
          Text('$remaining left', style: const TextStyle(
              color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

// ─── Health Score Badge ───────────────────────────────────────
class HealthScoreBadge extends StatelessWidget {
  final String score;
  final double size;
  const HealthScoreBadge({super.key, required this.score, this.size = 48});
  Color get _color => {'A': AppTheme.success, 'B': AppTheme.primary,
    'C': AppTheme.warning, 'D': AppTheme.error}[score] ?? AppTheme.textMuted;
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: _color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _color, width: 1.5),
    ),
    child: Center(child: Text(score, style: TextStyle(
        color: _color, fontSize: size * 0.45, fontWeight: FontWeight.w900))),
  );
}

// ─── Meal Type Chip ───────────────────────────────────────────
class MealTypeChip extends StatelessWidget {
  final String type;
  final bool selected;
  final VoidCallback onTap;
  const MealTypeChip({super.key, required this.type, required this.selected, required this.onTap});
  String get emoji => {'breakfast': '🌅','lunch': '☀️','dinner': '🌙','snack': '🍎'}[type] ?? '🍽️';
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary.withOpacity(0.1) : const Color(0xFFF5F0FF),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
            color: selected ? AppTheme.primary : Colors.transparent, width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(type[0].toUpperCase() + type.substring(1),
            style: TextStyle(
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
              fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            )),
      ]),
    ),
  );
}

// ─── Shimmer Loading ──────────────────────────────────────────
class ShimmerBox extends StatefulWidget {
  final double width, height;
  final double radius;
  const ShimmerBox({super.key, required this.width, required this.height, this.radius = 12});
  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}
class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _a = Tween<double>(begin: -1, end: 2).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      width: widget.width, height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        gradient: LinearGradient(
          begin: Alignment(_a.value - 1, 0), end: Alignment(_a.value, 0),
          colors: const [Color(0xFFEEE8FF), Color(0xFFF5F0FF), Color(0xFFEEE8FF)],
        ),
      ),
    ),
  );
}

// ─── Animated Number ──────────────────────────────────────────
class AnimatedNumber extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final String suffix;
  const AnimatedNumber({super.key, required this.value, this.style, this.suffix = ''});
  @override
  State<AnimatedNumber> createState() => _AnimatedNumberState();
}
class _AnimatedNumberState extends State<AnimatedNumber> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<int> _a;
  int _prev = 0;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _a = IntTween(begin: 0, end: widget.value).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _c.forward();
  }
  @override
  void didUpdateWidget(covariant AnimatedNumber old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _a = IntTween(begin: _prev, end: widget.value).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
      _prev = widget.value;
      _c.forward(from: 0);
    }
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Text('${_a.value}${widget.suffix}', style: widget.style),
  );
}