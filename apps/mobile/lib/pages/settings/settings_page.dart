import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_notifier.dart';
import '../../shared/api/tags_api.dart';
import '../../shared/core/strings.dart';
import '../../shared/notifications/notification_prefs.dart';
import '../../shared/notifications/notification_service.dart';
import '../../shared/providers/tag_store.dart';
import '../../shared/theme/theme.dart';
import '../../shared/ui/app_toast.dart';
import '../../pages/app_shell.dart';
import '../../shared/theme/theme_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final prefsAsync = ref.watch(notificationPrefsProvider);
    final themeMode = ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 120,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Locus', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: context.colorTextStrong)),
              const SizedBox(width: 5),
              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: context.colorBrand)),
            ],
          ),
        ),
        title: Text(S.navSettings, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.colorText)),
        actions: [
          IconButton(icon: const Icon(Icons.menu), onPressed: AppShell.openDrawer),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        children: [
          // ── Account ────────────────────────────────────────────────────
          if (user != null) ...[
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: context.colorSurface2,
                child: Text(
                  (user.name.isNotEmpty ? user.name : user.email)[0].toUpperCase(),
                  style: TextStyle(color: context.colorBrand),
                ),
              ),
              title: Text(
                user.name.isNotEmpty ? user.name : user.email,
                style: TextStyle(color: context.colorTextStrong),
              ),
              subtitle: Text(user.email, style: TextStyle(color: context.colorMuted, fontSize: 12)),
              trailing: Icon(Icons.edit_outlined, size: 18, color: context.colorMuted),
              onTap: () => _showEditProfileDialog(context, ref, user.name, user.email),
            ),
            Divider(color: context.colorBorder),
          ],

          // ── Appearance ─────────────────────────────────────────────────
          _SectionHeader(title: 'Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: context.colorSurface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _ThemeOption(
                    icon: Icons.light_mode_outlined,
                    label: 'Light',
                    selected: themeMode == ThemeMode.light,
                    onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.light),
                  ),
                  _ThemeOption(
                    icon: Icons.brightness_auto_outlined,
                    label: 'System',
                    selected: themeMode == ThemeMode.system,
                    onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.system),
                  ),
                  _ThemeOption(
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark',
                    selected: themeMode == ThemeMode.dark,
                    onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark),
                  ),
                ],
              ),
            ),
          ),

          Divider(color: context.colorBorder),

          // ── Notifications ───────────────────────────────────────────────
          _SectionHeader(title: 'Notifications'),

          prefsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => ListTile(
              title: Text('Failed to load preferences: $e',
                  style: TextStyle(color: context.colorDanger)),
            ),
            data: (prefs) => _NotificationSection(prefs: prefs),
          ),

          Divider(color: context.colorBorder),

          // ── Tags ───────────────────────────────────────────────────────
          _SectionHeader(title: 'Tags'),
          _TagManagementSection(),

          Divider(color: context.colorBorder),

          // ── Logout ─────────────────────────────────────────────────────
          ListTile(
            leading: Icon(Icons.logout, color: context.colorDanger),
            title: Text('Sign out', style: TextStyle(color: context.colorDanger)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Sign out',
                          style: TextStyle(color: context.colorDanger)),
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

void _showEditProfileDialog(BuildContext context, WidgetRef ref, String currentName, String currentEmail) {
  final nameCtrl = TextEditingController(text: currentName);
  final emailCtrl = TextEditingController(text: currentEmail);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('Edit profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Name'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailCtrl,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final name = nameCtrl.text.trim();
            final email = emailCtrl.text.trim();
            Navigator.pop(ctx);
            await ref.read(authNotifierProvider.notifier).updateProfile(
              name: name.isNotEmpty ? name : null,
              email: email.isNotEmpty ? email : null,
            );
            // Failure toast is already shown by the notifier itself.
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

// ── Theme option button ────────────────────────────────────────────────────────

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? context.colorBrand.withAlpha(30) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? context.colorBrand : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? context.colorBrand : context.colorMuted),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? context.colorBrand : context.colorMuted,
                ),
              ),
            ],
          ),
        ),
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
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
            color: context.colorMuted,
          ),
        ),
      );
}

// ── Notification section ───────────────────────────────────────────────────────

