import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_controller.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../core/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenGames, required this.onOpenRoom});
  final VoidCallback onOpenGames;
  final void Function(String gameId) onOpenRoom;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final strings = ZStrings.of(context);
    final user = app.user ?? {};
    final username = user['username']?.toString() ?? 'ZYNORA';
    final level = user['level'] ?? 1;
    final xp = user['xp'] ?? 0;
    final coins = user['coins'] ?? 0;
    final gems = user['gems'] ?? user['diamonds'] ?? 0;

    return GradientScaffold(
      child: RefreshIndicator(
        color: ZTheme.gold,
        onRefresh: app.loadDashboardData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _TopBar(username: username, level: level.toString()),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _HeroBanner(
                  username: username,
                  level: level.toString(),
                  xp: xp.toString(),
                  coins: coins.toString(),
                  gems: gems.toString(),
                  onPlay: app.games.isNotEmpty ? () => onOpenRoom(app.games.first['id'].toString()) : onOpenGames,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              sliver: SliverToBoxAdapter(child: _QuickStats(user: user)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionTitle(title: 'المهام اليومية', action: 'عرض الكل', onTap: onOpenGames),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              sliver: SliverToBoxAdapter(child: _DailyMissions(app: app)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionTitle(title: strings.chooseGame, action: strings.games, onTap: onOpenGames),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              sliver: SliverToBoxAdapter(child: _GamesRail(games: app.games, onPlay: onOpenRoom)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(child: _FeaturedPanels(app: app, onOpenGames: onOpenGames)),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.username, required this.level});
  final String username;
  final String level;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppController>();
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ZTheme.gold.withValues(alpha: .85), width: 2),
            gradient: const LinearGradient(colors: [Color(0xFF293653), Color(0xFF0C1322)]),
          ),
          child: Center(
            child: Text(username.substring(0, 1).toUpperCase(), style: const TextStyle(color: ZTheme.gold, fontWeight: FontWeight.w900, fontSize: 18)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(username, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              Text('المستوى $level • فارس زينورا', style: TextStyle(color: Colors.white.withValues(alpha: .58), fontSize: 12)),
            ],
          ),
        ),
        _RoundIcon(icon: Icons.notifications_none_rounded, badge: app.notifications.length),
        const SizedBox(width: 6),
        _RoundIcon(icon: Icons.settings_outlined, onTap: () {}),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, this.badge = 0, this.onTap});
  final IconData icon;
  final int badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white70),
          style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .06), shape: const CircleBorder()),
        ),
        if (badge > 0)
          Positioned(
            top: 5,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(color: ZTheme.gold, borderRadius: BorderRadius.circular(9)),
              child: Text('$badge', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF1A1205))),
            ),
          ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.username, required this.level, required this.xp, required this.coins, required this.gems, required this.onPlay});
  final String username;
  final String level;
  final String xp;
  final String coins;
  final String gems;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ZTheme.gold.withValues(alpha: .45)),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 28, offset: Offset(0, 16))],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/zynora_world.png', fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF050B14).withValues(alpha: .88), const Color(0xFF07101D).withValues(alpha: .28), const Color(0xFF05070B).withValues(alpha: .82)],
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Image.asset('assets/brand/zynora-logo.png', width: 38, height: 38),
                const SizedBox(width: 8),
                const Text('ZYNORA', style: TextStyle(color: ZTheme.gold, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const Spacer(),
                _Currency(icon: Icons.monetization_on_rounded, value: coins),
                const SizedBox(width: 6),
                _Currency(icon: Icons.diamond_rounded, value: gems),
              ],
            ),
          ),
          Positioned(
            right: 18,
            bottom: 22,
            left: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('عالم أسطوري ينتظرك', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                const Text('ابدأ رحلتك الآن!', style: TextStyle(color: ZTheme.gold, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lv. $level  •  XP $xp', style: TextStyle(color: Colors.white.withValues(alpha: .82), fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 5),
                          ClipRRect(borderRadius: BorderRadius.circular(10), child: const LinearProgressIndicator(value: .68, minHeight: 6, backgroundColor: Colors.white12, color: ZTheme.gold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(height: 48, child: PrimaryButton(label: 'ابدأ اللعب', icon: Icons.play_arrow_rounded, onPressed: onPlay)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Currency extends StatelessWidget {
  const _Currency({required this.icon, required this.value});
  final IconData icon;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: .48), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
      child: Row(children: [Icon(icon, size: 14, color: ZTheme.gold), const SizedBox(width: 4), Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))]),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.user});
  final Map<String, dynamic> user;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Stat(icon: Icons.emoji_events_rounded, value: '${user['wins'] ?? 0}', label: 'انتصارات')),
        const SizedBox(width: 8),
        Expanded(child: _Stat(icon: Icons.sports_esports_rounded, value: '${user['matches'] ?? 0}', label: 'مباريات')),
        const SizedBox(width: 8),
        Expanded(child: _Stat(icon: Icons.shield_rounded, value: '${user['level'] ?? 1}', label: 'المستوى')),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) {
    return ZCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      child: Column(children: [Icon(icon, color: ZTheme.gold, size: 20), const SizedBox(height: 6), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)), Text(label, style: TextStyle(color: Colors.white.withValues(alpha: .52), fontSize: 10))]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action, required this.onTap});
  final String title;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Row(children: [Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900))), TextButton(onPressed: onTap, child: Text(action, style: const TextStyle(color: ZTheme.gold, fontWeight: FontWeight.w700)))]);
  }
}

