import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/constants.dart';

// ─── MeterBar ─────────────────────────────────────────────────────────────────

class MeterBar extends StatelessWidget {
  final String label;
  final int value; // 0-100
  final Color? color;

  const MeterBar({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  Color get _barColor {
    if (color != null) return color!;
    if (value >= 75) return kGreen;
    if (value >= 45) return kAmber;
    return kRed;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 12, color: kMuted),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 8,
                backgroundColor: kWarm,
                valueColor: AlwaysStoppedAnimation(_barColor),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: GoogleFonts.spaceMono(fontSize: 11, color: kMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ConfidenceBadge ──────────────────────────────────────────────────────────

class ConfidenceBadge extends StatelessWidget {
  final double confidence;
  final String? label;

  const ConfidenceBadge({super.key, required this.confidence, this.label});

  Color get _bg {
    if (confidence >= 0.80) return kGreenBg;
    if (confidence >= 0.50) return kYellowBg;
    return kRedBg;
  }

  Color get _fg {
    if (confidence >= 0.80) return kGreen;
    if (confidence >= 0.50) return kYellow;
    return kRed;
  }

  String get _text => label ?? '${(confidence * 100).toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _text,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _fg,
        ),
      ),
    );
  }
}

// ─── InfoCard ─────────────────────────────────────────────────────────────────

class InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? iconColor;

  const InfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kBrown.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: kWarm,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: iconColor ?? kAmber),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kBrown,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0E8DC)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─── PawLoading ───────────────────────────────────────────────────────────────

class PawLoading extends StatefulWidget {
  final String? message;
  const PawLoading({super.key, this.message});

  @override
  State<PawLoading> createState() => _PawLoadingState();
}

class _PawLoadingState extends State<PawLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _bounce,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, _bounce.value),
            child: child,
          ),
          child: const Text('🐾', style: TextStyle(fontSize: 48)),
        ),
        const SizedBox(height: 16),
        Text(
          widget.message ?? 'Analysing…',
          style: GoogleFonts.dmSans(fontSize: 14, color: kMuted),
        ),
      ],
    );
  }
}

// ─── TagChip ──────────────────────────────────────────────────────────────────

class TagChip extends StatelessWidget {
  final String label;
  final Color? bg;
  final Color? fg;
  final VoidCallback? onTap;

  const TagChip({
    super.key,
    required this.label,
    this.bg,
    this.fg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg ?? kWarm,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: fg ?? kBrown2,
        ),
      ),
    );
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: chip);
    }
    return chip;
  }
}

// ─── SectionHeader ────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String text;
  const SectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.spaceMono(
          fontSize: 10,
          letterSpacing: 1.5,
          color: kMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── StatusDot ────────────────────────────────────────────────────────────────

class StatusDot extends StatelessWidget {
  final bool online;
  const StatusDot({super.key, required this.online});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: online ? kGreen : kRed,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          online ? 'Online' : 'Offline',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: online ? kGreen : kRed,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}