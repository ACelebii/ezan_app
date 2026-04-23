import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  Future<void> cachePrayerTimes(String city, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_vakitler_$city', jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getCachedPrayerTimes(String city) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('cached_vakitler_$city');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  final Map<String, dynamic> _guestSettings = {
    'hesaplama_yontemi': 'Diyanet Takvimi',
    'ikindi_hesabi': 'Şafi, Maliki, Hanbeli, Türkiye',
    'ana_sayfa_stili': 'Listeli',
    'uygulama_dili': 'Türkçe',
    'kayitli_sehirler': [
      {
        'isim': 'İstanbul',
        'sehir': 'Türkiye',
        'lat': 41.0082,
        'lon': 28.9784,
        'secili': 'true'
      }
    ],
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
          loadedSettings['ana_sayfa_stili'] = 'Listeli';
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
  // SADELEŞTİRİLMİŞ ÇEVİRİ MOTORU (SADECE TÜRKÇE & İNGİLİZCE)
  // =========================================================
  String translate(String? text) {
    if (text == null || text.trim().isEmpty) return "";

    final lang = uygulamaDili;
    if (lang == "Türkçe") return text;

    if (lang == "English") {
      if (text.endsWith(" Dakika Önce")) {
        String num = text.split(" ")[0];
        return "$num Mins Before";
      }
      if (text.endsWith(" Dakika")) {
        String num = text.split(" ")[0];
        return "$num Mins";
      }
      if (text.endsWith(" vaktine kalan")) {
        String name = translate(text.split(" ")[0]);
        return "$name in";
      }
      if (text.endsWith(" vaktinde oku")) {
        String name = translate(text.split(" ")[0]);
        return "Read on $name time";
      }
      if (text.endsWith(" Vakti")) {
        String name = translate(text.split(" ")[0]);
        return "$name Time";
      }
      if (text.endsWith(" Ezanı")) {
        String name = translate(text.split(" ")[0]);
        return "$name Adhan";
      }

      final dict = {
        // Ayarlar & Alt Menüler
        "Otomatik": "Auto",
        "Açık (Karanlık Tema)": "On (Dark Theme)",
        "Kapalı (Aydınlık Tema)": "Off (Light Theme)",
        "Uygulama görünüm temasını seçin": "Choose app appearance theme",
        "Vazgeç": "Cancel",
        "Ayarlar": "Settings",
        "AKTİF GÖRÜNÜM": "ACTIVE THEME",
        "Şehirler": "Cities",
        "Yeni Şehir Ekle": "Add New City",
        "Ara": "Search",
        "Değiştir": "Change",
        "Kaydet": "Save",
        "Düzenle": "Edit",
        "Türkiye": "Turkey",
        "Konumum": "My Location",
        "Şehir bilgileri alınamadı.": "Failed to get city data.",

        // Menü & Vakitler
        "Yakın Camiler": "Nearby Mosques",
        "Hatim": "Hatm",
        "Kazalar": "Missed Prayers",
        "Ajanda": "Agenda",
        "Amel Defteri": "Deeds Book",
        "Hesaplanıyor...": "Calculating...",
        "Yükleniyor...": "Loading...",
        "Vaktin Çıkmasına": "Time Left",
        "Vaktine": "Time",
        "İmsak": "Imsak",
        "Güneş": "Sunrise",
        "Sabah": "Fajr",
        "Öğle": "Dhuhr",
        "İkindi": "Asr",
        "Akşam": "Maghrib",
        "Yatsı": "Isha",

        // Aylar & Günler
        "Ocak": "January",
        "Şubat": "February",
        "Mart": "March",
        "Nisan": "April",
        "Mayıs": "May",
        "Haziran": "June",
        "Temmuz": "July",
        "Ağustos": "August",
        "Eylül": "September",
        "Ekim": "October",
        "Kasım": "November",
        "Aralık": "December",
        "Pzt": "Mon",
        "Sal": "Tue",
        "Çar": "Wed",
        "Per": "Thu",
        "Cum": "Fri",
        "Cmt": "Sat",
        "Paz": "Sun",
        "Shawwal": "Shawwal",
        "Ramadan": "Ramadan",
        "Dhu al-Qidah": "Dhu al-Qidah",
        "Dhu al-Hijjah": "Dhu al-Hijjah",
        "Muharram": "Muharram",
        "Safar": "Safar",
        "Rabi al-Awwal": "Rabi al-Awwal",
        "Rabi al-Thani": "Rabi al-Thani",
        "Jumada al-Awwal": "Jumada al-Awwal",
        "Jumada al-Thani": "Jumada al-Thani",
        "Rajab": "Rajab",
        "Shaban": "Sha'ban",

        // Ayarlar Menü Öğeleri
        "Kuran": "Quran",
        "Kütüphane": "Library",
        "Pusula": "Compass",
        "İmsakiye": "Schedule",
        "Zikirmatik": "Tasbih",
        "Camiler": "Mosques",
        "Dualar": "Prayers",
        "Menü": "Menu",
        "Vakitler": "Times",

        "Hesaplama Yöntemi": "Calculation Method",
        "İkindi Hesabı": "Asr Calculation",
        "Temkinler": "Safety Times",
        "Hatırlatıcılar": "Reminders",
        "Bildirimleri Ertele": "Snooze Notifications",
        "Vaktinde Kıl": "Pray on Time",
        "Bildirim İzinleri": "Notification Perms",
        "Durumu": "Status",
        "Ses": "Sound",
        "Uyarı Süresi": "Alert Time",
        "İlk Uyarı Gecikmesi": "First Alert Delay",
        "Uyarı Sıklığı": "Alert Frequency",
        "Günler": "Days",
        "Tüm Günler Açık": "All Days On",
        "Tüm Günler Kapalı": "All Days Off",
        "Vaktinden Önce Uyarı": "Early Alert",
        "Güneş Vaktinden 60 Dakika Önce": "60 Mins Before Sunrise",

        "Uygulama Dili": "App Language",
        "Konum İzinleri": "Location Perms",
        "Gece Modu": "Dark Mode",
        "Canlı Etkinlik": "Live Activity",
        "Ana Sayfa Stili": "Home Style",
        "Hesabım": "My Account",
        "Profilim": "My Profile",
        "KUR'AN-I KERİM YAZI BOYUTU": "QURAN FONT SIZE",
        "Boyut Ayarla": "Adjust Size",
        "Açık": "On",
        "Kapalı": "Off",
        "Başlat": "Start",

        // Kayıt / Giriş Ekranları
        "Hesap Oluştur": "Create Account",
        "Şifremi Unuttum": "Forgot Password",
        "Çıkış Yap": "Log Out",
        "Hoş Geldin!": "Welcome!",
        "Mail Adresiniz": "Your Email",
        "Şifre": "Password",
        "Şifre Belirleyin": "Set Password",
        "Kayıt Ol": "Sign Up",
        "Giriş Yap": "Log In",
        "Google ile Oturum Aç": "Sign in with Google",
        "Apple ile Giriş Yap": "Sign in with Apple",
        "veya": "or",
        "Şifre Sıfırlama": "Reset Password",
        "Şifrenizi mi Unuttunuz?": "Forgot your password?",
        "Bağlantı Gönder": "Send Link",

        // Çeşitli
        "Ertele": "Snooze",
        "Tarih Seç": "Select Date",
        "Bitti": "Done",
        "İptal": "Cancel",
        "Sabah Ezanı [Kapalı]": "Fajr Adhan [Off]",
        "Namazların geciktirilmeden kılınması için; ilk uyarı gecikme süresinden sonra uyan sıklığına göre 2 defa hatırlatma yapan bir özelliktir. 'Haydi kalk! Vakit girdi, Namazını kıl' diyen hayırlı bir arkadaş gibidir.":
            "A feature that reminds you twice to pray on time. Like a good friend saying 'Come on, it is time to pray!'.",
        "Varsayılan Sistem Sesi": "Default System Sound",
        "Sesi kullanmak için önce indirmelisiniz.": "Download the sound first.",
        "Ses Seçimi": "Select Sound",
      };

      return dict[text] ?? text;
    }

    return text;
  }

  // =========================================================
  // GETTERLAR
  // =========================================================

  String get anaSayfaStili {
    String stil = _user != null
        ? (_userData?['ayarlar']?['ana_sayfa_stili'] ?? 'Listeli')
        : (_guestSettings['ana_sayfa_stili'] ?? 'Listeli');
    List<String> gecerliTemalar = [
      'Listeli',
      'Dairesel',
      'Analog Saat',
      'Fotoğraflı',
      'Timeline',
      'Dashboard'
    ];
    if (!gecerliTemalar.contains(stil)) return 'Listeli';
    return stil;
  }

  String get uygulamaDili => _user != null
      ? (_userData?['ayarlar']?['uygulama_dili'] ?? 'Türkçe')
      : (_guestSettings['uygulama_dili'] ?? 'Türkçe');
  String get hesaplamaYontemi => _user != null
      ? (_userData?['ayarlar']?['hesaplama_yontemi'] ?? 'Diyanet Takvimi')
      : _guestSettings['hesaplama_yontemi'];
  String get ikindiHesabi => _user != null
      ? (_userData?['ayarlar']?['ikindi_hesabi'] ??
          'Şafi, Maliki, Hanbeli, Türkiye')
      : _guestSettings['ikindi_hesabi'];
  List<dynamic> get kayitliSehirler => _user != null
      ? (_userData?['ayarlar']?['kayitli_sehirler'] ??
          _guestSettings['kayitli_sehirler'])
      : _guestSettings['kayitli_sehirler'];

  Map<String, dynamic> get seciliSehir {
    try {
      return kayitliSehirler.firstWhere((s) => s['secili'] == 'true',
          orElse: () => kayitliSehirler.first);
    } catch (e) {
      return _guestSettings['kayitli_sehirler'][0];
    }
  }

  int get apiMethod {
    switch (hesaplamaYontemi) {
      case "Kuzey Amerika (ISNA)":
        return 2;
      case "Müslim World Lig":
        return 3;
      case "Ummül Kurra":
        return 4;
      case "Mısır":
        return 5;
      case "Tahran Üniversitesi":
        return 7;
      case "Diyanet Takvimi":
        return 13;
      default:
        return 13;
    }
  }

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
            'ana_sayfa_stili': 'Listeli',
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
            'ana_sayfa_stili': 'Listeli',
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

  String _translateFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return "Hesap bulunamadı.";
      case 'wrong-password':
        return "Şifre hatalı.";
      case 'email-already-in-use':
        return "Bu e-posta zaten kullanımda.";
      default:
        return "Bir hata oluştu ($code)";
    }
  }
}
