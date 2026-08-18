import 'dart:async';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_service.dart';
import 'config.dart';

enum StartupPhase { splash, checkingSession, unauthenticated, authenticated }

class AppController extends ChangeNotifier {
  AppController() {
    unawaited(_loadPrefs());
  }

  final ApiService api = ApiService();

  ThemeMode themeMode = ThemeMode.dark;
  Locale locale = const Locale('ar');
  bool onboardingDone = false;
  bool guestMode = false;
  bool loading = false;
  bool initializedAds = false;
  bool soundOn = true;
  bool musicOn = true;
  String error = '';

  StartupPhase startupPhase = StartupPhase.splash;
  String? lastNetworkError;

  Map<String, dynamic>? user;
  List<Map<String, dynamic>> games = [];
  List<Map<String, dynamic>> friends = [];
  List<Map<String, dynamic>> friendRequests = [];
  List<Map<String, dynamic>> shopItems = [];
  List<Map<String, dynamic>> missions = [];
  List<Map<String, dynamic>> achievements = [];
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> notifications = [];
  Map<String, dynamic> leaderboards = {};
  List<Map<String, dynamic>> rooms = [];
  List<Map<String, dynamic>> searchedUsers = [];
  List<Map<String, dynamic>> communityOffers = [];
  List<Map<String, dynamic>> tournaments = [];
  List<Map<String, dynamic>> gifts = [];
  List<Map<String, dynamic>> liveRooms = [];
  List<Map<String, dynamic>> voiceRooms = [];
  List<Map<String, dynamic>> economyLedger = [];
  Map<String, dynamic> economyStats = {};

  String searchStatus = '';
  Map<String, dynamic>? activeRoom;
  Map<String, dynamic>? roomState;
  List<Map<String, dynamic>> chatMessages = [];
  io.Socket? socket;

  BannerAd? bannerAd;

  bool get isGuest => guestMode;
  bool get isLoggedIn => guestMode || (api.token != null && user != null);

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      onboardingDone = prefs.getBool('onboarding_done') ?? false;
      guestMode = prefs.getBool('guest_mode') ?? false;
      api.token = prefs.getString('token');
      final localeCode = prefs.getString('locale') ?? 'ar';
      locale = localeCode == 'en' ? const Locale('en') : const Locale('ar');
      themeMode = (prefs.getString('theme') ?? 'dark') == 'light' ? ThemeMode.light : ThemeMode.dark;
      soundOn = prefs.getBool('soundOn') ?? true;
      musicOn = prefs.getBool('musicOn') ?? true;

      if (guestMode) {
        api.token = null;
        user = _demoUser();
        startupPhase = StartupPhase.authenticated;
      } else {
        startupPhase = api.token == null ? StartupPhase.unauthenticated : StartupPhase.checkingSession;
      }
      notifyListeners();

