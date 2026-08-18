import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../../core/widgets.dart';

class DominoBoardWidget extends StatelessWidget {
  const DominoBoardWidget({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final board = List<Map<String, dynamic>>.from(((controller.roomState?['board'] ?? []) as List).map((e) => Map<String, dynamic>.from(e as Map)));
    final hand = List<Map<String, dynamic>>.from(((controller.roomState?['myHand'] ?? []) as List).map((e) => Map<String, dynamic>.from(e as Map)));
    final players = List<Map<String, dynamic>>.from(((controller.roomState?['players'] ?? []) as List).map((e) => Map<String, dynamic>.from(e as Map)));
    return ZCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Domino Table', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: board.isEmpty
                  ? [const Text('Board is empty')]
                  : board.map((tile) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _TileVisual(left: tile['left'] as int, right: tile['right'] as int),
                      )).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Text('My Hand', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: hand.map((tile) {
              return InkWell(
                onTap: () => controller.sendGameAction({'type': 'playTile', 'tileId': tile['id'], 'side': 'right'}),
                child: _TileVisual(left: tile['left'] as int, right: tile['right'] as int),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => controller.sendGameAction({'type': 'draw'}),
                icon: const Icon(Icons.add_box_rounded),
                label: const Text('Draw Tile'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...players.map((player) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('${player['username']} • hand ${player['handCount']} • score ${player['score']}'),
              ))
        ],
      ),
    );
  }
}

class _TileVisual extends StatelessWidget {
  const _TileVisual({required this.left, required this.right});
  final int left;
  final int right;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Expanded(child: Center(child: Text('$left', style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w800)))),
          const Divider(height: 1, thickness: 1),
          Expanded(child: Center(child: Text('$right', style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w800)))),
        ],
      ),
    );
  }
}
