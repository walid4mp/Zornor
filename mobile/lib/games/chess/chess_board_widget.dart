import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../../core/widgets.dart';

class ChessBoardWidget extends StatefulWidget {
  const ChessBoardWidget({super.key, required this.controller});
  final AppController controller;

  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget> {
  String? selected;

  static const pieces = {
    'r': '♜', 'n': '♞', 'b': '♝', 'q': '♛', 'k': '♚', 'p': '♟',
    'R': '♖', 'N': '♘', 'B': '♗', 'Q': '♕', 'K': '♔', 'P': '♙',
  };

  @override
  Widget build(BuildContext context) {
    final board = widget.controller.chessBoardFromFen();
    final turn = widget.controller.roomState?['turn']?.toString() ?? 'w';
    final status = widget.controller.roomState?['status']?.toString() ?? 'waiting';
    return ZCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chess • turn ${turn == 'w' ? 'White' : 'Black'} • $status', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 64,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
              itemBuilder: (context, index) {
                final row = index ~/ 8;
                final col = index % 8;
                final square = '${'abcdefgh'[col]}${8 - row}';
                final piece = board[row][col];
                final isDark = (row + col).isOdd;
                final active = selected == square;
                return GestureDetector(
                  onTap: () {
                    if (selected == null && piece.isNotEmpty) {
                      setState(() => selected = square);
                    } else if (selected != null) {
                      widget.controller.sendGameAction({'type': 'move', 'from': selected, 'to': square, 'promotion': 'q'});
                      setState(() => selected = null);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.amberAccent
                          : (isDark ? const Color(0xFF7A9E7E) : const Color(0xFFF1E8D3)),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(square, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                          ),
                        ),
                        Center(
                          child: Text(
                            pieces[piece] ?? '',
                            style: const TextStyle(fontSize: 34),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => widget.controller.sendGameAction({'type': 'resign'}),
                icon: const Icon(Icons.flag_rounded),
                label: const Text('Resign'),
              ),
              OutlinedButton.icon(
                onPressed: () => widget.controller.sendGameAction({'type': 'move', 'from': 'e2', 'to': 'e4', 'promotion': 'q'}),
                icon: const Icon(Icons.history_edu_rounded),
                label: const Text('Sample Move e2-e4'),
              )
            ],
          )
        ],
      ),
    );
  }
}
