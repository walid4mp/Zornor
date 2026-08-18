import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_controller.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../core/widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final strings = ZStrings.of(context);
    final items = [
      (title: strings.playWithFriends, icon: Icons.groups_rounded),
      (title: strings.enjoyMultipleGames, icon: Icons.sports_esports_rounded),
      (title: strings.competeAndWin, icon: Icons.emoji_events_rounded),
    ];

    return Scaffold(
      body: GradientScaffold(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    Image.asset('assets/brand/zynora-logo.png', width: 34, height: 34),
                    const SizedBox(width: 8),
                    Expanded(child: Text(strings.appName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900))),
                    TextButton(
                      onPressed: () => context.read<AppController>().enterGuestMode(),
                      child: const Text('تخطي', style: TextStyle(color: ZTheme.gold, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: PageView.builder(
                    controller: controller,
                    itemCount: items.length,
                    onPageChanged: (value) => setState(() => index = value),
                    itemBuilder: (context, itemIndex) {
                      final item = items[itemIndex];
                      return Center(
                        child: ZCard(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 112,
                                height: 112,
                                decoration: const BoxDecoration(
                                  gradient: ZTheme.heroGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(item.icon, color: Colors.white, size: 56),
                              ),
                              const SizedBox(height: 18),
                              Text(item.title,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 10),
                              Text(strings.premiumGaming,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    items.length,
                    (dot) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: dot == index ? 30 : 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: dot == index ? ZTheme.primary : Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.read<AppController>().enterGuestMode(),
                  icon: const Icon(Icons.explore_rounded),
                  label: const Text('تجربة ZYNORA كضيف'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white24), minimumSize: const Size.fromHeight(48)),
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: index == items.length - 1 ? strings.startNow : strings.playNow,
                  onPressed: () {
                    if (index == items.length - 1) {
                      context.read<AppController>().completeOnboarding();
                    } else {
                      controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
                    }
                  },
                  icon: Icons.arrow_forward_rounded,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
