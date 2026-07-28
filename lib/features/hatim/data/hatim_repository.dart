// lib/features/hatim/data/hatim_repository.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/repositories/base_repository.dart';
import '../hatim_model.dart';

/// Firestore şeması:
///   hatimler/{hatimId}                        -> özet sayaçlar (totalItems/takenItems/completedItems/participants)
///   hatimler/{hatimId}/assignments/{itemId}   -> Cüz/Sayfa/Sure görevi (type/value/title/subtitle/status/userId)
///   users/{uid}/hatimGorevleri/{itemId}       -> "myTasks" için minimal mirror doküman
class HatimRepository extends BaseRepository<List<HatimModel>> {
  static const String _cacheKey = 'hatimler_cache';

  FirebaseFirestore get _db => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: dotenv.env['FIREBASE_DB_ID'] ?? 'default',
      );

  // --- Özet liste (BaseRepository: remote + cache) ---

  @override
  Future<List<HatimModel>> fetchFromRemote() async {
    try {
      final snapshot = await _db
          .collection('hatimler')
          .get(const GetOptions(source: Source.server));
      return snapshot.docs
          .map((doc) => HatimModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Hatimler yüklenemedi: $e");
    }
  }

  @override
  Future<List<HatimModel>?> fetchFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(_cacheKey);
    if (cachedData == null) return null;
    final data = json.decode(cachedData) as List;
    return data
        .map((e) => HatimModel.fromCacheJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveToCache(List<HatimModel> data) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(data.map((h) => h.toCacheJson()).toList());
    await prefs.setString(_cacheKey, encoded);
  }

  // --- Canlı dinleme ---

  /// Genişletilen bir hatimin görev/durum listesini canlı dinler.
  Stream<List<HatimSubItem>> watchAssignments(String hatimId) {
    return _db
        .collection('hatimler')
        .doc(hatimId)
        .collection('assignments')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => HatimSubItem.fromFirestore(d.id, d.data()))
            .toList());
  }

  /// Giriş yapmış kullanıcının aldığı görevleri canlı dinler.
  Stream<List<MyHatimTask>> watchMyTasks(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('hatimGorevleri')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MyHatimTask.fromFirestore(d.id, d.data()))
            .toList());
  }

  // --- Yazma işlemleri (transaction ile atomik) ---

  /// Görevi al (available -> taken) veya kendi aldığın görevi bırak (taken -> available).
  Future<void> toggleItem({
    required String hatimId,
    required HatimSubItem item,
    required String userId,
    required String userName,
  }) async {
    final assignmentRef = _db
        .collection('hatimler')
        .doc(hatimId)
        .collection('assignments')
        .doc(item.id);
    final mirrorRef =
        _db.collection('users').doc(userId).collection('hatimGorevleri').doc(item.id);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(assignmentRef);
      final status = snap.data()?['status']?.toString() ?? 'available';
      final ownerId = snap.data()?['userId']?.toString();

      if (status == 'available') {
        tx.update(assignmentRef, {
          'status': 'taken',
          'userId': userId,
          'userName': userName,
          'takenAt': FieldValue.serverTimestamp(),
        });
        tx.set(mirrorRef, {
          'hatimId': hatimId,
          'taskTitle': item.type,
          'title': item.title,
          'subtitle': item.subtitle,
          'value': item.value,
          'takenAt': FieldValue.serverTimestamp(),
        });
      } else if (status == 'taken' && ownerId == userId) {
        tx.update(assignmentRef, {
          'status': 'available',
          'userId': FieldValue.delete(),
          'userName': FieldValue.delete(),
          'takenAt': FieldValue.delete(),
        });
        tx.delete(mirrorRef);
      }
      // Başkası tarafından alınmışsa veya zaten tamamlanmışsa: sessizce yok say.
      // (Firestore rules aynı durumu sunucu tarafında da reddedecek.)
    });

    await _recomputeHatimStats(hatimId);
  }

  /// Kullanıcının kendi görevini "okudum" olarak işaretler.
  Future<void> completeTask({
    required String hatimId,
    required String itemId,
    required String userId,
  }) async {
    final assignmentRef = _db
        .collection('hatimler')
        .doc(hatimId)
        .collection('assignments')
        .doc(itemId);
    final mirrorRef =
        _db.collection('users').doc(userId).collection('hatimGorevleri').doc(itemId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(assignmentRef);
      if (snap.data()?['userId']?.toString() != userId) return;
      tx.update(assignmentRef, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      tx.delete(mirrorRef);
    });

    await _recomputeHatimStats(hatimId);
  }

  /// Kullanıcının kendi görevinden vazgeçmesi (havuza geri döner).
  Future<void> dropTask({
    required String hatimId,
    required String itemId,
    required String userId,
  }) async {
    final assignmentRef = _db
        .collection('hatimler')
        .doc(hatimId)
        .collection('assignments')
        .doc(itemId);
    final mirrorRef =
        _db.collection('users').doc(userId).collection('hatimGorevleri').doc(itemId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(assignmentRef);
      if (snap.data()?['userId']?.toString() != userId) return;
      tx.update(assignmentRef, {
        'status': 'available',
        'userId': FieldValue.delete(),
        'userName': FieldValue.delete(),
        'takenAt': FieldValue.delete(),
      });
      tx.delete(mirrorRef);
    });

    await _recomputeHatimStats(hatimId);
  }

  /// Bir hatimin totalItems/takenItems/completedItems/participants sayaçlarını
  /// assignments alt koleksiyonundan yeniden hesaplayıp özet dokümana yazar.
  /// Cloud Functions olmadığı için bu istemci tarafında, her yazmadan sonra
  /// best-effort olarak yapılıyor (kısa süreliğine hafif tutarsız olabilir,
  /// bir sonraki yazmada kendini düzeltir).
  Future<void> _recomputeHatimStats(String hatimId) async {
    final assignmentsSnap = await _db
        .collection('hatimler')
        .doc(hatimId)
        .collection('assignments')
        .get();

    int taken = 0;
    int completed = 0;
    final participantIds = <String>{};
    for (final doc in assignmentsSnap.docs) {
      final data = doc.data();
      final status = data['status']?.toString() ?? 'available';
      final userId = data['userId']?.toString();
      if (status == 'taken') taken++;
      if (status == 'completed') {
        completed++;
        taken++;
      }
      if (userId != null && userId.isNotEmpty) participantIds.add(userId);
    }

    await _db.collection('hatimler').doc(hatimId).update({
      'totalItems': assignmentsSnap.docs.length,
      'takenItems': taken,
      'completedItems': completed,
      'participants': participantIds.length,
    });
  }
}
