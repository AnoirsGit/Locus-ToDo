import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_notifier.dart';
import '../../shared/notifications/notification_prefs.dart';
import '../../shared/notifications/notification_service.dart';
import '../../shared/theme/theme.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final prefsAsync = ref.watch(notificationPrefsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Account ────────────────────────────────────────────────────
          if (user != null) ...[
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.surface2Dark,
                child: Text(
                  user.email[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.brandDark),
                ),
              ),
              title: Text(user.email, style: const TextStyle(color: AppColors.textStrongDark)),
              subtitle: const Text('Account', style: TextStyle(color: AppColors.mutedDark)),
            ),
            const Divider(color: AppColors.borderDark),
          ],

          // ── Notifications ───────────────────────────────────────────────
          const _SectionHeader(title: 'Notifications'),

          prefsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => ListTile(
              title: Text('Failed to load preferences: $e',
                  style: const TextStyle(color: AppColors.dangerDark)),
            ),
            data: (prefs) => _NotificationSection(prefs: prefs),
          ),

          const Divider(color: AppColors.borderDark),

          // ── Logout ─────────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.dangerDark),
            title: const Text('Sign out', style: TextStyle(color: AppColors.dangerDark)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surfaceDark,
                  title: const Text('Sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign out',
                          style: TextStyle(color: AppColors.dangerDark)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(authNotifierProvider.notifier).logout();
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
            color: AppColors.mutedDark,
          ),
        ),
      );
}

// ── Notification section ───────────────────────────────────────────────────────

class _NotificationSection extends ConsumerWidget {
  final NotificationPrefs prefs;
  const _NotificationSection({required this.prefs});

  Future<void> _requestAndSave(WidgetRef ref, NotificationPrefs updated) async {
    // If enabling any notification for the first time, request permission
    if (updated.preDeadlineEnabled || updated.eveningSummaryEnabled) {
      await NotificationService.requestPermission();
    }
    await ref.read(notificationPrefsProvider.notifier).update(updated);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // ── Pre-deadline toggle ─────────────────────────────────────────
        SwitchListTile(
          value: prefs.preDeadlineEnabled,
          onChanged: (val) => _requestAndSave(
            ref,
            prefs.copyWith(preDeadlineEnabled: val),
          ),
          title: const Text('Pre-deadline reminder',
              style: TextStyle(color: AppColors.textStrongDark)),
          subtitle: const Text('Notify before a task is due',
              style: TextStyle(color: AppColors.mutedDark, fontSize: 12)),
          secondary: const Icon(Icons.alarm, color: AppColors.brandDark),
          activeColor: AppColors.brandDark,
        ),

        // Lead time picker (visible only when enabled)
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: prefs.preDeadlineEnabled
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _LeadTimePicker(
              minutes: prefs.preDeadlineMinutes,
              onChanged: (mins) => ref
                  .read(notificationPrefsProvider.notifier)
                  .update(prefs.copyWith(preDeadlineMinutes: mins)),
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),

        const Divider(color: AppColors.borderDark, indent: 16, endIndent: 16),

        // ── Evening summary toggle ──────────────────────────────────────
        SwitchListTile(
          value: prefs.eveningSummaryEnabled,
          onChanged: (val) => _requestAndSave(
            ref,
            prefs.copyWith(eveningSummaryEnabled: val),
          ),
          title: const Text('Evening summary',
              style: TextStyle(color: AppColors.textStrongDark)),
          subtitle: const Text('Daily recap of pending tasks',
              style: TextStyle(color: AppColors.mutedDark, fontSize: 12)),
          secondary: const Icon(Icons.nightlight_round, color: AppColors.brandDark),
          activeColor: AppColors.brandDark,
        ),

        // Time picker (visible only when enabled)
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: prefs.eveningSummaryEnabled
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _EveningTimePicker(
              hour: prefs.eveningSummaryHour,
              minute: prefs.eveningSummaryMinute,
              onChanged: (h, m) => ref
                  .read(notificationPrefsProvider.notifier)
                  .update(prefs.copyWith(eveningSummaryHour: h, eveningSummaryMinute: m)),
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── Lead time picker ───────────────────────────────────────────────────────────

class _LeadTimePicker extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onChanged;

  static const _options = [5, 10, 15, 30, 60, 120];

  const _LeadTimePicker({required this.minutes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2Dark,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Remind me',
            style: TextStyle(fontSize: 12, color: AppColors.mutedDark),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options.map((mins) {
              final selected = mins == minutes;
              return GestureDetector(
                onTap: () => onChanged(mins),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.brandDark : AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.brandDark : AppColors.borderDark,
                    ),
                  ),
                  child: Text(
                    _label(mins),
                    style: TextStyle(
                      fontSize: 13,
                      color: selected ? Colors.white : AppColors.textDark,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Text(
            'before scheduled time',
            style: const TextStyle(fontSize: 12, color: AppColors.muted2Dark),
          ),
        ],
      ),
    );
  }

  String _label(int mins) {
    if (mins < 60) return '${mins}m';
    return '${mins ~/ 60}h';
  }
}

// ── Evening time picker ────────────────────────────────────────────────────────

class _EveningTimePicker extends StatelessWidget {
  final int hour;
  final int minute;
  final void Function(int hour, int minute) onChanged;

  const _EveningTimePicker({
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  String get _displayTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2Dark,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 18, color: AppColors.mutedDark),
          const SizedBox(width: 10),
          const Text(
            'Send summary at',
            style: TextStyle(fontSize: 13, color: AppColors.textDark),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: hour, minute: minute),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.brandDark,
                      surface: AppColors.surfaceDark,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                onChanged(picked.hour, picked.minute);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.brandSoftDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.brandDark.withOpacity(0.4)),
              ),
              child: Text(
                _displayTime,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand2Dark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
