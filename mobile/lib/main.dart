import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app_controller.dart';
import 'core/theme.dart';
import 'core/translations.dart';
import 'core/widgets.dart';
import 'features/auth/auth_screen.dart';
import 'features/community/community_screen.dart';
import 'features/friends/friends_screen.dart';
import 'features/games/games_hub_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shop/shop_screen.dart';
import 'features/splash/splash_screen.dart';
import 'games/common/game_room_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('ZYNORA FlutterError: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('ZYNORA unhandled error: $error');
    debugPrintStack(stackTrace: stack);
    return true;
  };

  runApp(const ZynoraRoot());
}

class ZynoraRoot extends StatelessWidget {
  const ZynoraRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppController(),
      child: Consumer<AppController>(
        builder: (context, app, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'ZYNORA',
            theme: ZTheme.light(),
            darkTheme: ZTheme.dark(),
            themeMode: app.themeMode,
            locale: app.locale,
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              final lang = Localizations.localeOf(context).languageCode;
              return Directionality(
                textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const AppBootstrapper(),
          );
        },
      ),
    );
  }
}

class AppBootstrapper extends StatefulWidget {
  const AppBootstrapper({super.key});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  bool showSplash = true;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    if (showSplash) {
      return SplashScreen(onFinished: () {
        if (mounted) setState(() => showSplash = false);
      });
    }
    if (!app.onboardingDone) return const OnboardingScreen();
    if (app.startupPhase == StartupPhase.checkingSession) {
      return const _BootLoadingScreen();
    }
    if (!app.isLoggedIn) {
      if (app.api.token != null && app.lastNetworkError != null) {
        return _ConnectionRecoveryScreen(message: app.lastNetworkError!, onRetry: app.retryConnection);
      }
      return const AuthScreen();
    }
    return const MainShell();
  }
}

class _BootLoadingScreen extends StatelessWidget {
  const _BootLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final strings = ZStrings.of(context);
    return Scaffold(
      body: GradientScaffold(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(strings.loading, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionRecoveryScreen extends StatelessWidget {
  const _ConnectionRecoveryScreen({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientScaffold(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: ZCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 56),
                    const SizedBox(height: 16),
                    const Text('ZYNORA', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'Try Again',
                      icon: Icons.refresh_rounded,
                      onPressed: () {
                        onRetry();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  String? activeGameId;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        onOpenGames: () => setState(() => index = 1),
        onOpenRoom: _openQuickMatch,
      ),
      GamesHubScreen(onPlay: _openQuickMatch),
      const FriendsScreen(),
      const ShopScreen(),
      const ProfileScreen(),
      const CommunityScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(child: IndexedStack(index: index, children: pages)),
          if (activeGameId != null)
            Positioned.fill(
              child: Material(
                color: Colors.black.withValues(alpha: 0.55),
                child: SafeArea(
                  child: Column(
                    children: [
                      Align(
                        alignment: AlignmentDirectional.topEnd,
                        child: IconButton(
                          onPressed: () => setState(() => activeGameId = null),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                        ),
                      ),
                      Expanded(child: GameRoomScreen(gameId: activeGameId!)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      drawer: const Drawer(child: SafeArea(child: SettingsScreen())),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.sports_esports_rounded), label: 'الألعاب'),
          NavigationDestination(icon: Icon(Icons.people_alt_rounded), label: 'الأصدقاء'),
          NavigationDestination(icon: Icon(Icons.storefront_rounded), label: 'المتجر'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'حسابي'),
          NavigationDestination(icon: Icon(Icons.live_tv_rounded), label: 'LIVE'),
        ],
      ),
    );
  }

  Future<void> _openQuickMatch(String gameId) async {
    final app = context.read<AppController>();
    if (app.isGuest) {
      setState(() => activeGameId = gameId);
      return;
    }
    try {
      await app.quickMatch(gameId);
      if (mounted) setState(() => activeGameId = gameId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(app.error.isEmpty ? 'تعذر إنشاء غرفة اللعب.' : app.error)));
      }
    }
  }
}
