import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_controller.dart';
import '../../core/translations.dart';
import '../../core/widgets.dart';
import '../wallet/wallet_screen.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final strings = ZStrings.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionHeader(title: strings.shop),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletScreen())), icon: const Icon(Icons.account_balance_wallet_rounded), label: const Text('المحفظة والشحن')),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('Avatars')),
            Chip(label: Text('Frames')),
            Chip(label: Text('Emotes')),
            Chip(label: Text('Themes')),
            Chip(label: Text('Dice Skins')),
            Chip(label: Text('Cosmetics')),
          ],
        ),
        const SizedBox(height: 16),
        ...app.shopItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ZCard(
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(colors: [Color(0xFF6A5CFF), Color(0xFFFFB457)]),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(item['description'].toString()),
                          const SizedBox(height: 6),
                          Text('${strings.coins}: ${item['price']}'),
                        ],
                      ),
                    ),
                    FilledButton(onPressed: () => app.purchase(item['id'].toString()), child: const Text('Buy')),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
