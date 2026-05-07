import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_notifier.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          if (user != null) ...[
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF252C32),
                child: Text(
                  user.email[0].toUpperCase(),
                  style: const TextStyle(color: Color(0xFF579DFF)),
                ),
              ),
              title: Text(user.email, style: const TextStyle(color: Color(0xFFE2E8ED))),
              subtitle: const Text('Аккаунт', style: TextStyle(color: Color(0xFF7A8A97))),
            ),
            const Divider(color: Color(0xFF2E3740)),
          ],
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFF87168)),
            title: const Text('Выйти', style: TextStyle(color: Color(0xFFF87168))),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E2428),
                  title: const Text('Выйти из аккаунта?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Выйти', style: TextStyle(color: Color(0xFFF87168))),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(authNotifierProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
    );
  }
}
