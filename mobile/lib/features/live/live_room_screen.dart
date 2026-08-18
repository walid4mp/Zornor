import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/config.dart';
import '../gifts/gift_catalog.dart';
import 'webrtc_voice_service.dart';

class LiveRoomScreen extends StatefulWidget {
  const LiveRoomScreen({super.key, required this.roomId, required this.title});

  final String roomId;
  final String title;

  @override
  State<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends State<LiveRoomScreen> {
  late final io.Socket socket;
  final WebRtcVoiceService voice = WebRtcVoiceService();
  final TextEditingController messageController = TextEditingController();

  bool mic = false;
  bool connected = false;
  bool voiceConnecting = false;
  int viewers = 1280;
  String? activeGift;
  Timer? giftTimer;

  final List<String> messages = <String>[
    'أهلاً بالجميع 👋',
    'بث جميل 🔥',
    'أرسلوا الهدايا 🎁',
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_connect());
  }

  Future<void> _connect() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    socket = io.io(
      AppConfig.socketBaseUrl(),
      io.OptionBuilder()
          .setTransports(<String>['websocket'])
          .setAuth(<String, dynamic>{if (token != null) 'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .setTimeout(AppConfig.socketConnectTimeout.inMilliseconds)
          .build(),
    );

    socket.onConnect((_) {
      if (!mounted) return;
      setState(() => connected = true);
      socket.emit('live:join', <String, dynamic>{'roomId': widget.roomId});
    });

    socket.onConnectError((dynamic data) {
      if (!mounted) return;
      setState(() => connected = false);
    });

    socket.onDisconnect((_) {
      if (!mounted) return;
      setState(() => connected = false);
    });

    socket.on('live:viewers', (dynamic data) {
      if (!mounted) return;
      final int? count = data is int
          ? data
          : data is Map && data['count'] is num
              ? (data['count'] as num).toInt()
              : null;
      if (count != null) setState(() => viewers = count);
    });

    socket.on('chat:message', _onChatMessage);
    socket.on('live:message', _onChatMessage);

    socket.on('live:gift', (dynamic data) {
      if (!mounted) return;
      final String gift = data is Map && data['gift'] != null
          ? data['gift'].toString()
          : '🎁';
      _showGift(gift);
    });

    socket.connect();
  }

  void _onChatMessage(dynamic data) {
    if (!mounted) return;
    String message = 'رسالة جديدة';
    if (data is Map && data['message'] != null) {
      final String sender = data['senderUsername']?.toString() ?? '';
      message = sender.isEmpty
          ? data['message'].toString()
          : '$sender: ${data['message']}';
    } else if (data != null) {
      message = data.toString();
    }
    setState(() {
      messages.add(message);
      if (messages.length > 30) messages.removeAt(0);
    });
  }

  @override
  void dispose() {
    giftTimer?.cancel();
    messageController.dispose();
    if (connected) {
      socket.emit('live:leave', <String, dynamic>{'roomId': widget.roomId});
    }
    unawaited(voice.leave(widget.roomId));
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff09070f),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xff35104f), Color(0xff100b1d), Color(0xff07060b)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _buildHeader(),
              Expanded(
                child: Stack(
                  children: <Widget>[
                    _buildStage(),
                    _buildMessages(),
                    if (activeGift != null) _buildGiftAnimation(activeGift!),
                  ],
                ),
              ),
              _buildComposer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: <Color>[Color(0xffff4f9a), Color(0xff7c3aed)]),
            ),
            child: const CircleAvatar(
              radius: 23,
              backgroundColor: Color(0xff191323),
              child: Icon(Icons.person_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Row(
                  children: <Widget>[
                    Icon(Icons.circle, size: 8, color: connected ? Colors.greenAccent : Colors.orangeAccent),
                    const SizedBox(width: 5),
                    Text(
                      connected ? 'متصل' : 'جاري الاتصال...',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.visibility_outlined, size: 15, color: Colors.white60),
                    const SizedBox(width: 4),
                    Text(_formatViewers(viewers), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(15)),
            child: const Text('● LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: const Color(0xffa855f7).withValues(alpha: 0.28), blurRadius: 50, spreadRadius: 15),
                  ],
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xffff4f9a), Color(0xff7c3aed), Color(0xff2563eb)],
                  ),
                ),
              ),
              Container(
                width: 164,
                height: 164,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff120d1d).withValues(alpha: 0.88),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: const Icon(Icons.person_rounded, size: 88, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('مرحباً بكم في ZYNORA LIVE', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 7),
          const Text('تحدث، استمتع، وأرسل هدايا متحركة ✨', style: TextStyle(color: Colors.white60, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: SizedBox(
        height: 155,
        child: ListView.builder(
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (BuildContext context, int index) {
            final String message = messages[messages.length - 1 - index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.42), borderRadius: BorderRadius.circular(16)),
                  child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.only(left: 14),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(25)),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      onSubmitted: (_) => _sendMessage(),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالة...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send_rounded, color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 7),
          _roundButton(
            icon: mic ? Icons.mic_rounded : Icons.mic_off_rounded,
            highlighted: mic,
            onPressed: _toggleMic,
          ),
          const SizedBox(width: 7),
          _roundButton(icon: Icons.card_giftcard_rounded, highlighted: true, onPressed: _sendGift),
        ],
      ),
    );
  }

  Widget _roundButton({required IconData icon, required VoidCallback onPressed, bool highlighted = false}) {
    return Material(
      color: highlighted ? const Color(0xffec4899) : Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 48, height: 48, child: Icon(icon, color: Colors.white, size: 21)),
      ),
    );
  }

  void _sendMessage() {
    final String text = messageController.text.trim();
    if (text.isEmpty) return;
    if (connected) {
      socket.emit('live:message', <String, dynamic>{'roomId': widget.roomId, 'message': text});
    } else {
      setState(() => messages.add('أنت: $text'));
    }
    messageController.clear();
  }

  Future<void> _toggleMic() async {
    if (voiceConnecting) return;
    if (mic) {
      await voice.leave(widget.roomId);
      if (mounted) setState(() => mic = false);
      return;
    }
    if (!connected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('انتظر حتى يتصل البث بالخادم.')));
      }
      return;
    }
    setState(() => voiceConnecting = true);
    try {
      await voice.join(socket: socket, voiceRoomId: widget.roomId);
      if (mounted) setState(() => mic = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تشغيل الميكروفون. تحقق من إذن الصوت.')));
      }
    } finally {
      if (mounted) setState(() => voiceConnecting = false);
    }
  }

  void _sendGift() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xff171021),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('🎁 هدايا ZYNORA', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text('اختر هدية لإظهار تأثيرها في البث', style: TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 15),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: zynoraGifts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.82),
                  itemBuilder: (BuildContext context, int index) {
                    final ZynoraGift gift = zynoraGifts[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        socket.emit('live:gift', <String, dynamic>{'roomId': widget.roomId, 'gift': gift.id, 'price': gift.price, 'currency': gift.currency, 'animation': gift.animation});
                        _showGift(gift.icon);
                        Navigator.of(sheetContext).pop();
                      },
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                          Text(gift.icon, style: const TextStyle(fontSize: 31)),
                          const SizedBox(height: 4),
                          Text(gift.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 10)),
                          const SizedBox(height: 4),
                          Text('${gift.price} ${gift.currency == 'gems' ? '💎' : '🪙'}', style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGift(String gift) {
    giftTimer?.cancel();
    setState(() => activeGift = gift);
    giftTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => activeGift = null);
    });
  }

  Widget _buildGiftAnimation(String gift) {
    return Center(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.45, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.elasticOut,
          builder: (BuildContext context, double scale, Widget? child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.black.withValues(alpha: 0.70),
                  border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.7), width: 1.5),
                  boxShadow: <BoxShadow>[BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.35), blurRadius: 35, spreadRadius: 5)],
                ),
                child: Text(gift, style: const TextStyle(fontSize: 76)),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatViewers(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}
