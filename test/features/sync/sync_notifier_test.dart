import 'package:flutter_test/flutter_test.dart';
import 'package:ezan_vakti_uygulamasi/features/sync/sync_notifier.dart';

void main() {
  group('SyncNotifier', () {
    test('starts idle with no error message', () {
      final notifier = SyncNotifier();

      expect(notifier.state, SyncState.idle);
      expect(notifier.errorMessage, isNull);
    });

    test('setSyncing moves state to syncing and notifies', () {
      final notifier = SyncNotifier();
      var notified = false;
      notifier.addListener(() => notified = true);

      notifier.setSyncing();

      expect(notifier.state, SyncState.syncing);
      expect(notified, isTrue);
    });

    test('setError moves state to error and records the message', () {
      final notifier = SyncNotifier();

      notifier.setError('Sunucuya ulaşılamadı');

      expect(notifier.state, SyncState.error);
      expect(notifier.errorMessage, 'Sunucuya ulaşılamadı');
    });

    test('setSuccess moves state to success then resets to idle after a delay',
        () async {
      final notifier = SyncNotifier();

      notifier.setSuccess();
      expect(notifier.state, SyncState.success);

      await Future.delayed(const Duration(seconds: 2, milliseconds: 200));

      expect(notifier.state, SyncState.idle);
    });
  });
}