class _NotificationSection extends ConsumerWidget {
  final NotificationPrefs prefs;
  const _NotificationSection({required this.prefs});

  Future<void> _requestAndSave(WidgetRef ref, NotificationPrefs updated) async {
    if (updated.preDeadlineEnabled || updated.eveningSummaryEnabled) {
      await NotificationService.requestPermission();
    }
    await ref.read(notificationPrefsProvider.notifier).savePrefs(updated);
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
          title: Text('Pre-deadline reminder',
              style: TextStyle(color: context.colorTextStrong)),
          subtitle: Text('Notify before a task is due',
              style: TextStyle(color: context.colorMuted, fontSize: 12)),
          secondary: Icon(Icons.alarm, color: context.colorBrand),
        ),

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
                  .savePrefs(prefs.copyWith(preDeadlineMinutes: mins)),
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),

        Divider(color: context.colorBorder, indent: 16, endIndent: 16),

        // ── Evening summary toggle ──────────────────────────────────────
        SwitchListTile(
          value: prefs.eveningSummaryEnabled,
          onChanged: (val) => _requestAndSave(
            ref,
            prefs.copyWith(eveningSummaryEnabled: val),
          ),
          title: Text('Evening summary',
              style: TextStyle(color: context.colorTextStrong)),
          subtitle: Text('Daily recap of pending tasks',
              style: TextStyle(color: context.colorMuted, fontSize: 12)),
          secondary: Icon(Icons.nightlight_round, color: context.colorBrand),
        ),

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
                  .savePrefs(prefs.copyWith(eveningSummaryHour: h, eveningSummaryMinute: m)),
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
        color: context.colorSurface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Remind me',
            style: TextStyle(fontSize: 12, color: context.colorMuted),
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
                    color: selected ? context.colorBrand : context.colorSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? context.colorBrand : context.colorBorder,
                    ),
                  ),
                  child: Text(
                    _label(mins),
                    style: TextStyle(
                      fontSize: 13,
                      color: selected ? Colors.white : context.colorText,
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
            style: TextStyle(fontSize: 12, color: context.colorMuted2),
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

// ── Tag management ────────────────────────────────────────────────────────────

class _TagManagementSection extends ConsumerWidget {
  const _TagManagementSection();

  Color _parseColor(String? hex) {
    if (hex == null) return Colors.grey;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  void _showCreateTagDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('New tag'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tag name'),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => _createTag(ref, ctx, nameCtrl.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _createTag(ref, ctx, nameCtrl.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTag(WidgetRef ref, BuildContext dialogCtx, String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) return;
    Navigator.pop(dialogCtx);
    try {
      await ref.read(tagsApiProvider).create(name);
      await ref.read(tagStoreProvider.notifier).reload();
    } catch (_) {
      ref.read(appToastProvider.notifier).show(S.tagCreateFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagStoreProvider).tags;

    return Column(
      children: [
        if (tags.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'No tags yet',
              style: TextStyle(fontSize: 13, color: context.colorMuted),
            ),
          )
        else
          ...tags.map((tag) => ListTile(
                dense: true,
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _parseColor(tag.color),
                  ),
                ),
                title: Text(tag.name, style: TextStyle(fontSize: 14, color: context.colorText)),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: context.colorMuted),
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    try {
                      await ref.read(tagsApiProvider).delete(tag.id);
                      await ref.read(tagStoreProvider.notifier).reload();
                    } catch (_) {
                      ref.read(appToastProvider.notifier).show(S.tagDeleteFailed);
                    }
                  },
                ),
              )),
        ListTile(
          dense: true,
          leading: Icon(Icons.add, size: 18, color: context.colorBrand),
          title: Text('Add tag', style: TextStyle(fontSize: 14, color: context.colorBrand)),
          onTap: () => _showCreateTagDialog(context, ref),
        ),
      ],
    );
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
        color: context.colorSurface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, size: 18, color: context.colorMuted),
          const SizedBox(width: 10),
          Text(
            'Send summary at',
            style: TextStyle(fontSize: 13, color: context.colorText),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: hour, minute: minute),
              );
              if (picked != null) {
                onChanged(picked.hour, picked.minute);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: context.colorBrandSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colorBrand.withAlpha(100)),
              ),
              child: Text(
                _displayTime,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colorBrand2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
