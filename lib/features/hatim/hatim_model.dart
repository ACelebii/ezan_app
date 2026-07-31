// lib/features/hatim/hatim_model.dart

/// Firestore'daki `hatimler/{hatimId}/assignments/{itemId}` dokümanını temsil eder.
/// Immutable: her Firestore snapshot'ı yeni bir nesne üretir, mevcut nesneler
/// mutate edilmez (bkz. eski HatimSubItem'daki paylaşılan-referans sorunu).
class HatimSubItem {
  final String id;
  final String title;
  final String subtitle;
  final int value;
  final String type; // Ait olduğu HatimTask.title ile eşleşir ("Cüz"/"Sayfa"/"Sure")
  final String status; // "available" | "taken" | "completed"
  final String? userId;

  const HatimSubItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.type,
    this.status = "available",
    this.userId,
  });

  bool get isTaken => status == "taken" || status == "completed";
  bool get isCompleted => status == "completed";

  factory HatimSubItem.fromFirestore(String id, Map<String, dynamic> data) {
    return HatimSubItem(
      id: id,
      title: data['title']?.toString() ?? '',
      subtitle: data['subtitle']?.toString() ?? '',
      value: (data['value'] as num?)?.toInt() ?? 0,
      type: data['type']?.toString() ?? '',
      status: data['status']?.toString() ?? 'available',
      userId: data['userId']?.toString(),
    );
  }
}

class HatimTask {
  final String title;
  final bool isLocked;
  final List<HatimSubItem> availableItems;

  const HatimTask({
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

  const HatimModel({
    required this.id,
    required this.date,
    required this.participants,
    required this.okunmaYuzdesi,
    required this.paylasilmaYuzdesi,
    required this.tasks,
    });

  /// `hatimler/{id}` özet dokümanından oluşturur. `tasks` başlangıçta boştur;
  /// ilgili hatim genişletildiğinde `assignments` alt koleksiyonundan
  /// canlı olarak doldurulur (bkz. HatimProvider._applyAssignments).
  factory HatimModel.fromFirestore(String id, Map<String, dynamic> data) {
    final total = (data['totalItems'] as num?)?.toInt() ?? 0;
    final completed = (data['completedItems'] as num?)?.toInt() ?? 0;
    final taken = (data['takenItems'] as num?)?.toInt() ?? 0;
    return HatimModel(
      id: id,
      date: data['date']?.toString() ?? '',
      participants: (data['participants'] as num?)?.toInt() ?? 0,
      okunmaYuzdesi: total == 0 ? 0 : ((completed / total) * 100).round(),
      paylasilmaYuzdesi: total == 0 ? 0 : ((taken / total) * 100).round(),
      tasks: const [],
    );
  }

  /// Sadece özet alanları (tasks hariç) SharedPreferences cache'i için.
  Map<String, dynamic> toCacheJson() => {
        'id': id,
        'date': date,
        'participants': participants,
        'okunmaYuzdesi': okunmaYuzdesi,
        'paylasilmaYuzdesi': paylasilmaYuzdesi,
      };

  factory HatimModel.fromCacheJson(Map<String, dynamic> json) => HatimModel(
        id: json['id'].toString(),
        date: json['date']?.toString() ?? '',
        participants: (json['participants'] as num?)?.toInt() ?? 0,
        okunmaYuzdesi: (json['okunmaYuzdesi'] as num?)?.toInt() ?? 0,
        paylasilmaYuzdesi: (json['paylasilmaYuzdesi'] as num?)?.toInt() ?? 0,
        tasks: const [],
      );
}

/// Kullanıcının aldığı bir görevi temsil eder. `users/{uid}/hatimGorevleri/{itemId}`
/// mirror dokümanından üretilir — nesne referansı değil, düz alanlar taşır.
class MyHatimTask {
  final String hatimId;
  final String taskTitle; // "Cüz" | "Sayfa" | "Sure"
  final String itemId;
  final String title;
  final String subtitle;
  final int value;
  final DateTime takenAt;

  const MyHatimTask({
    required this.hatimId,
    required this.taskTitle,
    required this.itemId,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.takenAt,
  });

  factory MyHatimTask.fromFirestore(String itemId, Map<String, dynamic> data) {
    return MyHatimTask(
      hatimId: data['hatimId']?.toString() ?? '',
      taskTitle: data['taskTitle']?.toString() ?? '',
      itemId: itemId,
      title: data['title']?.toString() ?? '',
      subtitle: data['subtitle']?.toString() ?? '',
      value: (data['value'] as num?)?.toInt() ?? 0,
      takenAt: (data['takenAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}