class _DailyMissions extends StatelessWidget {
  const _DailyMissions({required this.app});
  final AppController app;
  @override
  Widget build(BuildContext context) {
    final items = app.missions.take(3).toList();
    const fallback = [
      ('تسجيل الدخول اليومي', 'استلم المكافأة', Icons.login_rounded, '1/1'),
      ('اهزم 10 خصوم', 'مهمة قتالية', Icons.sports_martial_arts_rounded, '10/10'),
      ('أكمل 3 مباريات', 'اربح XP إضافية', Icons.emoji_events_rounded, '3/3'),
    ];
    return Column(
      children: List.generate(3, (i) {
        final mission = items.isNotEmpty && i < items.length ? items[i] : null;
        final title = mission?['title']?.toString() ?? fallback[i].$1;
        final subtitle = mission?['description']?.toString() ?? fallback[i].$2;
        final progress = mission?['progress']?.toString() ?? fallback[i].$4;
        final icon = fallback[i].$3;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ZCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: ZTheme.gold.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: ZTheme.gold, size: 20)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)), Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: .48), fontSize: 10))])), Text(progress, style: const TextStyle(color: ZTheme.gold, fontWeight: FontWeight.w900, fontSize: 12)), const SizedBox(width: 8), OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(side: BorderSide(color: ZTheme.gold.withValues(alpha: .5)), foregroundColor: ZTheme.gold, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: Size.zero), child: const Text('استلم', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800))) ]),
          ),
        );
      }),
    );
  }
}

class _GamesRail extends StatelessWidget {
  const _GamesRail({required this.games, required this.onPlay});
  final List<Map<String, dynamic>> games;
  final void Function(String) onPlay;
  @override
  Widget build(BuildContext context) {
    final data = games.isEmpty
        ? const [
            {'id': 'ludo', 'name': 'Ludo', 'description': 'تنافس مع أصدقائك', 'min_players': 2, 'max_players': 4},
            {'id': 'chess', 'name': 'Chess', 'description': 'مواجهة استراتيجية', 'min_players': 2, 'max_players': 2},
            {'id': 'domino', 'name': 'Domino', 'description': 'لعبة سريعة وممتعة', 'min_players': 2, 'max_players': 4},
          ]
        : games;
    return SizedBox(
      height: 175,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final game = data[index];
          return SizedBox(
            width: 215,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => onPlay(game['id'].toString()),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(colors: [Color(0xFF17243A), Color(0xFF0A101B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  border: Border.all(color: ZTheme.gold.withValues(alpha: .22)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 48, height: 48, decoration: BoxDecoration(color: ZTheme.gold.withValues(alpha: .13), borderRadius: BorderRadius.circular(15)), child: Icon(_gameIcon(game['id'].toString()), color: ZTheme.gold, size: 27)),
                    const Spacer(),
                    Text(game['name'].toString(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(game['description'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: .5), fontSize: 11)),
                    const SizedBox(height: 9),
                    Row(children: [const Icon(Icons.people_alt_outlined, size: 13, color: ZTheme.gold), const SizedBox(width: 4), Text('${game['min_players']}-${game['max_players']}', style: TextStyle(color: Colors.white.withValues(alpha: .65), fontSize: 10)), const Spacer(), const Icon(Icons.arrow_back_rounded, size: 16, color: ZTheme.gold)])
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _gameIcon(String id) => switch (id) { 'ludo' => Icons.casino_rounded, 'chess' => Icons.extension_rounded, _ => Icons.grid_view_rounded };
}

class _FeaturedPanels extends StatelessWidget {
  const _FeaturedPanels({required this.app, required this.onOpenGames});
  final AppController app;
  final VoidCallback onOpenGames;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _FeatureCard(icon: Icons.shield_rounded, title: 'التحالفات', text: 'كوّن فريقك وشارك في المنافسات', button: 'استكشف', onTap: onOpenGames)),
        const SizedBox(width: 10),
        Expanded(child: _FeatureCard(icon: Icons.local_fire_department_rounded, title: 'الأحداث', text: app.events.isEmpty ? 'فعاليات جديدة كل أسبوع' : '${app.events.length} أحداث متاحة الآن', button: 'المزيد', onTap: onOpenGames)),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.icon, required this.title, required this.text, required this.button, required this.onTap});
  final IconData icon;
  final String title;
  final String text;
  final String button;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return ZCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, color: ZTheme.gold.withValues(alpha: .12)), child: Icon(icon, color: ZTheme.gold)), const SizedBox(height: 10), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)), const SizedBox(height: 4), Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: .5), fontSize: 10, height: 1.4)), const SizedBox(height: 8), TextButton(onPressed: onTap, style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero), child: Text(button, style: const TextStyle(color: ZTheme.gold, fontSize: 11, fontWeight: FontWeight.w800)))]),
    );
  }
}
