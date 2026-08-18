import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_controller.dart';
import '../../core/translations.dart';
import '../../core/widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();
  bool registerMode = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final strings = ZStrings.of(context);
    return Scaffold(
      body: GradientScaffold(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: ZCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(strings.appName,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text(strings.slogan, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      if (registerMode) ...[
                        TextField(controller: usernameController, decoration: InputDecoration(labelText: strings.username)),
                        const SizedBox(height: 12),
                      ],
                      TextField(controller: emailController, decoration: InputDecoration(labelText: strings.email)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(labelText: strings.password),
                      ),
                      const SizedBox(height: 18),
                      if (app.error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(app.error, style: const TextStyle(color: Colors.redAccent)),
                        ),
                      PrimaryButton(
                        label: registerMode ? strings.register : strings.login,
                        icon: registerMode ? Icons.person_add_alt_1_rounded : Icons.login_rounded,
                        onPressed: app.loading
                            ? null
                            : () async {
                                final email = emailController.text.trim();
                                final password = passwordController.text;
                                final username = usernameController.text.trim();

                                if (!email.contains('@') || !email.contains('.')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('أدخل بريدًا إلكترونيًا صحيحًا.')),
                                  );
                                  return;
                                }
                                if (password.length < 8) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('كلمة المرور يجب أن تحتوي على 8 أحرف على الأقل.')),
                                  );
                                  return;
                                }
                                if (registerMode && username.length < 3) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('اسم المستخدم يجب أن يحتوي على 3 أحرف على الأقل.')),
                                  );
                                  return;
                                }

                                try {
                                  if (registerMode) {
                                    await app.register(email, username, password);
                                  } else {
                                    await app.login(email, password);
                                  }
                                } catch (_) {
                                  // AppController exposes the friendly message.
                                }
                              },
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => setState(() => registerMode = !registerMode),
                        child: Text(registerMode ? strings.login : strings.register),
                      ),
                      TextButton(
                        onPressed: () => _showResetDialog(context, app),
                        child: Text(strings.forgotPassword),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showResetDialog(BuildContext context, AppController app) async {
    final strings = ZStrings.of(context);
    final email = TextEditingController(text: emailController.text);
    final password = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.resetPassword),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: email, decoration: InputDecoration(labelText: strings.email)),
            const SizedBox(height: 12),
            TextField(controller: password, decoration: InputDecoration(labelText: strings.password), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await app.resetPassword(email.text.trim(), password.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(strings.save),
          ),
        ],
      ),
    );
  }
}
