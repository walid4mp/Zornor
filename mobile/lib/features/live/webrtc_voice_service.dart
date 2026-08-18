import 'package:socket_io_client/socket_io_client.dart' as io;

/// Socket-only voice-room signaling adapter.
///
/// Native WebRTC was intentionally removed from the mobile build because the
/// available flutter_webrtc releases in this project are not compatible with
/// the Android/Flutter toolchain used by CI. The room signaling remains intact
/// so a future native audio implementation can be plugged in without changing
/// LiveRoomScreen.
class WebRtcVoiceService {
  io.Socket? _socket;
  String? _roomId;

  Future<void> join({required io.Socket socket, required String voiceRoomId}) async {
    _socket = socket;
    _roomId = voiceRoomId;
    _socket!.emit('voice:join', <String, dynamic>{'voiceRoomId': voiceRoomId});
  }

  Future<void> leave(String voiceRoomId) async {
    _socket?.emit('voice:leave', <String, dynamic>{'voiceRoomId': voiceRoomId});
    _socket = null;
    _roomId = null;
  }

  bool get isJoined => _socket != null && _roomId != null;
}
