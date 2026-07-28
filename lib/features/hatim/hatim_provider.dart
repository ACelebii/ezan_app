import 'dart:async';
import 'package:flutter/material.dart';
import '../../locator.dart';
import 'hatim_model.dart';
import 'data/hatim_repository.dart';

class HatimProvider extends ChangeNotifier {
  final HatimRepository _repo;

  HatimProvider({HatimRepository? repository})
      : _repo = repository ?? locator<HatimRepository>() {
    _loadHatimler();
  }

  int _activeTab = 0;
  int get activeTab => _activeTab;

  String? _expandedHatimId;
  String? get expandedHatimId => _expandedHatimId;

  bool isHatimlerLoading = true;
  String? errorMessage;
  List<HatimModel> kuranHatimleri = [];
  final List<HatimModel> cevsenHatimleri = []; // Cevşen için Firestore verisi henüz yok

  List<HatimModel> get currentHatimler =>
      _activeTab == 0 ? kuranHatimleri : cevsenHatimleri;

  // --- GÖREVLERİM YÖNETİMİ (users/{uid}/hatimGorevleri canlı dinlemesi) ---
  List<MyHatimTask> myTasks = [];
  MyHatimTask? lastReadTask;
  DateTime? lastReadAt;

  StreamSubscription<List<HatimSubItem>>? _assignmentsSub;
  StreamSubscription<List<MyHatimTask>>? _myTasksSub;
  String? _currentUid;

  Future<void> _loadHatimler() async {
    isHatimlerLoading = true;
    notifyListeners();
    try {
      kuranHatimleri = await _repo.getData();
      errorMessage = null;
    } catch (e) {
      errorMessage = "Hatimler yüklenemedi: $e";
    }
    isHatimlerLoading = false;
    notifyListeners();
  }

  /// Pull-to-refresh: cache'i atlayıp doğrudan sunucudan çeker.
  Future<void> refresh() async {
    try {
      final remote = await _repo.fetchFromRemote();
      await _repo.saveToCache(remote);
      kuranHatimleri = remote;
      errorMessage = null;
    } catch (e) {
      errorMessage = "Hatimler yenilenemedi: $e";
    }
    notifyListeners();
  }

  void setActiveTab(int index) {
    _activeTab = index;
    _collapseExpanded();
    notifyListeners();
  }

  void toggleExpand(String id) {
    if (_expandedHatimId == id) {
      _collapseExpanded();
    } else {
      _expandedHatimId = id;
      _listenAssignments(id);
    }
    notifyListeners();
  }

  void _collapseExpanded() {
    _expandedHatimId = null;
    _assignmentsSub?.cancel();
    _assignmentsSub = null;
  }

  void _listenAssignments(String hatimId) {
    _assignmentsSub?.cancel();
    _assignmentsSub = _repo.watchAssignments(hatimId).listen((items) {
      _applyAssignments(hatimId, items);
    });
  }

  void _applyAssignments(String hatimId, List<HatimSubItem> items) {
    final idx = kuranHatimleri.indexWhere((h) => h.id == hatimId);
    if (idx == -1) return;

    final grouped = <String, List<HatimSubItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.type, () => []).add(item);
    }
    final tasks = grouped.entries
        .map((e) => HatimTask(title: e.key, availableItems: e.value))
        .toList();

    kuranHatimleri[idx] = kuranHatimleri[idx].withTasks(tasks);
    notifyListeners();
  }

  /// Bir hatimi (genişletilmiş olsun ya da olmasın) id'sine göre bulur.
  HatimModel? findHatim(String hatimId) {
    for (final h in [...kuranHatimleri, ...cevsenHatimleri]) {
      if (h.id == hatimId) return h;
    }
    return null;
  }

  /// Kullanıcının giriş/çıkış durumu değiştikçe (bkz. main.dart'taki
  /// ChangeNotifierProxyProvider bağlaması) "myTasks" canlı dinlemesini
  /// başlatır/durdurur.
  void onAuthChanged(String? uid) {
    if (uid == _currentUid) return;
    _currentUid = uid;

    _myTasksSub?.cancel();
    _myTasksSub = null;
    myTasks = [];
    lastReadTask = null;
    lastReadAt = null;

    if (uid != null) {
      _myTasksSub = _repo.watchMyTasks(uid).listen((tasks) {
        myTasks = tasks;
        if (lastReadTask != null &&
            !tasks.any((t) => t.itemId == lastReadTask!.itemId)) {
          lastReadTask = null;
          lastReadAt = null;
        }
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void setLastReadTask(MyHatimTask task) {
    lastReadTask = task;
    lastReadAt = DateTime.now();
    notifyListeners();
  }

  Future<void> toggleItem(
    HatimModel hatim,
    HatimTask task,
    HatimSubItem item, {
    required String userId,
    required String userName,
  }) {
    return _repo.toggleItem(
      hatimId: hatim.id,
      item: item,
      userId: userId,
      userName: userName,
    );
  }

  Future<void> completeTask(MyHatimTask task, String userId) {
    if (lastReadTask?.itemId == task.itemId) {
      lastReadTask = null;
      lastReadAt = null;
    }
    return _repo.completeTask(
      hatimId: task.hatimId,
      itemId: task.itemId,
      userId: userId,
    );
  }

  Future<void> dropTask(MyHatimTask task, String userId) {
    if (lastReadTask?.itemId == task.itemId) {
      lastReadTask = null;
      lastReadAt = null;
    }
    return _repo.dropTask(
      hatimId: task.hatimId,
      itemId: task.itemId,
      userId: userId,
    );
  }

  @override
  void dispose() {
    _assignmentsSub?.cancel();
    _myTasksSub?.cancel();
    super.dispose();
  }
}
