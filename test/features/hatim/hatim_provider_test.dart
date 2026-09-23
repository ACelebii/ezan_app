import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezan_vakti_uygulamasi/features/hatim/hatim_provider.dart';
import 'package:ezan_vakti_uygulamasi/features/hatim/hatim_model.dart';
import 'package:ezan_vakti_uygulamasi/features/hatim/data/hatim_repository.dart';

/// Gerçek Firestore'a hiç dokunmayan, bellek-içi sahte repository.
/// HatimRepository'nin tüm public metotlarını override eder; `_db` hiç
/// çağrılmaz.
class _FakeHatimRepository extends HatimRepository {
  _FakeHatimRepository(this._summaries, this._assignments);

  final List<HatimModel> _summaries;
  final Map<String, List<HatimSubItem>> _assignments;
  final Map<String, StreamController<List<HatimSubItem>>>
      _assignmentControllers = {};
  final StreamController<List<MyHatimTask>> _myTasksController =
      StreamController<List<MyHatimTask>>.broadcast();
  List<MyHatimTask> _myTasks = [];

  void _emitAssignments(String hatimId) {
    _assignmentControllers[hatimId]
        ?.add(List.of(_assignments[hatimId] ?? const []));
  }

  void _emitMyTasks() => _myTasksController.add(List.of(_myTasks));

  @override
  Future<List<HatimModel>> fetchFromRemote() async => _summaries;

  @override
  Future<List<HatimModel>?> fetchFromCache() async => null;

  @override
  Future<void> saveToCache(List<HatimModel> data) async {}

  @override
  Stream<List<HatimSubItem>> watchAssignments(String hatimId) {
    final controller = _assignmentControllers.putIfAbsent(
        hatimId, () => StreamController<List<HatimSubItem>>.broadcast());
    scheduleMicrotask(() => _emitAssignments(hatimId));
    return controller.stream;
  }

  @override
  Stream<List<MyHatimTask>> watchMyTasks(String uid) {
    scheduleMicrotask(_emitMyTasks);
    return _myTasksController.stream;
  }

  @override
  Future<HatimToggleResult> toggleItem({
    required String hatimId,
    required HatimSubItem item,
    required String userId,
    required String userName,
  }) async {
    final items = _assignments[hatimId];
    if (items == null) return HatimToggleResult.conflict;
    final idx = items.indexWhere((i) => i.id == item.id);
    if (idx == -1) return HatimToggleResult.conflict;
    final current = items[idx];

    HatimToggleResult result;
    if (current.status == 'available') {
      items[idx] = HatimSubItem(
        id: current.id,
        title: current.title,
        subtitle: current.subtitle,
        value: current.value,
        type: current.type,
        status: 'taken',
        userId: userId,
      );
      _myTasks = [
        ..._myTasks,
        MyHatimTask(
          hatimId: hatimId,
          taskTitle: current.type,
          itemId: current.id,
          title: current.title,
          subtitle: current.subtitle,
          value: current.value,
          takenAt: DateTime.now(),
        ),
      ];
      result = HatimToggleResult.taken;
    } else if (current.status == 'taken' && current.userId == userId) {
      items[idx] = HatimSubItem(
        id: current.id,
        title: current.title,
        subtitle: current.subtitle,
        value: current.value,
        type: current.type,
      );
      _myTasks = _myTasks.where((t) => t.itemId != current.id).toList();
      result = HatimToggleResult.released;
    } else {
      result = HatimToggleResult.conflict;
    }

    _emitAssignments(hatimId);
    _emitMyTasks();
    return result;
  }

  @override
  Future<void> completeTask({
    required String hatimId,
    required String itemId,
    required String userId,
  }) async {
    final items = _assignments[hatimId];
    if (items == null) return;
    final idx = items.indexWhere((i) => i.id == itemId);
    if (idx == -1 || items[idx].userId != userId) return;
    final current = items[idx];
    items[idx] = HatimSubItem(
      id: current.id,
      title: current.title,
      subtitle: current.subtitle,
      value: current.value,
      type: current.type,
      status: 'completed',
      userId: userId,
    );
    _myTasks = _myTasks.where((t) => t.itemId != itemId).toList();
    _emitAssignments(hatimId);
    _emitMyTasks();
  }

  @override
  Future<void> dropTask({
    required String hatimId,
    required String itemId,
    required String userId,
  }) async {
    final items = _assignments[hatimId];
    if (items == null) return;
    final idx = items.indexWhere((i) => i.id == itemId);
    if (idx == -1 || items[idx].userId != userId) return;
    final current = items[idx];
    items[idx] = HatimSubItem(
      id: current.id,
      title: current.title,
      subtitle: current.subtitle,
      value: current.value,
      type: current.type,
    );
    _myTasks = _myTasks.where((t) => t.itemId != itemId).toList();
    _emitAssignments(hatimId);
    _emitMyTasks();
  }
}

HatimSubItem _item(String id, {String type = "Cüz"}) =>
    HatimSubItem(id: id, title: "1.", subtitle: type, value: 1, type: type);

Future<void> _settle() => Future.delayed(Duration.zero);

