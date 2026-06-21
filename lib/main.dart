import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/app.dart';
import 'package:jeb/core/di/injection.dart';
import 'package:jeb/core/services/forex_service.dart';
import 'package:jeb/core/services/google_drive_auth.dart';
import 'package:jeb/core/services/notification_service.dart';
import 'package:jeb/core/services/receipt_store.dart';
import 'package:jeb/features/home/presentation/cubit/home_layout_cubit.dart';
import 'package:jeb/features/settings/presentation/cubit/settings_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await getIt<NotificationService>().init();
  await getIt<ReceiptStore>().init();
  // Apply cached FX rates immediately, then refresh in the background.
  getIt<ForexService>().primeFromCache();
  unawaited(getIt<ForexService>().refreshIfStale());
  // Restore a previously connected Google Drive session (Android backup).
  if (Platform.isAndroid) {
    unawaited(getIt<GoogleDriveAuth>().restore());
  }
  runApp(
    MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<SettingsCubit>(
          create: (_) => getIt<SettingsCubit>()..load(),
        ),
        BlocProvider<HomeLayoutCubit>(
          create: (_) => getIt<HomeLayoutCubit>(),
        ),
      ],
      child: const JebApp(),
    ),
  );
}
