import 'package:flutter/material.dart';
import 'hatim_model.dart';

class HatimProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  set isLoggedIn(bool value) {
    _isLoggedIn = value;
    notifyListeners();
  }

  int _activeTab = 0;
  int get activeTab => _activeTab;

  String? _expandedHatimId;
  String? get expandedHatimId => _expandedHatimId;

  // --- GÖREVLERİM YÖNETİMİ ---
  List<MyTask> myTasks = [];
  MyTask? lastReadTask;

  void setActiveTab(int index) {
    _activeTab = index;
    _expandedHatimId = null;
    notifyListeners();
  }

  void toggleExpand(String id) {
    _expandedHatimId = (_expandedHatimId == id) ? null : id;
    notifyListeners();
  }

  // --- YENİ: GÖREVİ AL VEYA BIRAK (TOGGLE MANTIĞI) ---
  void toggleItem(HatimModel hatim, HatimTask task, HatimSubItem item) {
    if (item.isTaken) {
      // Zaten alınmışsa bırak (Sepetten çıkar)
      item.isTaken = false;
      myTasks.removeWhere((t) => t.item.id == item.id);
      if (lastReadTask?.item.id == item.id) {
        lastReadTask = null;
      }
    } else {
      // Alınmamışsa al (Sepete ekle)
      item.isTaken = true;
      myTasks.add(MyTask(
        hatim: hatim,
        taskType: task,
        item: item,
        timeLeft: "14 Gün",
        takenAt: DateTime.now(),
      ));
    }
    notifyListeners();
  }

  // Son kalınan yeri güncelle
  void setLastReadTask(MyTask task) {
    lastReadTask = task;
    notifyListeners();
  }

  // Tek Bir Görevi "Okudum" Olarak İşaretle
  void completeTask(MyTask task) {
    task.item.isCompleted = true;
    myTasks.remove(task);
    if (lastReadTask == task) {
      lastReadTask = null;
    }
    notifyListeners();
  }

  // Tek Bir Görevi "Vazgeç" Diyerek İptal Et
  void dropTask(MyTask task) {
    task.item.isTaken = false;
    myTasks.remove(task);
    if (lastReadTask == task) {
      lastReadTask = null;
    }
    notifyListeners();
  }

  void completeTasks(Set<MyTask> completedTasks) {
    for (var task in completedTasks) {
      task.item.isCompleted = true;
      myTasks.remove(task);
    }
    notifyListeners();
  }

  void dropTasks(Set<MyTask> droppedTasks) {
    for (var task in droppedTasks) {
      task.item.isTaken = false;
      myTasks.remove(task);
    }
    notifyListeners();
  }

  // --- MEVCUT ÖRNEK VERİLER ---
  final List<HatimModel> kuranHatimleri = [
    HatimModel(
      id: "42010",
      date: "06.04.2026",
      participants: 70,
      okunmaYuzdesi: 74,
      paylasilmaYuzdesi: 80,
      tasks: [
        HatimTask(title: "Cüz", availableItems: [
          HatimSubItem(id: "c1", title: "1.", subtitle: "Cüz", value: 1),
          HatimSubItem(id: "c2", title: "2.", subtitle: "Cüz", value: 2),
        ]),
        HatimTask(title: "Sayfa", availableItems: [
          HatimSubItem(
              id: "p455", title: "455.", subtitle: "Sayfa", value: 455),
          HatimSubItem(
              id: "p456", title: "456.", subtitle: "Sayfa", value: 456),
          HatimSubItem(
              id: "p213", title: "213.", subtitle: "Sayfa", value: 213),
          HatimSubItem(
              id: "p228", title: "228.", subtitle: "Sayfa", value: 228),
        ]),
        HatimTask(title: "Sure", availableItems: [
          HatimSubItem(
              id: "s36", title: "Yâsîn", subtitle: "Suresi", value: 36),
          HatimSubItem(id: "s38", title: "Sâd", subtitle: "Suresi", value: 38),
        ]),
      ],
    ),
  ];

  final List<HatimModel> cevsenHatimleri = [];

  List<HatimModel> get currentHatimler =>
      _activeTab == 0 ? kuranHatimleri : cevsenHatimleri;
}
