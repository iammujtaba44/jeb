import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/constants/currencies.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/utils/formatters.dart';
import 'package:jeb/core/widgets/currency_picker_sheet.dart';
import 'package:jeb/core/widgets/icon_badge.dart';
import 'package:jeb/features/settings/domain/entities/app_theme_mode.dart';
import 'package:jeb/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Accent colors for the settings icon badges — each tile gets its own hue
/// so the screen reads as a set of distinct, beautiful controls.
abstract class _Accent {
  static const Color money = Color(0xFF16A34A); // green
  static const Color theme = Color(0xFF7C3AED); // violet
  static const Color cloud = Color(0xFF2563EB); // blue
  static const Color backup = Color(0xFF0D9488); // teal
  static const Color lock = Color(0xFFF59E0B); // amber
  static const Color privacy = Color(0xFF059669); // emerald
  static const Color reminder = Color(0xFFE11D48); // rose
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listenWhen: (SettingsState p, SettingsState c) =>
            p.syncStatus != c.syncStatus,
        listener: _onSyncStatusChanged,
        builder: (BuildContext context, SettingsState state) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              const _SectionLabel('Preferences'),
              _SettingsCard(
                children: <Widget>[
                  _CurrencyTile(
                    currencyCode: state.settings.defaultCurrencyCode,
                  ),
                  const _TileDivider(),
                  _ThemeTile(mode: state.settings.themeMode),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionLabel('Reminders'),
              _SettingsCard(
                children: <Widget>[
                  _ReminderToggleTile(
                    enabled: state.settings.reminderEnabled,
                  ),
                  if (state.settings.reminderEnabled) ...<Widget>[
                    const _TileDivider(),
                    _ReminderTimeTile(minutes: state.settings.reminderMinutes),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionLabel('Backup & Sync'),
              _SettingsCard(
                children: <Widget>[
                  _SyncToggleTile(enabled: state.settings.syncEnabled),
                  if (state.settings.syncEnabled) ...<Widget>[
                    const _TileDivider(),
                    _BackupNowTile(state: state),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionLabel('Security'),
              _SettingsCard(
                children: <Widget>[
                  _AppLockTile(enabled: state.settings.appLockEnabled),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionLabel('About'),
              _SettingsCard(
                children: <Widget>[
                  _SettingsTile(
                    icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.duotone),
                    tint: _Accent.privacy,
                    title: 'Private by design',
                    subtitle:
                        'Your data lives on this device and your own iCloud — never on our servers.',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _onSyncStatusChanged(BuildContext context, SettingsState state) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (state.syncStatus == SyncStatus.success) {
      messenger.showSnackBar(const SnackBar(content: Text('Backed up ✓')));
    } else if (state.syncStatus == SyncStatus.failure) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Backup failed — check iCloud'),
        ),
      );
    }
  }
}

// ── Building blocks ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) => const Divider(height: 1, indent: 64);
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.tint,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? tint;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: IconBadge(icon: icon, color: tint),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
    );
  }
}

/// A muted chevron used as a tile's trailing affordance.
class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) {
    return Icon(
      PhosphorIcons.caretRight(),
      size: 18,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}

// ── Specific tiles ─────────────────────────────────────────────────────

class _CurrencyTile extends StatelessWidget {
  const _CurrencyTile({required this.currencyCode});

  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final Currency currency = Currencies.byCode(currencyCode);
    return _SettingsTile(
      icon: PhosphorIcons.coins(PhosphorIconsStyle.duotone),
      tint: _Accent.money,
      title: 'Default currency',
      subtitle: '${currency.symbol}  ${currency.code} · ${currency.name}',
      trailing: const _Chevron(),
      onTap: () => _pick(context),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final SettingsCubit cubit = context.read<SettingsCubit>();
    final String? picked =
        await showCurrencyPicker(context, selected: currencyCode);
    if (picked != null) cubit.setDefaultCurrency(picked);
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.mode});

  final AppThemeMode mode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconBadge(
                icon: PhosphorIcons.palette(PhosphorIconsStyle.duotone),
                color: _Accent.theme,
              ),
              const SizedBox(width: AppSpacing.md),
              const Text('Theme', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AppThemeMode>(
              segments: const <ButtonSegment<AppThemeMode>>[
                ButtonSegment<AppThemeMode>(
                  value: AppThemeMode.system,
                  label: Text('System'),
                ),
                ButtonSegment<AppThemeMode>(
                  value: AppThemeMode.light,
                  label: Text('Light'),
                ),
                ButtonSegment<AppThemeMode>(
                  value: AppThemeMode.dark,
                  label: Text('Dark'),
                ),
              ],
              selected: <AppThemeMode>{mode},
              onSelectionChanged: (Set<AppThemeMode> selection) =>
                  context.read<SettingsCubit>().setThemeMode(selection.first),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderToggleTile extends StatelessWidget {
  const _ReminderToggleTile({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: enabled,
      onChanged: context.read<SettingsCubit>().setReminderEnabled,
      secondary: IconBadge(
        icon: PhosphorIcons.bellRinging(PhosphorIconsStyle.duotone),
        color: _Accent.reminder,
      ),
      title: const Text(
        'Daily reminder',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: const Text('A nudge to log your spending each day'),
    );
  }
}

class _ReminderTimeTile extends StatelessWidget {
  const _ReminderTimeTile({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final TimeOfDay time =
        TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    return _SettingsTile(
      icon: PhosphorIcons.clock(PhosphorIconsStyle.duotone),
      tint: _Accent.reminder,
      title: 'Time',
      subtitle: time.format(context),
      trailing: const _Chevron(),
      onTap: () => _pickTime(context, time),
    );
  }

  Future<void> _pickTime(BuildContext context, TimeOfDay initial) async {
    final SettingsCubit cubit = context.read<SettingsCubit>();
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      cubit.setReminderMinutes(picked.hour * 60 + picked.minute);
    }
  }
}

class _AppLockTile extends StatelessWidget {
  const _AppLockTile({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: enabled,
      onChanged: context.read<SettingsCubit>().setAppLock,
      secondary: IconBadge(
        icon: PhosphorIcons.lockKey(PhosphorIconsStyle.duotone),
        color: _Accent.lock,
      ),
      title: const Text(
        'App lock',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: const Text('Require Face ID / fingerprint to open Jeb'),
    );
  }
}

class _SyncToggleTile extends StatelessWidget {
  const _SyncToggleTile({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: enabled,
      onChanged: context.read<SettingsCubit>().setSyncEnabled,
      secondary: IconBadge(
        icon: PhosphorIcons.cloud(PhosphorIconsStyle.duotone),
        color: _Accent.cloud,
      ),
      title: const Text(
        'iCloud Sync',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        enabled
            ? 'Backs up privately to your own iCloud.'
            : 'Off — data stays only on this device.',
      ),
    );
  }
}

class _BackupNowTile extends StatelessWidget {
  const _BackupNowTile({required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    final DateTime? last = state.settings.lastSyncedAt;
    final bool syncing = state.syncStatus == SyncStatus.syncing;
    return _SettingsTile(
      icon: PhosphorIcons.cloudArrowUp(PhosphorIconsStyle.duotone),
      tint: _Accent.backup,
      title: 'Back up now',
      subtitle: last == null
          ? 'Not backed up yet'
          : 'Last: ${DateFormatter.dateTime(last)}',
      trailing: syncing
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const _Chevron(),
      onTap: syncing ? null : context.read<SettingsCubit>().backupNow,
    );
  }
}
