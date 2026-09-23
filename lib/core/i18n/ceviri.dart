// lib/core/i18n/ceviri.dart

import 'ek_ceviriler.dart';

/// Uygulama metinlerinin çevirisi (kaynak Türkçe, hedef İngilizce). Ayarlardan
/// ve oturumdan bağımsız saf sınıftır: dil parametre olarak verilir.
/// `AuthService.translate` ve `context.t` buraya yönlenir.
///
/// Yeni metin eklerken: sabit metin [_sozluk]e (Kur'an ve zikirmatik için
/// `ek_ceviriler.dart`a), sayı/ad içeren metin kalıplara eklenir. Çevrilmemiş
/// metin olduğu gibi (Türkçe) kalır; `test/core/i18n/ceviri_tarama_test.dart`
/// ekranlardaki çevrilmemiş metinleri yakalar.
class Ceviri {
  const Ceviri._();

  static const turkce = 'Türkçe';
  static const ingilizce = 'English';

  /// [text]i [dil]e çevirir. Türkçe ve desteklenmeyen dillerde metin değişmez.
  static String cevir(String? text, String dil) {
    if (text == null || text.trim().isEmpty) return '';
    if (dil != ingilizce) return text;

    if (text.endsWith(" Dakika Önce")) {
      String num = text.split(" ")[0];
      return "$num Mins Before";
    }
    if (text.endsWith(" Dakika")) {
      String num = text.split(" ")[0];
      return "$num Mins";
    }
    if (text.endsWith(" vaktine kalan")) {
      String name = cevir(text.split(" ")[0], dil);
      return "$name in";
    }
    if (text.endsWith(" vaktinde oku")) {
      String name = cevir(text.split(" ")[0], dil);
      return "Read on $name time";
    }
    if (text.endsWith(" Vakti")) {
      String name = cevir(text.split(" ")[0], dil);
      return "$name Time";
    }
    if (text.endsWith(" Ezanı")) {
      String name = cevir(text.split(" ")[0], dil);
      return "$name Adhan";
    }
    final sabit = _sozluk[text] ?? ekCeviriEn(text);
    if (sabit != null) return sabit;
    for (final (kalip, f) in _kaliplar) {
      final m = kalip.firstMatch(text);
      if (m != null) return f(m, (x) => cevir(x, dil));
    }
    return text;
  }

  /// Ad/sayı içeren kalıplar; [t] iç metni de çevirir (ör. vakit adı).
  static final _kaliplar =
      <(RegExp, String Function(Match m, String Function(String) t))>[
    (RegExp(r'^(.+) Kazası$'), (m, t) => '${t(m[1]!)} Missed Prayer'),
    (RegExp(r'^(\d+)\. Hatim$'), (m, t) => 'Hatm ${m[1]}'),
    (RegExp(r'^Okunma %(.+)$'), (m, t) => 'Read %${m[1]}'),
    (RegExp(r'^Paylaşılma %(.+)$'), (m, t) => 'Shared %${m[1]}'),
    (RegExp(r'^Alındı: (.+)$'), (m, t) => 'Taken: ${t(m[1]!)}'),
    (RegExp(r'^(\d+) dakika önce$'), (m, t) => '${m[1]} minutes ago'),
    (RegExp(r'^(\d+) saat önce$'), (m, t) => '${m[1]} hours ago'),
    (RegExp(r'^(\d+) gün önce$'), (m, t) => '${m[1]} days ago'),
    (RegExp(r'^İşlem başarısız: (.+)$'), (m, t) => 'Operation failed: ${m[1]}'),
    (
      RegExp(r'^(.+) özelliği yakında eklenecek\.$'),
      (m, t) => 'The ${t(m[1]!)} feature is coming soon.'
    ),
    (
      RegExp(r'^(.+) yakında eklenecek\.\.\.$'),
      (m, t) => '${t(m[1]!)} coming soon...'
    ),
    (
      RegExp(r'^(.+)\n(\d+)\. Sayfa$', dotAll: true),
      (m, t) => '${m[1]}\nPage ${m[2]}'
    ),
    (RegExp(r'^Senkronizasyon hatası: (.+)$'), (m, t) => 'Sync error: ${m[1]}'),
    (
      RegExp(r'^(.+) için vakitler alınamadı\. İnternet bağlantınızı kontrol '
          r'edip tekrar deneyin\.$'),
      (m, t) => 'Prayer times for ${m[1]} could not be loaded. Check your '
          'internet connection and try again.'
    ),
  ];

  /// [text]in İngilizce karşılığı var mı (çeviri metinden farklı mı).
  static bool cevrilebilir(String text) => cevir(text, ingilizce) != text;

  static const _sozluk = <String, String>{
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
    "Yurt Dışı (Tüm Ülkeler)": "Abroad (All Countries)",
    "Konumumu Kullan": "Use My Location",
    "Konum bulunuyor...": "Finding your location...",
    "Konum servisleri kapalı.": "Location services are off.",
    "Konum izni reddedildi.": "Location permission denied.",
    "Konum izni kalıcı olarak reddedildi.":
        "Location permission was permanently denied.",
    "Konum alınamadı.": "Could not get your location.",
    "Bu konum için yer bulunamadı. İnternet bağlantınızı kontrol edip tekrar deneyin.":
        "No place found for this location. Check your internet connection and try again.",
    "Bu yer için Diyanet saati yok; vakitler koordinata göre hesaplanır (Diyanet yöntemiyle, birkaç dakika sapabilir).":
        "Diyanet does not publish times for this place; times are calculated from coordinates (Diyanet method, may differ by a few minutes).",
    "Ülke Seç": "Select Country",
    "Şehir Seç": "Select City",
    "İlçe Seç": "Select District",
    "Sonuç yok": "No results",
    "Liste alınamadı.": "Could not load the list.",
    "Tekrar Dene": "Try Again",
    "Bu yer eklenemedi. İnternet bağlantınızı kontrol edin ya da başka bir yer deneyin.":
        "This place could not be added. Check your internet connection or try another place.",

    // Menü & Vakitler
    "Yakın Camiler": "Nearby Mosques",
    "Hatim": "Hatm",
    "Kazalar": "Missed Prayers",
    "Ajanda": "Agenda",
    "Dini Günler": "Religious Days",
    "Haftanın Hutbesi": "Sermon of the Week",
    "Multimedya": "Multimedia",
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
    "Gökyüzü": "Sky",
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
    "Hesabımı Sil": "Delete My Account",
    "Hesabı Sil": "Delete Account",
    "Hesabını silmek istediğine emin misin?":
        "Are you sure you want to delete your account?",
    "Bu işlem geri alınamaz. Hesabın, ayarların ve aldığın hatim görevleri silinir.":
        "This can't be undone. Your account, settings and any Hatim tasks you've taken will be deleted.",
    "Hesabın silindi.": "Your account has been deleted.",
    "Giriş yapılmamış.": "Not signed in.",
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
}
