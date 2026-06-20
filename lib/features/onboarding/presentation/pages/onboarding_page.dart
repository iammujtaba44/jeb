import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/constants/app_constants.dart';
import 'package:jeb/core/constants/currencies.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/widgets/currency_picker_sheet.dart';
import 'package:jeb/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// First-run setup: pick the home currency and choose whether to back up.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late String _currency = _deviceCurrency();
  bool _sync = true;

  static String _deviceCurrency() {
    final String? country = ui.PlatformDispatcher.instance.locale.countryCode;
    const Map<String, String> byCountry = <String, String>{
      'PK': 'PKR', 'IN': 'INR', 'US': 'USD', 'GB': 'GBP', 'AE': 'AED',
      'SA': 'SAR', 'CA': 'CAD', 'AU': 'AUD', 'JP': 'JPY', 'CH': 'CHF',
      'TR': 'TRY', 'DE': 'EUR', 'FR': 'EUR', 'ES': 'EUR', 'IT': 'EUR',
      'NL': 'EUR', 'PT': 'EUR', 'IE': 'EUR',
    };
    final String code =
        byCountry[country] ?? AppConstants.defaultCurrencyCode;
    return Currencies.all.any((Currency c) => c.code == code)
        ? code
        : AppConstants.defaultCurrencyCode;
  }

  Future<void> _pickCurrency() async {
    final String? picked =
        await showCurrencyPicker(context, selected: _currency);
    if (picked != null) setState(() => _currency = picked);
  }

  void _finish() {
    context.read<SettingsCubit>().completeOnboarding(
          currencyCode: _currency,
          syncEnabled: _sync,
        );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Currency currency = Currencies.byCode(_currency);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Spacer(flex: 2),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Icon(
                  PhosphorIcons.wallet(PhosphorIconsStyle.duotone),
                  color: scheme.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Welcome to ${AppConstants.appName}',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Private, local-first money tracking. Let’s set a couple of '
                'things up.',
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: Icon(
                        PhosphorIcons.coins(PhosphorIconsStyle.duotone),
                        color: scheme.primary,
                      ),
                      title: const Text(
                        'Your currency',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${currency.symbol}  ${currency.code} · ${currency.name}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickCurrency,
                    ),
                    const Divider(height: 1, indent: 56),
                    SwitchListTile(
                      value: _sync,
                      onChanged: (bool v) => setState(() => _sync = v),
                      secondary: Icon(
                        PhosphorIcons.cloud(PhosphorIconsStyle.duotone),
                        color: scheme.primary,
                      ),
                      title: const Text(
                        'Back up to iCloud',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Private backup to your own iCloud'),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              FilledButton(
                onPressed: _finish,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Get started'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'You can change these anytime in Settings.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
