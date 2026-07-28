// lib/features/hatim/hatim_model.dart

class HatimSubItem {
  final String id;
  final String title;
  final String subtitle;
  final int value;
  bool isTaken;
  bool isCompleted; // YENİ: Görev başarıyla bitirildi mi?

  HatimSubItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.value,
    this.isTaken = false,
    this.isCompleted = false,
  });
}

class HatimTask {
  final String title;
  final bool isLocked;
  final List<HatimSubItem> availableItems;

  HatimTask({
    required this.title,
    required this.availableItems,
    this.isLocked = false,
  });

  int get availableCount =>
      availableItems.where((item) => !item.isTaken).length;
}

class HatimModel {
  final String id;
  final String date;
  final int participants;
  final int okunmaYuzdesi;
  final int paylasilmaYuzdesi;
  final List<HatimTask> tasks;

  HatimModel({
    required this.id,
    required this.date,
    required this.participants,
    required this.okunmaYuzdesi,
    required this.paylasilmaYuzdesi,
    required this.tasks,
  });
}

// YENİ: Kullanıcının aldığı görevleri tutan model
class MyTask {
  final HatimModel hatim;
  final HatimTask taskType;
  final HatimSubItem item;
  final String timeLeft;
  final DateTime takenAt;

  MyTask({
    required this.hatim,
    required this.taskType,
    required this.item,
    required this.timeLeft,
    required this.takenAt,
  });
}
