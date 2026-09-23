import '../../core/i18n/ceviri.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/vakit/kayitli_sehir.dart';
import '../../core/vakit/vakit_tercihi.dart';
import '../hatim/data/hatim_repository.dart';

/// Çevirisi olan uygulama dilleri. `translate` yalnızca İngilizceyi çevirir;
/// çevirisi olmayan bir dil seçtirmek, yazıları Türkçe bırakıp yalnızca yönü
/// değiştirirdi. Yeni bir dil, çevirisiyle birlikte buraya eklenir (sağdan sola
/// yazılan diller için ekranların RTL altyapısı hazırdır).
const desteklenenDiller = ['Türkçe', 'English'];

/// Kayıtlı dil desteklenenler arasında değilse (eskiden seçilen Arapça,
/// Almanca, Fransızca ya da bozuk kayıt) Türkçe.
String gecerliDil(Object? kayit) =>
    desteklenenDiller.contains(kayit) ? kayit as String : 'Türkçe';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // ÖNEMLİ: bu projenin Firestore veritabanının GERÇEK adı "default"
  // (parantezsiz) — `FirebaseFirestore.instance` SDK'nın "(default)" özel
  // adını arar, ki bu projede YOK; sessizce yanlış (var olmayan) veritabanına
  // bağlanır (yazmalar/dinlemeler sonsuza dek "NOT_FOUND" ile yeniden dener,
  // hiçbir zaman hata ya da sonuç vermez). Diğer tüm repository'lerle
  // (Hatim/Hutbe/Kütüphane/Multimedya) AYNI deseni kullan.
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: dotenv.env['FIREBASE_DB_ID'] ?? 'default',
  );
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  User? get user => _user;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _apiKey;
  String? get apiKey => _apiKey;

  void setApiKey(String key) => _apiKey = key;

  final Map<String, dynamic> _guestSettings = {
    'hesaplama_yontemi': 'Diyanet Takvimi',
    'ikindi_hesabi': 'Şafi, Maliki, Hanbeli, Türkiye',
    'ana_sayfa_stili': 'Gökyüzü',
    'uygulama_dili': 'Türkçe',
    'kayitli_sehirler': [KayitliSehir.varsayilan.toMap()],
    'hatirlaticilar': {
      'cuma': {'enabled': true, 'offset': 60, 'sound': 'ezan_kisa'},
      'oruc': {'enabled': true, 'offset': 60, 'sound': 'ezan_kisa'},
      'teheccut': {'enabled': false, 'offset': 45, 'sound': 'ezan_kisa'},
      'ramazan': {'enabled': false, 'offset': 60, 'sound': 'ezan_kisa'},
    },
    'vakit_ezan_ayarlari': {
      'imsak': _varsayilanVakitAyari,
      'sabah': _varsayilanVakitAyari,
      'ogle': _varsayilanVakitAyari,
      'ikindi': _varsayilanVakitAyari,
      'aksam': _varsayilanVakitAyari,
      'yatsi': _varsayilanVakitAyari,
    },
    'vaktinde_kil_ayarlari': {
      'ogle': _varsayilanVaktindeKilAyari,
      'ikindi': _varsayilanVaktindeKilAyari,
      'aksam': _varsayilanVaktindeKilAyari,
      'yatsi': _varsayilanVaktindeKilAyari,
    },
  };

  static const Map<String, dynamic> _varsayilanVakitAyari = {
    'enabled': true,
    'sound': 'ezan_kisa',
    'vaktindeOku': false,
    'onceEnabled': false,
    'onceSound': 'uyari',
    'onceDakika': 45,
    'gunler': [true, true, true, true, true, true, true],
  };

  static const Map<String, dynamic> _varsayilanVaktindeKilAyari = {
    'enabled': true,
    'ilkUyariDakika': 30,
    'sound': 'melodi_19',
    'siklikDakika': 10,
  };

  AuthService() {
    _loadGuestSettings();
    _auth.authStateChanges().listen((User? newUser) {
      _user = newUser;
      if (_user != null) {
        _listenToUserData();
      } else {
        _userDocSubscription?.cancel();
        _userData = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadGuestSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? settingsJson = prefs.getString('guestSettingsData');
      if (settingsJson != null) {
        Map<String, dynamic> loadedSettings = jsonDecode(settingsJson);
        if (loadedSettings['ana_sayfa_stili'] == null ||
            loadedSettings['ana_sayfa_stili'].isEmpty) {
          loadedSettings['ana_sayfa_stili'] = 'Gökyüzü';
          final String newSettingsJson = jsonEncode(loadedSettings);
          await prefs.setString('guestSettingsData', newSettingsJson);
        }
        _guestSettings.addAll(loadedSettings);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Hafıza okuma hatası: $e");
    }
  }

  Future<void> _saveGuestSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String settingsJson = jsonEncode(_guestSettings);
      await prefs.setString('guestSettingsData', settingsJson);
    } catch (e) {
      debugPrint("Hafıza yazma hatası: $e");
    }
  }

  void _listenToUserData() {
    _userDocSubscription?.cancel();
    _userDocSubscription = _firestore
        .collection('users')
        .doc(_user!.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        _userData = snapshot.data();
        notifyListeners();
      }
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // =========================================================
  // ÇEVİRİ: motor `Ceviri` sınıfında (lib/core/i18n/ceviri.dart). Burası yalnız
  // geçerli uygulama dilini verir; eski çağrılar (`translate`) kırılmasın diye
  // kalır. Yeni kodda `context.t(...)` kullanılır.
  // =========================================================
  String translate(String? text) => Ceviri.cevir(text, uygulamaDili);

  // =========================================================
  // GETTERLAR
  // =========================================================

  String get anaSayfaStili {
    String stil = _user != null
        ? (_userData?['ayarlar']?['ana_sayfa_stili'] ?? 'Gökyüzü')
        : (_guestSettings['ana_sayfa_stili'] ?? 'Gökyüzü');
    List<String> gecerliTemalar = [
      'Gökyüzü',
      'Listeli',
      'Dairesel',
      'Analog Saat',
      'Fotoğraflı',
      'Timeline',
      'Dashboard'
    ];
    if (!gecerliTemalar.contains(stil)) return 'Gökyüzü';
    return stil;
  }

  String get uygulamaDili => gecerliDil(_user != null
      ? _userData?['ayarlar']?['uygulama_dili']
      : _guestSettings['uygulama_dili']);
  String get hesaplamaYontemi => _user != null
      ? (_userData?['ayarlar']?['hesaplama_yontemi'] ?? 'Diyanet Takvimi')
      : _guestSettings['hesaplama_yontemi'];
  String get ikindiHesabi => _user != null
      ? (_userData?['ayarlar']?['ikindi_hesabi'] ??
          'Şafi, Maliki, Hanbeli, Türkiye')
      : _guestSettings['ikindi_hesabi'];

  /// Cuma/Oruç/Teheccüt/Ramazan hatırlatıcı ayarları. Depolanmış veri kısmi
  /// olsa bile (ör. eski bir sürümden kalma) her hatırlatıcı türü için
  /// varsayılanlarla birleştirilmiş tam bir map döner.
  Map<String, dynamic> get hatirlaticiAyarlari {
    final defaults =
        Map<String, dynamic>.from(_guestSettings['hatirlaticilar'] as Map);
    final kayitli = _user != null
        ? _userData?['ayarlar']?['hatirlaticilar'] as Map?
        : _guestSettings['hatirlaticilar'] as Map?;
    if (kayitli == null) return defaults;
    return {
      for (final tur in defaults.keys)
        tur: {
          ...Map<String, dynamic>.from(defaults[tur] as Map),
          ...Map<String, dynamic>.from(kayitli[tur] as Map? ?? const {}),
        }
    };
  }

  /// Vakit bazlı ezan alarmı ayarları (İmsak/Sabah/Öğle/İkindi/Akşam/Yatsı).
  /// [hatirlaticiAyarlari] ile aynı varsayılanlarla-birleştirme deseni.
  Map<String, dynamic> get vakitEzanAyarlari {
    final defaults =
        Map<String, dynamic>.from(_guestSettings['vakit_ezan_ayarlari'] as Map);
    final kayitli = _user != null
        ? _userData?['ayarlar']?['vakit_ezan_ayarlari'] as Map?
        : _guestSettings['vakit_ezan_ayarlari'] as Map?;
    if (kayitli == null) return defaults;
    return {
      for (final vakit in defaults.keys)
        vakit: {
          ...Map<String, dynamic>.from(defaults[vakit] as Map),
          ...Map<String, dynamic>.from(kayitli[vakit] as Map? ?? const {}),
        }
    };
  }

  /// "Vaktinde Kıl" hatırlatıcı ayarları (Öğle/İkindi/Akşam/Yatsı).
  Map<String, dynamic> get vaktindeKilAyarlari {
    final defaults = Map<String, dynamic>.from(
        _guestSettings['vaktinde_kil_ayarlari'] as Map);
    final kayitli = _user != null
        ? _userData?['ayarlar']?['vaktinde_kil_ayarlari'] as Map?
        : _guestSettings['vaktinde_kil_ayarlari'] as Map?;
    if (kayitli == null) return defaults;
    return {
      for (final vakit in defaults.keys)
        vakit: {
          ...Map<String, dynamic>.from(defaults[vakit] as Map),
          ...Map<String, dynamic>.from(kayitli[vakit] as Map? ?? const {}),
        }
    };
  }

  static const Map<String, int> _varsayilanTemkinler = {
    "İmsak": 0,
    "Güneş": -7,
    "Öğle": 5,
    "İkindi": 4,
    "Akşam": 7,
    "Yatsı": 0,
  };

  /// Vakit başına dakika cinsinden temkin (ihtiyat payı) değerleri.
  Map<String, int> get temkinDegerleri {
    final raw = _user != null
        ? _userData?['ayarlar']?['temkinler'] as Map?
        : _guestSettings['temkinler'] as Map?;
    if (raw == null) return Map<String, int>.from(_varsayilanTemkinler);
    return {
      for (final key in _varsayilanTemkinler.keys)
        key: (raw[key] as num?)?.toInt() ?? _varsayilanTemkinler[key]!,
    };
  }

  /// "Bildirimleri Ertele" bitiş anı (UTC); ertelenmemişse ya da süre
  /// dolduysa null. Bitiş anı, seçim yapıldığında ayrıca saklanır: etiket
  /// ("2 saat") sürenin ne zaman başladığını taşımaz.
  DateTime? get bildirimErteleBitis {
    final raw = _user != null
        ? _userData?['ayarlar']?['bildirim_ertele_bitis']
        : _guestSettings['bildirim_ertele_bitis'];
    final ms = (raw as num?)?.toInt();
    if (ms == null || ms <= 0) return null;
    final bitis = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    return bitis.isAfter(DateTime.now()) ? bitis : null;
  }

  /// Ayarlar'da görünen durum: süre dolduysa (ya da eskiden kalma, bitişi
  /// bilinmeyen bir seçimse) "Kapalı".
  String get bildirimErteleDurumu {
    final etiket = _user != null
        ? (_userData?['ayarlar']?['bildirim_ertele'] ?? 'Kapalı')
        : (_guestSettings['bildirim_ertele'] ?? 'Kapalı');
    return bildirimErteleBitis == null ? 'Kapalı' : etiket as String;
  }

  /// Kur'an-ı Kerim sayfasında Arapça metin için yazı boyutu (px).
  double get kuranYaziBoyutu {
    final raw = _user != null
        ? _userData?['ayarlar']?['kuran_font_size']
        : _guestSettings['kuran_font_size'];
    return (raw as num?)?.toDouble() ?? 28.0;
  }

  /// Kayıtlı şehirler (Ayarlar > Şehirler). Depolanan biçim [KayitliSehir.toMap]
  /// ile aynıdır (eski kayıtlar aynen okunur); bozuk satırlar atlanır ve tam bir
  /// şehir seçili gelir.
  List<KayitliSehir> get kayitliSehirler => KayitliSehir.listeCoz(_user != null
      ? (_userData?['ayarlar']?['kayitli_sehirler'] ??
          _guestSettings['kayitli_sehirler'])
      : _guestSettings['kayitli_sehirler']);

  KayitliSehir get seciliSehir => kayitliSehirler.seciliOlan;

  Future<void> sehirleriKaydet(List<KayitliSehir> liste) =>
      updateSetting('kayitli_sehirler', [for (final s in liste) s.toMap()]);

  /// Vakit hesabıyla ilgili bütün ayarlar (yöntem, ikindi hesabı, temkin).
  VakitTercihi get vakitTercihi => vakitTercihiIcin(hesaplamaYontemi);

  /// [yontem] adıyla, geri kalan ayarlar (ikindi, temkin) mevcut haliyle
  /// tercih. Şehir önizlemesi, henüz kaydedilmemiş bir yöntemi denemek için
  /// kullanır.
  VakitTercihi vakitTercihiIcin(String yontem) => VakitTercihi.ayarlardan(
        yontem: yontem,
        ikindiHesabi: ikindiHesabi,
        temkin: temkinDegerleri,
        varsayilanTemkin: _varsayilanTemkinler,
      );

  Future<void> updateSetting(String key, dynamic value) async {
    if (_user != null) {
      await _firestore.collection('users').doc(_user!.uid).set({
        'ayarlar': {key: value}
      }, SetOptions(merge: true));
    } else {
      _guestSettings[key] = value;
      await _saveGuestSettings();
      notifyListeners();
    }
  }

  // =========================================================
  // GİRİŞ / ÇIKIŞ İŞLEMLERİ
  // =========================================================

  Future<String?> loginWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password.trim());
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _translateFirebaseError(e.code);
    }
  }

  Future<String?> registerWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password.trim());
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email.trim(),
          'kayit_tarihi': FieldValue.serverTimestamp(),
          'ayarlar': {
            'ana_sayfa_stili': 'Gökyüzü',
            'hesaplama_yontemi': _guestSettings['hesaplama_yontemi'],
            'ikindi_hesabi': _guestSettings['ikindi_hesabi'],
            'uygulama_dili': _guestSettings['uygulama_dili'],
            'kayitli_sehirler': _guestSettings['kayitli_sehirler'],
          }
        });
      }
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _translateFirebaseError(e.code);
    }
  }

  Future<String?> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _translateFirebaseError(e.code);
    }
  }

  Future<String?> signInWithGoogle() async {
    _setLoading(true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return "Google girişi iptal edildi.";
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null &&
          userCredential.additionalUserInfo?.isNewUser == true) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'kayit_tarihi': FieldValue.serverTimestamp(),
          'ayarlar': {
            'ana_sayfa_stili': 'Gökyüzü',
            'hesaplama_yontemi': _guestSettings['hesaplama_yontemi'],
            'ikindi_hesabi': _guestSettings['ikindi_hesabi'],
            'uygulama_dili': _guestSettings['uygulama_dili'],
            'kayitli_sehirler': _guestSettings['kayitli_sehirler'],
          }
        });
      }
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Hesabı ve ayarlarını kalıcı olarak siler (Play'in "hesap silme"
  /// zorunluluğu). Geri alınamaz. Kullanıcının aldığı ama henüz tamamlamadığı
  /// Hatim görevleri önce bırakılır ([HatimRepository.dropTask]): paylaşılan
  /// hatimin sayaçları doğru kalır, görev başkasına açılır. Son girişten uzun
  /// süre geçtiyse Firebase tekrar giriş ister (kod 'requires-recent-login');
  /// kullanıcı normal giriş akışıyla tekrar girip yeniden dener.
  ///
  /// Tamamlanmış Hatim görevlerinde kalan görünen ad (`hatimler/*/assignments`
  /// içindeki `userName`) silinmez (kayıt paylaşılan hatimin tamamlanma
  /// sayısına dahil, silinirse istatistik bozulur); bunun yerine sabit bir
  /// değere anonimleştirilir. Firestore kuralı yalnız bu dar güncellemeye
  /// izin verir (bkz. firestore.rules).
  static const _silinmisKullaniciAdi = 'Silinmiş Kullanıcı';

  Future<String?> deleteAccount() async {
    final u = _auth.currentUser;
    if (u == null) return 'Giriş yapılmamış.';
    _setLoading(true);
    try {
      final gorevler = await _firestore
          .collection('users')
          .doc(u.uid)
          .collection('hatimGorevleri')
          .get();
      final hatimRepo = HatimRepository();
      for (final g in gorevler.docs) {
        final hatimId = g.data()['hatimId']?.toString();
        if (hatimId != null) {
          await hatimRepo.dropTask(
              hatimId: hatimId, itemId: g.id, userId: u.uid);
        }
      }

      // Tamamlanmış görevlerdeki adı anonimleştir. SIRALAMA ÖNEMLİ: bu,
      // Auth hesabı silinmeden ÖNCE olmalı; hesap silindikten sonra oturum
      // geçersiz sayılır ve Firestore kuralı hiçbir yazmaya izin vermez.
      final tamamlananlar = await _firestore
          .collectionGroup('assignments')
          .where('userId', isEqualTo: u.uid)
          .get();
      for (final d in tamamlananlar.docs) {
        if (d.data()['status'] == 'completed') {
          await d.reference.update({'userName': _silinmisKullaniciAdi});
        }
      }

      await _firestore.collection('users').doc(u.uid).delete();
      await _googleSignIn.signOut();
      await u.delete();
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _translateFirebaseError(e.code);
    } catch (e) {
      debugPrint('Hesap silme hatası: $e');
      _setLoading(false);
      return 'Hesap silinemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.';
    }
  }

  String _translateFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return "Hesap bulunamadı.";
      case 'wrong-password':
        return "Şifre hatalı.";
      case 'email-already-in-use':
        return "Bu e-posta zaten kullanımda.";
      // firebase_auth 6.x, kimlik-enumeration'ı önlemek için hem yanlış
      // şifre hem de bilinmeyen hesap durumunda bu kodu döner.
      case 'invalid-credential':
        return "E-posta veya şifre hatalı.";
      case 'invalid-email':
        return "Geçersiz e-posta adresi.";
      case 'user-disabled':
        return "Bu hesap devre dışı bırakılmış.";
      case 'too-many-requests':
        return "Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar deneyin.";
      case 'network-request-failed':
        return "İnternet bağlantınızı kontrol edin.";
      case 'weak-password':
        return "Şifre çok zayıf. En az 6 karakter kullanın.";
      case 'operation-not-allowed':
        return "Bu giriş yöntemi şu anda kullanılamıyor.";
      case 'requires-recent-login':
        return "Bu işlem için tekrar giriş yapmanız gerekiyor.";
      default:
        return "Bir hata oluştu ($code)";
    }
  }
}