void main() {
  group('HatimProvider', () {
    late _FakeHatimRepository repo;

    setUp(() {
      const hatim = HatimModel(
        id: "42010",
        date: "06.04.2026",
        participants: 0,
        okunmaYuzdesi: 0,
        paylasilmaYuzdesi: 0,
        tasks: [],
      );
      repo = _FakeHatimRepository([
        hatim
      ], {
        "42010": [_item("c1")],
      });
    });

    test('loads hatim summaries on construction', () async {
      final provider = HatimProvider(repository: repo);
      await _settle();

      expect(provider.isHatimlerLoading, isFalse);
      expect(provider.kuranHatimleri, hasLength(1));
      expect(provider.kuranHatimleri.first.id, "42010");
    });

    test('setActiveTab updates tab and collapses expanded item', () async {
      final provider = HatimProvider(repository: repo);
      await _settle();

      provider.toggleExpand("42010");
      expect(provider.expandedHatimId, "42010");

      provider.setActiveTab(1);

      expect(provider.activeTab, 1);
      expect(provider.expandedHatimId, isNull);
    });

    test('toggleExpand toggles the same id open and closed', () async {
      final provider = HatimProvider(repository: repo);
      await _settle();

      provider.toggleExpand("42010");
      expect(provider.expandedHatimId, "42010");

      provider.toggleExpand("42010");
      expect(provider.expandedHatimId, isNull);
    });

    test('toggleExpand starts listening and populates tasks from assignments',
        () async {
      final provider = HatimProvider(repository: repo);
      await _settle();

      provider.toggleExpand("42010");
      await _settle();

      final loaded = provider.findHatim("42010")!;
      expect(loaded.tasks, hasLength(1));
      expect(loaded.tasks.first.title, "Cüz");
      expect(loaded.tasks.first.availableItems.first.id, "c1");
    });

    test('toggleItem takes an item and reflects it in myTasks', () async {
      final provider = HatimProvider(repository: repo);
      provider.onAuthChanged("user1");
      await _settle();
      provider.toggleExpand("42010");
      await _settle();

      final loaded = provider.findHatim("42010")!;
      final task = loaded.tasks.first;
      final item = task.availableItems.first;

      await provider.toggleItem(loaded, task, item,
          userId: "user1", userName: "Test User");
      await _settle();

      expect(provider.myTasks, hasLength(1));
      expect(provider.myTasks.first.itemId, "c1");

      final updated = provider.findHatim("42010")!;
      expect(updated.tasks.first.availableItems.first.isTaken, isTrue);
    });

    test('toggleItem drops an already-taken item', () async {
      final provider = HatimProvider(repository: repo);
      provider.onAuthChanged("user1");
      await _settle();
      provider.toggleExpand("42010");
      await _settle();

      var loaded = provider.findHatim("42010")!;
      await provider.toggleItem(
          loaded, loaded.tasks.first, loaded.tasks.first.availableItems.first,
          userId: "user1", userName: "Test User");
      await _settle();

      loaded = provider.findHatim("42010")!;
      await provider.toggleItem(
          loaded, loaded.tasks.first, loaded.tasks.first.availableItems.first,
          userId: "user1", userName: "Test User");
      await _settle();

      expect(provider.myTasks, isEmpty);
      final updated = provider.findHatim("42010")!;
      expect(updated.tasks.first.availableItems.first.isTaken, isFalse);
    });

    test('completeTask removes the task from myTasks and marks it completed',
        () async {
      final provider = HatimProvider(repository: repo);
      provider.onAuthChanged("user1");
      await _settle();
      provider.toggleExpand("42010");
      await _settle();

      final loaded = provider.findHatim("42010")!;
      await provider.toggleItem(
          loaded, loaded.tasks.first, loaded.tasks.first.availableItems.first,
          userId: "user1", userName: "Test User");
      await _settle();

      final myTask = provider.myTasks.first;
      await provider.completeTask(myTask, "user1");
      await _settle();

      expect(provider.myTasks, isEmpty);
      final updated = provider.findHatim("42010")!;
      expect(updated.tasks.first.availableItems.first.isCompleted, isTrue);
    });

    test('dropTask returns the item to available and clears myTasks', () async {
      final provider = HatimProvider(repository: repo);
      provider.onAuthChanged("user1");
      await _settle();
      provider.toggleExpand("42010");
      await _settle();

      final loaded = provider.findHatim("42010")!;
      await provider.toggleItem(
          loaded, loaded.tasks.first, loaded.tasks.first.availableItems.first,
          userId: "user1", userName: "Test User");
      await _settle();

      final myTask = provider.myTasks.first;
      await provider.dropTask(myTask, "user1");
      await _settle();

      expect(provider.myTasks, isEmpty);
      final updated = provider.findHatim("42010")!;
      expect(updated.tasks.first.availableItems.first.isTaken, isFalse);
    });

    test('toggleItem clears lastReadTask when its item is dropped', () async {
      final provider = HatimProvider(repository: repo);
      provider.onAuthChanged("user1");
      await _settle();
      provider.toggleExpand("42010");
      await _settle();

      final loaded = provider.findHatim("42010")!;
      await provider.toggleItem(
          loaded, loaded.tasks.first, loaded.tasks.first.availableItems.first,
          userId: "user1", userName: "Test User");
      await _settle();

      provider.setLastReadTask(provider.myTasks.first);
      expect(provider.lastReadTask, isNotNull);

      await provider.dropTask(provider.myTasks.first, "user1");
      await _settle();

      expect(provider.lastReadTask, isNull);
    });

    test('onAuthChanged clears myTasks and stops listening on logout',
        () async {
      final provider = HatimProvider(repository: repo);
      provider.onAuthChanged("user1");
      await _settle();
      provider.toggleExpand("42010");
      await _settle();

      final loaded = provider.findHatim("42010")!;
      await provider.toggleItem(
          loaded, loaded.tasks.first, loaded.tasks.first.availableItems.first,
          userId: "user1", userName: "Test User");
      await _settle();
      expect(provider.myTasks, hasLength(1));

      provider.onAuthChanged(null);
      expect(provider.myTasks, isEmpty);
    });
  });
}
