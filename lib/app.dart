import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/constants/app_constants.dart';
import 'package:jeb/core/theme/app_theme.dart';
import 'package:jeb/features/settings/domain/entities/app_theme_mode.dart';
import 'package:jeb/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:jeb/features/app_shell/presentation/main_shell.dart';
import 'package:jeb/features/settings/presentation/widgets/app_lock_gate.dart';

/// Root application widget. Rebuilds the [MaterialApp] when the user changes
/// their theme preference.
class JebApp extends StatelessWidget {
  const JebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (SettingsState p, SettingsState c) =>
          p.settings.themeMode != c.settings.themeMode,
      builder: (BuildContext context, SettingsState state) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: _toThemeMode(state.settings.themeMode),
          home: const AppLockGate(child: MainShell()),
        );
      },
    );
  }

  ThemeMode _toThemeMode(AppThemeMode mode) => switch (mode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };
}
