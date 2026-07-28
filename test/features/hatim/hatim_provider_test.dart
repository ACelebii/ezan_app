import 'package:flutter_test/flutter_test.dart';
import 'package:ezan_vakti_uygulamasi/features/hatim/hatim_provider.dart';
import 'package:ezan_vakti_uygulamasi/features/hatim/hatim_model.dart';

HatimModel _buildHatim({required HatimSubItem item}) {
  return HatimModel(
    id: "1",
    date: "01.01.2026",
    participants: 1,
    okunmaYuzdesi: 0,
    paylasilmaYuzdesi: 0,
    tasks: [
      HatimTask(title: "Cüz", availableItems: [item]),
    ],
  );
}

void main() {
  group('HatimProvider', () {
    test('isLoggedIn starts false and notifies listeners on change', () {
      final provider = HatimProvider();
      expect(provider.isLoggedIn, isFalse);

      var notified = false;
      provider.addListener(() => notified = true);
      provider.isLoggedIn = true;

      expect(provider.isLoggedIn, isTrue);
      expect(notified, isTrue);
    });

    test('setActiveTab updates tab and collapses expanded item', () {
      final provider = HatimProvider();
      provider.toggleExpand("42010");
      expect(provider.expandedHatimId, "42010");

      provider.setActiveTab(1);

      expect(provider.activeTab, 1);
      expect(provider.expandedHatimId, isNull);
    });

    test('toggleExpand toggles the same id open and closed', () {
      final provider = HatimProvider();
      provider.toggleExpand("42010");
      expect(provider.expandedHatimId, "42010");

      provider.toggleExpand("42010");
      expect(provider.expandedHatimId, isNull);
    });

    test('currentHatimler returns kuran list on tab 0 and cevsen on tab 1',
        () {
      final provider = HatimProvider();
      expect(provider.currentHatimler, provider.kuranHatimleri);

      provider.setActiveTab(1);
      expect(provider.currentHatimler, provider.cevsenHatimleri);
    });

    test('toggleItem adds an item to myTasks and marks it taken', () {
      final provider = HatimProvider();
      final item = HatimSubItem(id: "c1", title: "1.", subtitle: "Cüz", value: 1);
      final task = HatimTask(title: "Cüz", availableItems: [item]);
      final hatim = _buildHatim(item: item);

      provider.toggleItem(hatim, task, item);

      expect(item.isTaken, isTrue);
      expect(provider.myTasks, hasLength(1));
      expect(provider.myTasks.first.item, item);
    });

    test('toggleItem removes the item from myTasks when taken again', () {
      final provider = HatimProvider();
      final item = HatimSubItem(id: "c1", title: "1.", subtitle: "Cüz", value: 1);
      final task = HatimTask(title: "Cüz", availableItems: [item]);
      final hatim = _buildHatim(item: item);

      provider.toggleItem(hatim, task, item); // al
      provider.toggleItem(hatim, task, item); // bırak

      expect(item.isTaken, isFalse);
      expect(provider.myTasks, isEmpty);
    });

    test('toggleItem clears lastReadTask when its item is dropped', () {
      final provider = HatimProvider();
      final item = HatimSubItem(id: "c1", title: "1.", subtitle: "Cüz", value: 1);
      final task = HatimTask(title: "Cüz", availableItems: [item]);
      final hatim = _buildHatim(item: item);

      provider.toggleItem(hatim, task, item);
      provider.setLastReadTask(provider.myTasks.first);
      expect(provider.lastReadTask, isNotNull);

      provider.toggleItem(hatim, task, item); // bırak
      expect(provider.lastReadTask, isNull);
    });

    test('completeTask marks item completed and removes it from myTasks', () {
      final provider = HatimProvider();
      final item = HatimSubItem(id: "c1", title: "1.", subtitle: "Cüz", value: 1);
      final task = HatimTask(title: "Cüz", availableItems: [item]);
      final hatim = _buildHatim(item: item);
      provider.toggleItem(hatim, task, item);
      final myTask = provider.myTasks.first;

      provider.completeTask(myTask);

      expect(item.isCompleted, isTrue);
      expect(provider.myTasks, isEmpty);
    });

    test('dropTask marks item not taken and removes it from myTasks', () {
      final provider = HatimProvider();
      final item = HatimSubItem(id: "c1", title: "1.", subtitle: "Cüz", value: 1);
      final task = HatimTask(title: "Cüz", availableItems: [item]);
      final hatim = _buildHatim(item: item);
      provider.toggleItem(hatim, task, item);
      final myTask = provider.myTasks.first;

      provider.dropTask(myTask);

      expect(item.isTaken, isFalse);
      expect(provider.myTasks, isEmpty);
    });
  });
}
