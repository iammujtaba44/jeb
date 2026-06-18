import 'package:flutter_test/flutter_test.dart';
import 'package:jeb/features/settings/domain/entities/app_settings.dart';

void main() {
  group('AppSettings reminder', () {
    test('defaults to 20:00, disabled', () {
      const AppSettings s = AppSettings.defaults;
      expect(s.reminderEnabled, isFalse);
      expect(s.reminderMinutes, 20 * 60);
      expect(s.reminderHour, 20);
      expect(s.reminderMinute, 0);
    });

    test('derives hour and minute from minutes-since-midnight', () {
      final AppSettings s =
          AppSettings.defaults.copyWith(reminderMinutes: 9 * 60 + 30);
      expect(s.reminderHour, 9);
      expect(s.reminderMinute, 30);
    });

    test('copyWith toggles the reminder without touching the time', () {
      final AppSettings s = AppSettings.defaults
          .copyWith(reminderMinutes: 7 * 60, reminderEnabled: true);
      expect(s.reminderEnabled, isTrue);
      expect(s.reminderHour, 7);
      final AppSettings off = s.copyWith(reminderEnabled: false);
      expect(off.reminderEnabled, isFalse);
      expect(off.reminderMinutes, 7 * 60);
    });
  });
}
