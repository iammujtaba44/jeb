import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/constants/app_constants.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/widgets/face_id_icon.dart';
import 'package:jeb/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:local_auth/local_auth.dart';

/// Overlays a biometric lock above the entire app when app lock is enabled.
/// Locks on a cold start, and re-locks on resume only after the app has been
/// in the background longer than [_gracePeriod] — so brief system excursions
/// (image picker, share sheet, Face ID prompt) don't force a re-auth.
class AppLockGate extends StatefulWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _locked = true;
  DateTime? _backgroundedAt;

  /// How long the app can be away before it re-locks on return.
  static const Duration _gracePeriod = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (!context.read<SettingsCubit>().state.settings.appLockEnabled) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final DateTime? since = _backgroundedAt;
      _backgroundedAt = null;
      if (!_locked &&
          since != null &&
          DateTime.now().difference(since) > _gracePeriod) {
        setState(() => _locked = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = context.select<SettingsCubit, bool>(
      (SettingsCubit cubit) => cubit.state.settings.appLockEnabled,
    );
    return Stack(
      children: <Widget>[
        widget.child,
        if (enabled && _locked)
          Positioned.fill(
            child: _LockScreen(
              onUnlocked: () {
                if (mounted) setState(() => _locked = false);
              },
            ),
          ),
      ],
    );
  }
}

enum _Bio { face, fingerprint, generic }

class _LockScreen extends StatefulWidget {
  const _LockScreen({required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _busy = false;
  _Bio _bio = _Bio.generic;

  @override
  void initState() {
    super.initState();
    _loadBiometricType();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _loadBiometricType() async {
    try {
      final List<BiometricType> available =
          await _auth.getAvailableBiometrics();
      if (!mounted) return;
      setState(() {
        if (available.contains(BiometricType.face)) {
          _bio = _Bio.face;
        } else if (available.contains(BiometricType.fingerprint) ||
            available.contains(BiometricType.strong)) {
          _bio = _Bio.fingerprint;
        } else {
          _bio = _Bio.generic;
        }
      });
    } catch (_) {
      /* keep generic */
    }
  }

  Future<void> _authenticate() async {
    if (_busy) return;
    setState(() => _busy = true);
    bool ok = false;
    try {
      ok = await _auth.authenticate(
        localizedReason: 'Unlock ${AppConstants.appName}',
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) widget.onUnlocked();
  }

  Widget _bioGlyph(Color color) => switch (_bio) {
        _Bio.face => FaceIdIcon(size: 46, color: color),
        _Bio.fingerprint =>
          Icon(Icons.fingerprint_rounded, size: 46, color: color),
        _Bio.generic => Icon(Icons.lock_open_rounded, size: 46, color: color),
      };

  String get _bioLabel {
    final bool apple = Platform.isIOS || Platform.isMacOS;
    return switch (_bio) {
      _Bio.face => apple ? 'Unlock with Face ID' : 'Unlock with face',
      _Bio.fingerprint =>
        apple ? 'Unlock with Touch ID' : 'Unlock with fingerprint',
      _Bio.generic => 'Tap to unlock',
    };
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color onColor = scheme.onPrimary;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              scheme.primary,
              Color.alphaBlend(
                scheme.tertiary.withValues(alpha: 0.45),
                scheme.primary,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: <Widget>[
                const Spacer(flex: 3),
                _LockEmblem(onColor: onColor),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  AppConstants.appName,
                  style: textTheme.displaySmall?.copyWith(
                    color: onColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Locked for your privacy',
                  style: textTheme.bodyLarge?.copyWith(
                    color: onColor.withValues(alpha: 0.8),
                  ),
                ),
                const Spacer(flex: 4),
                _BiometricButton(
                  onColor: onColor,
                  busy: _busy,
                  onTap: _authenticate,
                  child: _bioGlyph(onColor),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _bioLabel,
                  style: textTheme.titleMedium?.copyWith(
                    color: onColor.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The decorative lock badge at the top of the lock screen.
class _LockEmblem extends StatelessWidget {
  const _LockEmblem({required this.onColor});

  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onColor.withValues(alpha: 0.12),
        border: Border.all(color: onColor.withValues(alpha: 0.28), width: 1.5),
      ),
      child: Icon(Icons.lock_rounded, size: 48, color: onColor),
    );
  }
}

/// Large tappable biometric (Face ID / fingerprint) button.
class _BiometricButton extends StatelessWidget {
  const _BiometricButton({
    required this.child,
    required this.onColor,
    required this.busy,
    required this.onTap,
  });

  final Widget child;
  final Color onColor;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: busy ? null : onTap,
      radius: 56,
      child: Container(
        width: 92,
        height: 92,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onColor.withValues(alpha: 0.18),
          border: Border.all(color: onColor.withValues(alpha: 0.4), width: 2),
        ),
        child: busy
            ? Padding(
                padding: const EdgeInsets.all(26),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(onColor),
                ),
              )
            : child,
      ),
    );
  }
}
