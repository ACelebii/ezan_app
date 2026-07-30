import 'package:flutter_test/flutter_test.dart';
import 'package:ezan_vakti_uygulamasi/features/hatirlaticilar/data/reminder_scheduler.dart';

void main() {
  group('ReminderScheduler.parseMinutesOfDay', () {
    test('parses Aladhan formatted time strings', () {
      expect(ReminderScheduler.parseMinutesOfDay('05:23 (+03)'), 5 * 60 + 23);
      expect(ReminderScheduler.parseMinutesOfDay('00:00'), 0);
      expect(ReminderScheduler.parseMinutesOfDay('23:59'), 23 * 60 + 59);
    });

    test('returns null for malformed input', () {
      expect(ReminderScheduler.parseMinutesOfDay('not a time'), isNull);
      expect(ReminderScheduler.parseMinutesOfDay(null), isNull);
      expect(ReminderScheduler.parseMinutesOfDay(42), isNull);
    });
  });

  group('ReminderScheduler.triggerTime', () {
    test('subtracts the offset from the base time', () {
      final t = ReminderScheduler.triggerTime(12 * 60 + 30, 60); // Öğle 12:30, 60dk önce
      expect(t.hour, 11);
      expect(t.minute, 30);
    });

    test('wraps around midnight when the offset crosses it', () {
      final t = ReminderScheduler.triggerTime(30, 60); // 00:30 - 60dk
      expect(t.hour, 23);
      expect(t.minute, 30);
    });

    test('zero offset returns the base time unchanged', () {
      final t = ReminderScheduler.triggerTime(5 * 60 + 10, 0);
      expect(t.hour, 5);
      expect(t.minute, 10);
    });
  });

  group('ReminderScheduler.ramadanWindowFromEntries', () {
    final entries = [
      {
        'yil': 2025,
        'ay': 'Mart',
        'gunNo': '1',
        'baslik': "Ramazan'ın İlk Günü",
      },
      {
        'yil': 2025,
        'ay': 'Mart',
        'gunNo': '30',
        'baslik': 'Ramazan Bayramı',
      },
      {
        'yil': 2026,
        'ay': 'Şubat',
        'gunNo': '18',
        'baslik': "Ramazan'ın İlk Günü",
      },
      {
        'yil': 2026,
        'ay': 'Mart',
        'gunNo': '20',
        'baslik': 'Ramazan Bayramı',
      },
    ];

    test('returns the window that contains "today"', () {
      final window = ReminderScheduler.ramadanWindowFromEntries(
          entries, DateTime(2026, 3, 1));
      expect(window, isNotNull);
      expect(window!.start, DateTime(2026, 2, 18));
      expect(window.end, DateTime(2026, 3, 19));
    });

    test('returns the next upcoming window when today is before it', () {
      final window = ReminderScheduler.ramadanWindowFromEntries(
          entries, DateTime(2025, 6, 1));
      expect(window, isNotNull);
      expect(window!.start, DateTime(2026, 2, 18));
    });

    test('returns null when no window covers or follows "today"', () {
      final window = ReminderScheduler.ramadanWindowFromEntries(
          entries, DateTime(2026, 4, 1));
      expect(window, isNull);
    });

    test('falls back to a 29-day window when no Bayram entry is found', () {
      final noBayram = [
        {
          'yil': 2030,
          'ay': 'Ocak',
          'gunNo': '10',
          'baslik': "Ramazan'ın İlk Günü",
        },
      ];
      final window = ReminderScheduler.ramadanWindowFromEntries(
          noBayram, DateTime(2030, 1, 15));
      expect(window, isNotNull);
      expect(window!.start, DateTime(2030, 1, 10));
      expect(window.end, DateTime(2030, 2, 8));
    });
  });
}
