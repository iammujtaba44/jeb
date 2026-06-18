import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/app.dart';
import 'package:jeb/core/di/injection.dart';
import 'package:jeb/core/services/notification_service.dart';
import 'package:jeb/features/settings/presentation/cubit/settings_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await getIt<NotificationService>().init();
  runApp(
    BlocProvider<SettingsCubit>(
      create: (_) => getIt<SettingsCubit>()..load(),
      child: const JebApp(),
    ),
  );
}
