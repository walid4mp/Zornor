import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_controller.dart';
import '../../core/translations.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../chess/chess_board_widget.dart';
import '../domino/domino_board_widget.dart';
import '../ludo/ludo_board_widget.dart';
import '../ludo/guest_ludo_screen.dart';

class GameRoomScreen extends StatefulWidget {
  const GameRoomScreen({super.key, required this.gameId});
  final String gameId;

  @override
  State<GameRoomScreen> createState() => _GameRoomScreenState();
}

class _GameRoomScreenState extends State<GameRoomScreen> {
  final chatController = TextEditingController();
  late final ConfettiController confetti = ConfettiController(duration: const Duration(seconds: 2));

  @override
  void dispose() {
    chatController.dispose();
    confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final strings = ZStrings.of(context);
    if (app.isGuest) {
      if (widget.gameId == 'ludo') return const GuestLudoScreen();
      return _GuestGamePreview(gameId: widget.gameId);
    }

    final room = app.activeRoom;
    final state = app.roomState;

    if (app.searchStatus == 'winner') {
      confetti.play();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.gameId.toUpperCase()} Room'),
        actions: [
          IconButton(onPressed: app.reloadRooms, icon: const Icon(Icons.refresh_rounded)),
          IconButton(
            tooltip: 'مغادرة',
            onPressed: () {
              app.leaveRoom();
              Navigator.of(context).maybePop();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          GradientScaffold(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ZCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(room == null ? widget.gameId.toUpperCase() : 'Room ${room['roomCode'] ?? ''}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                          ),
                          if (app.searchStatus == 'searching') const Chip(label: Text('Searching...')),
                          if (app.searchStatus == 'found') const Chip(label: Text('Opponent Found!')),
                          if (app.searchStatus == 'winner') const Chip(label: Text('Winner')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('${strings.publicRooms}: ${room?['isPrivate'] == true ? strings.privateRoom : strings.publicRooms}'),
                      const SizedBox(height: 8),
                      Text('Status: ${state?['status'] ?? app.searchStatus}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildBoard(context, app),
                const SizedBox(height: 16),
                ZCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chat', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          itemCount: app.chatMessages.length,
                          itemBuilder: (context, index) {
                            final message = app.chatMessages[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Align(
                                alignment: message['senderUserId'] == app.user?['id'] ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                                  ),
                                  child: Text('${message['senderUsername']}: ${message['message']}'),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: chatController,
                              decoration: InputDecoration(hintText: strings.send),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed: () {
                              app.sendChat(chatController.text);
                              chatController.clear();
                            },
                            icon: const Icon(Icons.send_rounded),
                            label: Text(strings.send),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.06,
              numberOfParticles: 18,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBoard(BuildContext context, AppController app) {
    switch (widget.gameId) {
      case 'chess':
        return ChessBoardWidget(controller: app);
      case 'domino':
        return DominoBoardWidget(controller: app);
      default:
        return LudoBoardWidget(controller: app);
    }
  }
}


class _GuestGamePreview extends StatelessWidget {
  const _GuestGamePreview({required this.gameId});
  final String gameId;

  @override
  Widget build(BuildContext context) {
    final name = gameId == 'chess' ? 'CHESS' : 'DOMINO';
    final icon = gameId == 'chess' ? Icons.extension_rounded : Icons.grid_view_rounded;
    return Scaffold(
      backgroundColor: const Color(0xFF05080E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ZCard(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, color: ZTheme.gold, size: 72),
                const SizedBox(height: 16),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('اللعب الجماعي متاح بعد تسجيل الدخول وربطك بخادم ZYNORA.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, height: 1.5)),
                const SizedBox(height: 20),
                PrimaryButton(label: 'العودة إلى الألعاب', icon: Icons.arrow_back_rounded, onPressed: () => Navigator.of(context).maybePop()),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
