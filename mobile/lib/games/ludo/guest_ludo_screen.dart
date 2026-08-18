import 'dart:math';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';

class GuestLudoScreen extends StatefulWidget {
  const GuestLudoScreen({super.key});

  @override
  State<GuestLudoScreen> createState() => _GuestLudoScreenState();
}

class _GuestLudoScreenState extends State<GuestLudoScreen> {
  final Random _random = Random();
  int dice = 1;
  int playerSteps = 0;
  int botSteps = 0;
  int playerWins = 0;
  bool playerTurn = true;
  bool rolling = false;
  String status = 'ارمِ النرد وابدأ رحلتك';

  Future<void> roll() async {
    if (!playerTurn || rolling) return;
    setState(() => rolling = true);
    for (var i = 0; i < 7; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 70));
      if (!mounted) return;
      setState(() => dice = _random.nextInt(6) + 1);
    }
    final value = dice;
    setState(() {
      playerSteps = min(56, playerSteps + value);
      status = playerSteps >= 56 ? 'انتصار أسطوري! الجولة لك 🏆' : 'تحركت $value خانات — دور الخصم';
      playerTurn = false;
      rolling = false;
    });
    if (playerSteps >= 56) {
      setState(() => playerWins++);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    final botDice = _random.nextInt(6) + 1;
    setState(() {
      dice = botDice;
      botSteps = min(56, botSteps + botDice);
      if (botSteps >= 56) {
        status = 'الفارس الخصم سبقك — أعد المحاولة!';
        playerSteps = 0;
        botSteps = 0;
      } else {
        status = 'الخصم تحرك $botDice — دورك الآن';
      }
      playerTurn = true;
    });
  }

  void reset() {
    setState(() {
      dice = 1;
      playerSteps = 0;
      botSteps = 0;
      playerTurn = true;
      rolling = false;
      status = 'جولة جديدة — حظًا موفقًا يا فارس زينورا';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05080E),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  ZCard(child: _arena()),
                  const SizedBox(height: 14),
                  ZCard(child: _controls()),
                  const SizedBox(height: 14),
                  _tips(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)),
            Image.asset('assets/brand/zynora-logo.png', width: 34, height: 34),
            const SizedBox(width: 8),
            const Expanded(child: Text('LUDO ARENA', style: TextStyle(color: ZTheme.gold, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.6))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .06), borderRadius: BorderRadius.circular(14)),
              child: Text('فوز $playerWins', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
            ),
          ],
        ),
      );

  Widget _arena() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _playerBadge('أنت • فارس زينورا', playerSteps, const Color(0xFF36A4FF))),
            const SizedBox(width: 8),
            Expanded(child: _playerBadge('الخصم • Shadow', botSteps, const Color(0xFFE95757))),
          ],
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: _LudoPainter(playerSteps: playerSteps, botSteps: botSteps),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 14),
        Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _playerBadge(String title, int steps, Color color) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: .08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: .25))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: steps / 56, minHeight: 6, backgroundColor: Colors.white10, color: color)),
          const SizedBox(height: 4),
          Text('$steps / 56', style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ]),
      );

  Widget _controls() => Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFD76A), Color(0xFF9B5F08)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: ZTheme.gold.withValues(alpha: .18), blurRadius: 20)],
            ),
            child: Center(child: Text('$dice', style: const TextStyle(color: Color(0xFF201305), fontSize: 34, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 12),
          Expanded(child: PrimaryButton(label: rolling ? 'جاري الرمي...' : 'ارمِ النرد', icon: Icons.casino_rounded, onPressed: playerTurn && !rolling ? roll : null)),
          const SizedBox(width: 8),
          IconButton(onPressed: reset, icon: const Icon(Icons.refresh_rounded, color: Colors.white70), tooltip: 'إعادة الجولة'),
        ],
      );

  Widget _tips() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: const Color(0xFF101722), border: Border.all(color: Colors.white10)),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.auto_awesome_rounded, color: ZTheme.gold),
          SizedBox(width: 10),
          Expanded(child: Text('هذه نسخة تدريبية تعمل دون إنترنت. عند تسجيل الدخول ستنتقل إلى غرف ZYNORA الحقيقية واللعب الجماعي عبر Render.', style: TextStyle(color: Colors.white60, height: 1.45, fontSize: 11))),
        ]),
      );
}

class _LudoPainter extends CustomPainter {
  _LudoPainter({required this.playerSteps, required this.botSteps});
  final int playerSteps;
  final int botSteps;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide;
    final rect = Rect.fromLTWH(0, 0, r, r);
    final bg = Paint()..shader = const LinearGradient(colors: [Color(0xFF17243A), Color(0xFF070C14)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24)), bg);

    final path = <Offset>[];
    final center = Offset(r / 2, r / 2);
    final radius = r * .34;
    for (var i = 0; i < 52; i++) {
      final a = -pi / 2 + (2 * pi * i / 52);
      path.add(Offset(center.dx + cos(a) * radius, center.dy + sin(a) * radius));
    }

    final cell = Paint()..color = const Color(0xFF18263A);
    final line = Paint()..color = Colors.white.withValues(alpha: .08)..style = PaintingStyle.stroke..strokeWidth = 1;
    for (var i = 0; i < path.length; i++) {
      final p = path[i];
      canvas.drawCircle(p, r * .035, cell);
      canvas.drawCircle(p, r * .035, line);
    }

    final glow = Paint()..shader = const RadialGradient(colors: [Color(0x66FFC34D), Color(0x0018273A)]).createShader(Rect.fromCircle(center: center, radius: r * .27));
    canvas.drawCircle(center, r * .27, glow);
    final crown = TextPainter(text: const TextSpan(text: '★', style: TextStyle(color: ZTheme.gold, fontSize: 42, fontWeight: FontWeight.w900)), textDirection: TextDirection.ltr)..layout();
    crown.paint(canvas, center - Offset(crown.width / 2, crown.height / 2));

    _token(canvas, path[(playerSteps * 52 ~/ 56) % 52], const Color(0xFF36A4FF));
    _token(canvas, path[(26 + botSteps * 52 ~/ 56) % 52], const Color(0xFFE95757));

    final label = TextPainter(text: const TextSpan(text: 'ZYNORA • TRAINING ARENA', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.4)), textDirection: TextDirection.ltr)..layout();
    label.paint(canvas, Offset(r / 2 - label.width / 2, r - label.height - 12));
  }

  void _token(Canvas canvas, Offset center, Color color) {
    final glow = Paint()..color = color.withValues(alpha: .20);
    canvas.drawCircle(center, 16, glow);
    final p = Paint()..color = color;
    canvas.drawCircle(center, 9, p);
    final hi = Paint()..color = Colors.white.withValues(alpha: .65);
    canvas.drawCircle(center - const Offset(3, 3), 3, hi);
  }

  @override
  bool shouldRepaint(covariant _LudoPainter oldDelegate) => oldDelegate.playerSteps != playerSteps || oldDelegate.botSteps != botSteps;
}