      if (api.token != null) {
        unawaited(_validateSessionAndContinue());
      }
    } catch (e, stack) {
      debugPrint('ZYNORA preferences initialization failed: $e');
      debugPrintStack(stackTrace: stack);
      api.token = null;
      startupPhase = StartupPhase.unauthenticated;
      lastNetworkError = 'تعذر تهيئة إعدادات التطبيق. يمكنك المتابعة وتسجيل الدخول من جديد.';
      notifyListeners();
    } finally {
      await _initializeAdsSafely();
      Future<void>.delayed(const Duration(seconds: 6), () {
        if (!mountedController || startupPhase != StartupPhase.checkingSession) return;
        lastNetworkError ??= 'تعذر الاتصال بالخادم. تحقق من الإنترنت ثم حاول مرة أخرى.';
        startupPhase = StartupPhase.unauthenticated;
        notifyListeners();
      });
    }
  }

  bool get mountedController => !_disposed;
  bool _disposed = false;

  Future<void> _initializeAdsSafely() async {
    if (initializedAds) return;
    initializedAds = true;
    try {
      await MobileAds.instance.initialize();
      loadBanner();
    } catch (e, stack) {
      debugPrint('AdMob initialization failed (continuing without ads): $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', onboardingDone);
    await prefs.setBool('guest_mode', guestMode);
    await prefs.setString('locale', locale.languageCode);
    await prefs.setString('theme', themeMode == ThemeMode.light ? 'light' : 'dark');
    await prefs.setBool('soundOn', soundOn);
    await prefs.setBool('musicOn', musicOn);
    if (api.token != null) {
      await prefs.setString('token', api.token!);
    } else {
      await prefs.remove('token');
    }
  }

  String friendlyNetworkError(Object e) {
    if (e is ApiException) return e.message;
    return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
  }

  Future<void> _validateSessionAndContinue() async {
    try {
      await refreshProfile(silent: true, rethrowError: true);
      await loadDashboardData(silent: true, rethrowError: true);
      lastNetworkError = null;
      startupPhase = isLoggedIn ? StartupPhase.authenticated : StartupPhase.unauthenticated;
    } catch (e) {
      if (e is ApiException && e.isUnauthorized) {
        lastNetworkError = 'انتهت صلاحية الجلسة. سجل الدخول مرة أخرى.';
        clearSessionPreservePrefs();
        startupPhase = StartupPhase.unauthenticated;
      } else {
        lastNetworkError = friendlyNetworkError(e);
        startupPhase = StartupPhase.unauthenticated;
      }
    }
    notifyListeners();
  }

  Map<String, dynamic> _demoUser() => {
        'id': 'guest-zynora',
        'username': 'ZYNORA',
        'role': 'guest',
        'coins': 125500,
        'gems': 8920,
        'xp': 6800,
        'level': 45,
        'wins': 12,
        'matches': 27,
      };

  void completeOnboarding() {
    onboardingDone = true;
    unawaited(_savePrefs());
    notifyListeners();
  }


  void enterGuestMode() {
    onboardingDone = true;
    guestMode = true;
    api.token = null;
    user = _demoUser();
    startupPhase = StartupPhase.authenticated;
    lastNetworkError = null;
    error = '';
    unawaited(_savePrefs());
    notifyListeners();
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    unawaited(_savePrefs());
    notifyListeners();
  }

  void toggleLocale() {
    locale = locale.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
    unawaited(_savePrefs());
    notifyListeners();
  }

  void toggleSound() {
    soundOn = !soundOn;
    unawaited(_savePrefs());
    notifyListeners();
  }

  void toggleMusic() {
    musicOn = !musicOn;
    unawaited(_savePrefs());
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    guestMode = false;
    loading = true;
    error = '';
    lastNetworkError = null;
    notifyListeners();
    try {
      final data = await api.postJson('/auth/login', {'email': email, 'password': password});
      api.token = data['token'] as String;
      user = Map<String, dynamic>.from(data['user'] as Map);
      startupPhase = StartupPhase.authenticated;
      await _savePrefs();
      await loadDashboardData(silent: true);
    } catch (e) {
      error = friendlyNetworkError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String username, String password) async {
    guestMode = false;
    loading = true;
    error = '';
    lastNetworkError = null;
    notifyListeners();
    try {
      final data = await api.postJson('/auth/register', {'email': email, 'username': username, 'password': password});
      api.token = data['token'] as String;
      user = Map<String, dynamic>.from(data['user'] as Map);
      startupPhase = StartupPhase.authenticated;
      await _savePrefs();
      await loadDashboardData(silent: true);
    } catch (e) {
      error = friendlyNetworkError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile({bool silent = false, bool rethrowError = false}) async {
    if (api.token == null) return;
    if (!silent) {
      loading = true;
      notifyListeners();
    }
    try {
      final data = await api.getJson('/auth/me');
      user = Map<String, dynamic>.from(data['user'] as Map);
      error = '';
    } catch (e) {
      if (e is ApiException && e.isUnauthorized) {
        lastNetworkError = 'انتهت صلاحية الجلسة. سجل الدخول مرة أخرى.';
        clearSessionPreservePrefs();
        startupPhase = StartupPhase.unauthenticated;
      } else {
        error = friendlyNetworkError(e);
        lastNetworkError ??= error;
      }
      if (rethrowError) rethrow;
    } finally {
      if (!silent) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> forgotPassword(String email) async {
    await api.postJson('/auth/forgot-password', {'email': email});
  }

  Future<void> resetPassword(String email, String password) async {
    await api.postJson('/auth/reset-password', {'email': email, 'newPassword': password});
  }

  Future<void> loadDashboardData({bool silent = false, bool rethrowError = false}) async {
    if (guestMode || api.token == null) return;
    if (!silent) {
      loading = true;
      notifyListeners();
    }
    try {
      final responses = await Future.wait([
        api.getJson('/games'),
        api.getJson('/games/leaderboards'),
        api.getJson('/friends'),
        api.getJson('/shop'),
        api.getJson('/missions'),
        api.getJson('/rooms'),
        api.getJson('/auth/me'),
      ]);
      games = List<Map<String, dynamic>>.from((responses[0]['games'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
      leaderboards = Map<String, dynamic>.from(responses[1]);
      friends = List<Map<String, dynamic>>.from((responses[2]['friends'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
      friendRequests = List<Map<String, dynamic>>.from((responses[2]['requests'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
      shopItems = List<Map<String, dynamic>>.from((responses[3]['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
      missions = List<Map<String, dynamic>>.from((responses[4]['missions'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
      achievements = List<Map<String, dynamic>>.from((responses[4]['achievements'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
      events = List<Map<String, dynamic>>.from((responses[4]['events'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
      notifications = List<Map<String, dynamic>>.from((responses[4]['notifications'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
      rooms = List<Map<String, dynamic>>.from((responses[5]['rooms'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
      user = Map<String, dynamic>.from(responses[6]['user'] as Map);
      error = '';
      lastNetworkError = null;
    } catch (e) {
      if (e is ApiException && e.isUnauthorized) {
        lastNetworkError = 'انتهت صلاحية الجلسة. سجل الدخول مرة أخرى.';
        clearSessionPreservePrefs();
        startupPhase = StartupPhase.unauthenticated;
      } else {
        error = friendlyNetworkError(e);
        lastNetworkError ??= error;
      }
      if (rethrowError) rethrow;
    } finally {
      if (!silent) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<Map<String, dynamic>> quickMatch(String gameId) async {
    if (guestMode) {
      return {'room': {'roomId': 'guest-$gameId', 'roomCode': 'DEMO', 'gameId': gameId, 'isPrivate': false, 'maxPlayers': 4}, 'searching': false};
    }
    searchStatus = 'searching';
    error = '';
    notifyListeners();
    try {
      final response = await api.postJson('/rooms/quick-match', {'gameId': gameId});
      final roomRaw = response['room'];
      if (roomRaw is! Map) {
        throw ApiException('تعذر إنشاء غرفة اللعب.');
      }
      activeRoom = Map<String, dynamic>.from(roomRaw);
      searchStatus = response['searching'] == true ? 'searching' : 'found';
      notifyListeners();
      final roomId = activeRoom?['roomId']?.toString();
      if (roomId == null || roomId.isEmpty) {
        throw ApiException('غرفة اللعب غير صالحة.');
      }
      await joinRealtime(roomId);
      return response;
    } catch (e) {
      searchStatus = '';
      error = friendlyNetworkError(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createRoom(String gameId, {bool isPrivate = false, int maxPlayers = 2}) async {
    final response = await api.postJson('/rooms', {'gameId': gameId, 'isPrivate': isPrivate, 'maxPlayers': maxPlayers});
    activeRoom = Map<String, dynamic>.from(response['room'] as Map);
    roomState = null;
    searchStatus = 'created';
    notifyListeners();
    await joinRealtime(activeRoom!['roomId'] as String);
  }

  Future<void> joinRoom(String roomId) async {
    final response = await api.postJson('/rooms/$roomId/join', {});
    activeRoom = Map<String, dynamic>.from(response['room'] as Map);
    roomState = Map<String, dynamic>.from(response['state'] as Map);
    searchStatus = 'found';
    notifyListeners();
    await joinRealtime(roomId);
  }

  Future<void> joinRealtime(String roomId) async {
    socket?.dispose();
    final configured = AppConfig.socketBaseUrl();
    final wsBase = configured.startsWith('https://')
        ? configured.replaceFirst('https://', 'wss://')
        : configured.replaceFirst('http://', 'ws://');
    socket = io.io(
      wsBase,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': api.token})
          .setTimeout(AppConfig.socketConnectTimeout.inMilliseconds)
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );
    socket!.connect();
    socket!.onConnect((_) {
      socket!.emit('room:subscribe', {'roomId': roomId});
    });
    socket!.onConnectError((data) {
      error = 'تعذر الاتصال بغرفة اللعب.';
      notifyListeners();
    });
    socket!.onDisconnect((_) {
      if (activeRoom?.isNotEmpty == true) {
        error = 'انقطع اتصال اللعبة. سيتم إعادة الاتصال تلقائيًا.';
        notifyListeners();
      }
    });
    socket!.on('room:state', (data) {
      roomState = Map<String, dynamic>.from(data as Map);
      if ((roomState?['winnerUserId'] ?? '').toString().isNotEmpty && user != null) {
        searchStatus = roomState?['winnerUserId'] == user!['id'] ? 'winner' : 'loser';
      }
      notifyListeners();
    });
    socket!.on('chat:message', (data) {
      if (soundOn) SystemSound.play(SystemSoundType.click);
      chatMessages.add(Map<String, dynamic>.from(data as Map));
      notifyListeners();
    });
    socket!.on('game:error', (data) {
      error = (data as Map)['message']?.toString() ?? 'Game error';
      notifyListeners();
    });
  }

  void leaveRoom() {
    socket?.dispose();
    socket = null;
    activeRoom = null;
    roomState = null;
    chatMessages.clear();
    searchStatus = '';
    error = '';
    notifyListeners();
  }

  void sendChat(String text) {
    if (activeRoom == null || text.trim().isEmpty) return;
    socket?.emit('chat:send', {'roomId': activeRoom!['roomId'], 'message': text.trim()});
  }

  void sendGameAction(Map<String, dynamic> action) {
    if (activeRoom == null) return;
    if (soundOn) SystemSound.play(SystemSoundType.click);
    socket?.emit('game:action', {'roomId': activeRoom!['roomId'], 'action': action});
  }

  Future<void> searchUsers(String queryText) async {
    if (queryText.trim().isEmpty) {
      searchedUsers = [];
      notifyListeners();
      return;
    }
    final response = await api.getJson('/users/search?q=${Uri.encodeQueryComponent(queryText.trim())}');
    searchedUsers = List<Map<String, dynamic>>.from((response['users'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
    notifyListeners();
  }

  Future<void> loadCommunity() async {
    if (guestMode || api.token == null) return;
    try {
      final r = await Future.wait([api.getJson('/community/events'),api.getJson('/community/gifts'),api.getJson('/community/live'),api.getJson('/community/voice-rooms'),api.getJson('/community/economy')]);
      tournaments = List<Map<String,dynamic>>.from((r[0]['tournaments'] as List).map((e)=>Map<String,dynamic>.from(e as Map)));
      communityOffers = List<Map<String,dynamic>>.from((r[0]['offers'] as List).map((e)=>Map<String,dynamic>.from(e as Map)));
      gifts = List<Map<String,dynamic>>.from((r[1]['gifts'] as List).map((e)=>Map<String,dynamic>.from(e as Map)));
      liveRooms = List<Map<String,dynamic>>.from((r[2]['rooms'] as List).map((e)=>Map<String,dynamic>.from(e as Map)));
      voiceRooms = List<Map<String,dynamic>>.from((r[3]['rooms'] as List).map((e)=>Map<String,dynamic>.from(e as Map)));
      economyLedger = List<Map<String,dynamic>>.from((r[4]['ledger'] as List).map((e)=>Map<String,dynamic>.from(e as Map)));
      economyStats = Map<String,dynamic>.from(r[4]['stats'] as Map);
      user = {...?user,'coins':r[4]['coins']};
      notifyListeners();
    } catch (e) { error=friendlyNetworkError(e); notifyListeners(); }
  }

  Future<void> joinTournament(String id) async { await api.postJson('/community/tournaments/$id/join', {}); await loadCommunity(); await refreshProfile(silent:true); }
  Future<void> sendLiveGift(String roomId,String giftId) async { await api.postJson('/community/live/$roomId/gift', {'giftId':giftId,'quantity':1}); await loadCommunity(); await refreshProfile(silent:true); }
  Future<void> createVoiceRoom(String name) async { await api.postJson('/community/voice-rooms', {'name':name,'maxSpeakers':8}); await loadCommunity(); }
  Future<void> joinVoiceRoom(String id) async { await api.postJson('/community/voice-rooms/$id/join', {}); }

  Future<void> reloadRooms() async {
    final response = await api.getJson('/rooms');
    rooms = List<Map<String, dynamic>>.from((response['rooms'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
    notifyListeners();
  }

  Future<void> sendFriendRequest(String userId) async {
    await api.postJson('/friends/request', {'receiverUserId': userId});
    await loadDashboardData();
  }

  Future<void> acceptFriendRequest(String requestId) async {
    await api.postJson('/friends/request/$requestId/accept', {});
    await loadDashboardData();
  }

  Future<void> purchase(String itemId) async {
    await api.postJson('/shop/purchase', {'itemId': itemId});
    await loadDashboardData();
  }

  @override
  void dispose() {
    _disposed = true;
    bannerAd?.dispose();
    socket?.dispose();
    super.dispose();
  }

  void loadBanner() {
    bannerAd?.dispose();
    bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      listener: BannerAdListener(
        onAdLoaded: (_) => notifyListeners(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
      request: const AdRequest(),
    )..load();
  }

  List<List<String>> chessBoardFromFen() {
    final fen = roomState?['fen']?.toString() ?? chess.Chess.DEFAULT_POSITION;
    final boardFen = fen.split(' ').first;
    return boardFen.split('/').map((rank) {
      final cells = <String>[];
      for (final char in rank.split('')) {
        final empty = int.tryParse(char);
        if (empty != null) {
          cells.addAll(List.filled(empty, ''));
        } else {
          cells.add(char);
        }
      }
      return cells;
    }).toList();
  }

  Future<void> retryConnection() async {
    lastNetworkError = null;
    error = '';
    startupPhase = StartupPhase.checkingSession;
    notifyListeners();
    if (api.token != null) {
      await _validateSessionAndContinue();
      return;
    }
    startupPhase = StartupPhase.unauthenticated;
    notifyListeners();
  }

  void logout() {
    guestMode = false;
    clearSessionPreservePrefs();
    startupPhase = StartupPhase.unauthenticated;
    notifyListeners();
  }

  void clearSessionPreservePrefs() {
    guestMode = false;
    api.token = null;
    user = null;
    socket?.dispose();
    socket = null;
    activeRoom = null;
    roomState = null;
    chatMessages.clear();
    unawaited(_savePrefs());
  }
}
