import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_controller.dart';
import '../../core/translations.dart';
import '../../core/widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final strings = ZStrings.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionHeader(title: strings.settings),
        const SizedBox(height: 12),
        ZCard(
          child: Column(
            children: [
              SwitchListTile(value: app.themeMode == ThemeMode.dark, onChanged: (_) => app.toggleTheme(), title: Text(strings.darkMode)),
              SwitchListTile(value: app.soundOn, onChanged: (_) => app.toggleSound(), title: Text(strings.sound)),
              SwitchListTile(value: app.musicOn, onChanged: (_) => app.toggleMusic(), title: Text(strings.music)),
              ListTile(title: Text(strings.language), trailing: Text(app.locale.languageCode.toUpperCase()), onTap: app.toggleLocale),
              ListTile(title: Text(strings.about), subtitle: const Text('ZYNORA Games • Play. Connect. Win.')),
              ListTile(title: Text(strings.terms)),
              ListTile(title: Text(strings.privacy)),
              ListTile(title: Text(strings.logout), onTap: onLogout ?? app.logout),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(title: strings.contactUs),
        const SizedBox(height: 12),
        ...const [
          ('WhatsApp', 'https://wa.me/213779109990', Icons.chat_rounded),
          ('Instagram', 'https://www.instagram.com/wh.s.8', Icons.camera_alt_rounded),
          ('Facebook', 'https://www.facebook.com/profile.php?id=61570663858487', Icons.facebook_rounded),
          ('Email', 'mailto:ww608352@gmail.com', Icons.email_rounded),
          ('GitHub', 'https://github.com/walid4mp/Walidmsk', Icons.code_rounded),
        ].map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ZCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(item.$3),
                  title: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(item.$2),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: () => launchUrl(Uri.parse(item.$2), mode: LaunchMode.externalApplication),
                ),
              ),
            )),
      ],
    );
  }
}
