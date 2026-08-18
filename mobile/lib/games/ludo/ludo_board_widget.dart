import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../../core/widgets.dart';

class LudoBoardWidget extends StatelessWidget {
  const LudoBoardWidget({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final players = List<Map<String, dynamic>>.from(((controller.roomState?['players'] ?? []) as List).map((e) => Map<String, dynamic>.from(e as Map)));
    final dice = controller.roomState?['currentDice'];
    return ZCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ludo Arena', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withValues(alpha: 0.04),
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 225,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 15),
                itemBuilder: (context, index) {
                  final row = index ~/ 15;
                  final col = index % 15;
                  Color color = Colors.transparent;
                  if (row < 6 && col < 6) color = Colors.red.withValues(alpha: 0.25);
                  if (row < 6 && col > 8) color = Colors.green.withValues(alpha: 0.25);
                  if (row > 8 && col < 6) color = Colors.blue.withValues(alpha: 0.25);
                  if (row > 8 && col > 8) color = Colors.yellow.withValues(alpha: 0.25);
                  if (row == 7 || col == 7) color = Colors.white.withValues(alpha: 0.12);
                  return Container(
                    margin: const EdgeInsets.all(0.5),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: (row == 7 && col == 7)
                        ? const Center(child: Icon(Icons.star_rounded, color: Colors.amber, size: 20))
                        : null,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: players.map((player) {
              final pieces = List<Map<String, dynamic>>.from((player['pieces'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
              return SizedBox(
                width: 220,
                child: ZCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${player['username']} • ${player['color']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text('Finished: ${player['finishedPieces']}'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: pieces.map((piece) => ActionChip(
                              label: Text('${piece['id']} (${piece['steps']})'),
                              onPressed: () => controller.sendGameAction({'type': 'movePiece', 'pieceId': piece['id']}),
                            )).toList(),
                      )
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              FilledButton.icon(
                onPressed: () => controller.sendGameAction({'type': 'rollDice'}),
                icon: const Icon(Icons.casino_rounded),
                label: Text('Roll ${dice ?? ''}'),
              ),
              const SizedBox(width: 10),
            ],
          )
        ],
      ),
    );
  }
}
