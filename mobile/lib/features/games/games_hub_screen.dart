import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_controller.dart';
import '../../core/translations.dart';
import '../../core/widgets.dart';

class GamesHubScreen extends StatelessWidget {
  const GamesHubScreen({super.key, required this.onPlay});
  final void Function(String gameId) onPlay;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final strings = ZStrings.of(context);
    final data = app.games.isNotEmpty ? app.games : const [
      {'id': 'ludo', 'name': 'Ludo Arena', 'description': 'مواجهة اجتماعية سريعة وممتعة', 'min_players': 2, 'max_players': 4, 'display_order': 1},
      {'id': 'chess', 'name': 'Chess', 'description': 'مباراة استراتيجية بقواعد الشطرنج الحقيقية', 'min_players': 2, 'max_players': 2, 'display_order': 2},
      {'id': 'domino', 'name': 'Domino', 'description': 'دومينو تنافسي مع توزيع حقيقي للبلاطات', 'min_players': 2, 'max_players': 4, 'display_order': 3},
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionHeader(title: strings.games),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('All Games')),
            Chip(label: Text('Popular')),
            Chip(label: Text('New')),
            Chip(label: Text('Competitive')),
            Chip(label: Text('Friends')),
            Chip(label: Text('Favorites')),
          ],
        ),
        const SizedBox(height: 16),
        ...data.map((game) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ZCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(colors: [Color(0xFF6A5CFF), Color(0xFF21D4FD), Color(0xFFFFB457)]),
                      ),
                      child: Center(
                        child: Text(game['name'].toString(), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(game['name'].toString(), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(game['description'].toString()),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: Text('Players: ${game['min_players']}-${game['max_players']}')),
                        Expanded(child: Text('${strings.onlinePlayers}: ${(game['display_order'] ?? 1) * 128}')),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        PrimaryButton(label: strings.quickMatch, onPressed: () => onPlay(game['id'].toString()), icon: Icons.flash_on_rounded),
                        OutlinedButton.icon(
                          onPressed: () => onPlay(game['id'].toString()),
                          icon: const Icon(Icons.meeting_room_rounded),
                          label: Text(strings.createRoom),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
