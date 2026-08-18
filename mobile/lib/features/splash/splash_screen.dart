import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});
  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
    ..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: controller, curve: Curves.elasticOut);
    final fade = CurvedAnimation(parent: controller, curve: Curves.easeIn);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF03060B), Color(0xFF0A1625), Color(0xFF211407)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: Center(
          child: FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.65, end: 1).animate(scale),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 124,
                    height: 124,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(color: ZTheme.gold.withValues(alpha: 0.55), width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, 16)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Image.asset(
                        'assets/brand/zynora-logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.sports_esports_rounded,
                          color: Colors.white,
                          size: 58,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('ZYNORA', style: TextStyle(color: ZTheme.gold, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 3)),
                  const SizedBox(height: 8),
                  Text('RISE OF LEGENDS', style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
