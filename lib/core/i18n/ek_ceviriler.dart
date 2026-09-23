// lib/core/i18n/ek_ceviriler.dart
//
// Kur'an, zikirmatik ve diğer ekranların İngilizce metinleri. `AuthService.translate`
// kendi sözlüğünde bulamazsa buraya bakar. Bulunamayan metin olduğu gibi kalır
// (Türkçe). Sabit metinler [_sozluk]te, sayı/ad içeren metinler [_kaliplar]da.

const _sozluk = <String, String>{
  // ---- Kur'an: menü ve sayfalar
  'Sureler': 'Surahs',
  'Cüzler': 'Juz',
  'Fihrist': 'Index',
  'Yer İmi': 'Bookmark',
  'Kaydedilmiş bir yer imi bulunamadı.': 'No saved bookmark found.',
  'Favori': 'Favorites',
  'Not': 'Notes',
  'Okuma Listesi': 'Reading List',
  'Kuran-ı Kerim': 'Holy Quran',
  'SURELER': 'SURAHS',
  'CÜZLER': 'JUZ',
  'Kaldığım Yer': 'Where I Left Off',
  'Sayfa': 'Page',
  'Cüz': 'Juz',
  'Sure': 'Surah',
  'Meal': 'Translation',
  'Ara (İsim veya Numara)': 'Search (Name or Number)',
  "Mealde ara (tüm Kur'an)": 'Search the translation (whole Quran)',
  'Aramak için yazın.': 'Type to search.',
  'Tümünü indir': 'Download all',
  'Tüm sayfaları indir': 'Download all pages',
  'Bu sayfaları indir': 'Download these pages',
  'Bu sayfanın ayetleri': 'Verses on this page',
  'Yaklaşık 57 MB indirilecek. Mobil veri kullanıyorsanız ücret çıkabilir.':
      'About 57 MB will be downloaded. Charges may apply if you use mobile data.',
  'İndir': 'Download',
  'Durdur': 'Stop',
  'Sayfa görselleri indirilemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.':
      'Page images could not be downloaded. Check your internet connection and try again.',
  'Tam eşleşme yok; benzer sözcükler gösteriliyor.':
      'No exact match; showing similar words.',
  'Sonuç bulunamadı.': 'No results found.',
  'Git!': 'Go!',
  'Ezberleme': 'Memorization',
  'Yardım': 'Help',
  'Seslendirme': 'Recitation',
  'Seslendirme (Hafız)': 'Recitation (Reciter)',
  'Sayfa Görünüm Stili': 'Page View Style',
  'Liste (Sure)': 'List (Surah)',
  'Metin (Sayfa)': 'Text (Page)',
  'Liste (Sayfa)': 'List (Page)',
  'Resim': 'Image',
  'Arkaplan': 'Background',
  'Ayet Takibi': 'Verse Tracking',
  'Vurgu': 'Highlight',
  'Renk': 'Color',
  'Kenarlık': 'Border',
  'Yok': 'None',
  'Hafız': 'Reciter',
  'Liste': 'List',
  'Ayetler yüklenemedi.\nİnternet bağlantınızı kontrol edip tekrar deneyin.':
      'Verses could not be loaded.\nCheck your internet connection and try again.',
  'Not ekle': 'Add note',
  'Notu düzenle': 'Edit note',
  'Favoriden çıkar': 'Remove from favorites',
  'Favorilere ekle': 'Add to favorites',
  'Sayfa görseli indirilemedi.': 'The page image could not be downloaded.',
  'Sure ekle': 'Add surah',
  'Favori Ayetler': 'Favorite Verses',
  'Henüz favori ayet yok.\n\nBir sureyi Liste görünümünde açıp ayetin altındaki kalp simgesine dokunarak favorilere ekleyebilirsiniz.':
      'No favorite verses yet.\n\nOpen a surah in List view and tap the heart icon under a verse to add it to your favorites.',
  'Notlarım': 'My Notes',
  'Henüz not yok.\n\nBir sureyi Liste görünümünde açıp ayetin altındaki not simgesine dokunarak o ayete not yazabilirsiniz.':
      'No notes yet.\n\nOpen a surah in List view and tap the note icon under a verse to write a note for it.',
  'Notunuzu yazın': 'Write your note',
  'Notu Sil': 'Delete Note',
  'Okuma listeniz boş.\n\nSağ alttaki + ile okumak istediğiniz sureleri ekleyin; okudukça işaretleyin.':
      'Your reading list is empty.\n\nUse the + at the bottom right to add the surahs you want to read, and tick them off as you go.',
  'Listeden çıkar': 'Remove from list',
  'Listeye sure ekle': 'Add surah to list',
  'Sure ara': 'Search surah',
  'Eklenecek sure kalmadı.': 'No surahs left to add.',
  'Ezberlemek için önce bir sure, cüz ya da sayfa açın.':
      'To memorize, first open a surah, juz or page.',
  'Seçtiğiniz ayetler, her biri istediğiniz kadar tekrarlanarak sırayla çalınır.':
      'The verses you select are played in order, each repeated as many times as you choose.',
  'Başlangıç': 'Start',
  'Bitiş': 'End',
  'Her ayet kaç kez': 'Repeats per verse',
  'Ezberlemeyi Bitir': 'Finish Memorization',
  'Açık olan sure seçtiğiniz hafızla yeniden yüklenir.':
      'The open surah reloads with the selected reciter.',
  'Südais': 'Sudais',
  'Mekke': 'Makkah',
  'Medine': 'Madinah',
  // ---- Zikirmatik
  'Sil': 'Delete',
  'Bitti': 'Done',
  'Düzenle': 'Edit',
  'Kalıcı olarak sil': 'Delete permanently',
  'Zikir ve sayacı kalıcı olarak silinir.':
      'The dhikr and its counter will be permanently deleted.',
  'Sayaç sıfırlansın mı?': 'Reset the counter?',
  'Sıfırla': 'Reset',
  'Görünüm 1': 'View 1',
  'Görünüm 2': 'View 2',
  'Görünüm 3': 'View 3',
  'Tesbih': 'Prayer Beads',
  'Zikri Düzenle': 'Edit Dhikr',
  'Zikir Ekle': 'Add Dhikr',
  'Lütfen zikir adı girin.': 'Please enter a dhikr name.',
  'Adet en az 1 olmalı.': 'The count must be at least 1.',
  'Zikir Adı': 'Dhikr Name',
  'Örn: Sübhânellâhi': 'e.g. Subhanallah',
  'Adet': 'Count',
  'İmame': 'Marker Bead',
  'Arapça': 'Arabic',
  'Arapça metin...': 'Arabic text...',
  'Okunuşu': 'Transliteration',
  'Okunuşu...': 'Transliteration...',
  'Anlamı': 'Meaning',
  'Anlamı...': 'Meaning...',
  // hazır zikirler (uygulamanın kendi metinleri)
  '100 Sübhânellâhi': '100 Subhanallah',
  '99 Lâ havle': '99 La hawla',
  'Salavat': 'Salawat',
  'Sübhânellâhi ve bi hamdihî sübhânellâhil azîm':
      'Subhanallahi wa bihamdihi subhanallahil azim',
  "Allah'ü Teala'yı tesbih ederim, hamd O'na mahsustur.":
      'I glorify Allah, the Most High; all praise belongs to Him.',
  'Lâ havle ve lâ kuvvete illâ billâhil aliyyil azîm':
      'La hawla wa la quwwata illa billahil aliyyil azim',
  "Bütün kudret ve kuvvet, Aliyy ve Azîm olan Allah'a aittir.":
      'All power and strength belong to Allah, the Most High, the Most Great.',
  'Allahümme Salli Ala Seyyidina Muhammedin ve Ala Ali Seyyidina Muhammed':
      'Allahumma salli ala sayyidina Muhammadin wa ala ali sayyidina Muhammad',
  "Allah'ım, efendimiz Hz. Muhammed'e ve aline salat eyle.":
      'O Allah, send blessings upon our master Muhammad and upon his family.',
  // ---- Kur'an: hata ve durum iletileri (sağlayıcı/depo)
  'Seçilen aralıkta çalınacak sesli ayet yok.':
      'There are no verses with audio in the selected range.',
  'Ses yüklenemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.':
      'The audio could not be loaded. Check your internet connection and try again.',
  'Sure listesi okunamadı.':
      'The surah list could not be read.', // ---- Diğer ekranlar
  // Kazalar
  'Bu cihazın ana ekranı sayısal rozetleri desteklemiyor; yalnızca bildirim noktası gösterilebilir.':
      "This device's home screen does not support numeric badges; only a notification dot can be shown.",
  'Henüz kayıt yok': 'No records yet',
  'Kaza sayısını iconda göster': 'Show the missed prayer count on the icon',
  'Toplu kaza girişi için rakamların üzerine dokununuz.\n(*) Son Kayıt Tarihi':
      'Tap the numbers to enter missed prayers in bulk.\n(*) Last Entry Date',
  // Ajanda
  'Bugün': 'Today',
  'Vakitler yüklenemedi. Lütfen internet bağlantınızı kontrol edin.':
      'Prayer times could not be loaded. Please check your internet connection.',
  // Camiler
  'Araçla': 'By Car',
  'Yürüyerek': 'On Foot',
  'Ayarları Aç': 'Open Settings',
  'Cami listesi yüklenemedi.': 'The mosque list could not be loaded.',
  'Harita uygulaması açılamadı.': 'The map app could not be opened.',
  'Konum bilgisi alınamadı': 'Location information could not be obtained',
  'Standart': 'Standard',
  'Uydu': 'Satellite',
  'Yakınında cami bulunamadı.': 'No mosques found nearby.',
  // Dini günler, dualar
  'Bu yıla ait veri bulunamadı.': 'No data found for this year.',
  'Arapça Okunuşu': 'Arabic Text',
  'Türkçe Okunuşu': 'Turkish Transliteration',
  'Kaynak': 'Source',
  'Gösterilecek dua bulunamadı.': 'No prayers to show.',
  // Hatim
  'Cevşen': 'Jawshan',
  'Görevlerim': 'My Tasks',
  'Hatimler': 'Hatms',
  'Şu an aktif bir hatim bulunmuyor.': 'There is no active hatm right now.',
  'Görev bulunamadı.': 'No tasks found.',
  'Lütfen seçtiğiniz görevleri yerine getirirken Kuran Okuma Adabı ve Kurallarına uyarak okuyalım.\nSeçtiğiniz sayfayı program haricinde bir yerden okuyacaksanız, aynı sayfa olmasına dikkat ediniz.':
      'Let us follow the etiquette and rules of reading the Quran while fulfilling the tasks you selected.\nIf you will read your selected page from somewhere outside the app, make sure it is the same page.',
  'EVET': 'YES',
  'Henüz alınmış bir göreviniz bulunmuyor.':
      'You have not taken any tasks yet.',
  'Okudum': 'I Read It',
  'Onaylıyormusunuz?': 'Do you confirm?',
  'Son Kaldığım Yer': 'Where I Left Off',
  'İlgili görevi\nokuduğunuzu\nonaylıyormusunuz?':
      'Do you confirm\nthat you have\nread this task?',
  // Hutbe
  'Bu PDF resmi yayındır.': 'This PDF is an official publication.',
  'Geçerli bir PDF linki bulunamadı.': 'No valid PDF link found.',
  'Henüz hutbe eklenmemiş.': 'No sermons have been added yet.',
  'Hutbe İndiriliyor...': 'Downloading Sermon...',
  'PDF yüklenirken hata oluştu! Linki kontrol edin.':
      'An error occurred while loading the PDF! Please check the link.',
  'Sunucuya bağlanılamadı.\nLütfen internet bağlantınızı kontrol edip sayfayı aşağı çekerek yenileyin.':
      'Could not connect to the server.\nPlease check your internet connection and pull down to refresh.',
  // İmsakiye
  "Soluk yazılı günler Diyanet'ten değil, hesaplanmış vakitlerdir (1-2 dakika sapabilir).":
      'Faded days are calculated times, not published by Diyanet (they may differ by 1-2 minutes).',
  // Kütüphane
  'Bu kategoriye ait içerik henüz eklenmemiş.':
      'No content has been added to this category yet.',
  'Henüz bir kitap okumadınız.': 'You have not read any book yet.',
  'Son Okunan': 'Last Read',
  'Bu kitap için PDF henüz eklenmedi.':
      'No PDF has been added for this book yet.',
  // İzin akışı
  '"Alarmlar ve hatırlatıcılar" izni: verilmezse Android ezanı birkaç dakika geciktirebilir.':
      '"Alarms & reminders" permission: if it is not granted, Android may delay the adhan by a few minutes.',
  'Bildirim izni': 'Notification permission',
  'Daha sonra Ayarlar > Hatırlatıcılar bölümünden de verebilirsiniz.':
      'You can also grant it later under Settings > Reminders.',
  'Devam': 'Continue',
  'Ezan ve hatırlatıcıların tam vaktinde çalabilmesi için şu izinler gerekiyor:':
      'These permissions are needed so the adhan and reminders can play exactly on time:',
  'Ezanlar tam vaktinde çalsın': 'Play adhans exactly on time',
  'Şimdi Değil': 'Not Now',
  // Multimedya
  'Henüz multimedya içeriği eklenmemiş.':
      'No multimedia content has been added yet.',
  'Bu bölümde henüz içerik yok.': 'There is no content in this section yet.',
  'Video linki açılamadı.': 'The video link could not be opened.',
  'İzlemek için: ': 'To watch: ',
  'Duvar Kağıdı Olarak Ayarla': 'Set as Wallpaper',
  'Duvar kağıdı ayarlanamadı.': 'The wallpaper could not be set.',
  'Duvar kağıdı ayarlandı.': 'Wallpaper set.',
  'Duvar kağıdı ayarlanırken hata oluştu.':
      'An error occurred while setting the wallpaper.',
  // Pusula
  'DERECE': 'DEGREES',
  'KIBLE YÖNÜ': 'QIBLA DIRECTION',
  'KIBLEYE YÖNELDİNİZ': 'YOU ARE FACING THE QIBLA',
  'Konum alınıyor, lütfen bekleyin...': 'Getting your location, please wait...',
  'Konumunuz': 'Your Location',
  'Konumunuz alınamadı, harita Kâbe merkezli gösteriliyor.':
      'Your location could not be obtained; the map is centered on the Kaaba.',
  'Kâbe': 'Kaaba',
  // Ayarlar ve hesap
  'En az bir şehir kalmalıdır.': 'At least one city must remain.',
  'Hesabınıza bağlı e-posta adresini girin, size güvenli bir sıfırlama bağlantısı gönderelim.':
      'Enter the email address linked to your account and we will send you a secure reset link.',
  'Kayıtlı Mail Adresiniz': 'Your Registered Email',
  'Lütfen geçerli bir e-posta adresi yazın.':
      'Please enter a valid email address.',
  'Lütfen mail adresinizi yazın.': 'Please enter your email address.',
  'Sıfırlama bağlantısı mailinize gönderildi!':
      'The reset link was sent to your email!',
  'Bildirim izni verilmedi': 'Notification permission was not granted',
  'Bu yıl için Ramazan takvim verisi henüz eklenmedi; hatırlatıcı şu an hiçbir şey planlamıyor.':
      'Ramadan calendar data has not been added for this year yet; the reminder is not scheduling anything right now.',
  'Ezanlar tam vaktinde çalmayabilir': 'Adhans may not play exactly on time',
  'Android, "Alarmlar ve hatırlatıcılar" izni olmadan bildirimleri birkaç dakika geciktirebilir. Ezanın tam vaktinde çalması için bu izni verin.':
      'Without the "Alarms & reminders" permission, Android may delay notifications by a few minutes. Grant this permission so adhans play exactly on time.',
  'Arka plan yenilemesi gecikebilir': 'Background refresh may be delayed',
  'Telefonunuzun pil tasarrufu, uygulama uzun süre açılmadığında bildirimlerin arka planda yenilenmesini geciktirebilir. Ezanların kendisi bundan etkilenmez; yine de "Pil optimizasyonunu yoksay" izni verirseniz yenileme daha güvenilir çalışır.':
      'Your phone\'s battery saver may delay background notification refresh when the app hasn\'t been opened for a while. Adhans themselves are not affected; granting "Ignore battery optimizations" makes the refresh more reliable.',
  'Hatırlatıcının çalışması için bildirim izni gerekir.':
      'Notification permission is required for the reminder to work.',
  'Lütfen e-posta ve şifrenizi girin.': 'Please enter your email and password.',
  'Lütfen geçerli bir e-posta adresi girin.':
      'Please enter a valid email address.',
  'Aramıza Katıl': 'Join Us',
  'Ayarlarını buluta kaydetmek ve her cihazdan erişmek için ücretsiz kayıt ol.':
      'Sign up for free to save your settings to the cloud and access them from any device.',
  'Güvenliğiniz için şifreniz en az 8 karakter olmalıdır.':
      'For your security, your password must be at least 8 characters.',
  'Hesabınız oluşturuldu!': 'Your account has been created!',
  'Lütfen e-posta ve şifre alanlarını boş bırakmayın.':
      'Please do not leave the email and password fields empty.',
  'Bu ses için dosya henüz eklenmedi.':
      'No file has been added for this sound yet.',
  'Sesler': 'Sounds',
  'Yakında': 'Coming Soon',
  '9 Şevval\n1447': '9 Shawwal\n1447',
  'İstanbul': 'Istanbul',
  // Vakitler
  'Kayıtlı şehrime dön': 'Back to my saved city',
  // Göreli zaman ("az önce", "5 dakika önce")
  'az önce': 'just now',
};

const _yuklenenler = {
  'Sure ayetleri': 'surah verses',
  'Cüz ayetleri': 'juz verses',
  'Sayfa ayetleri': 'page verses',
  'Sureler': 'surahs',
};

String _adet(String n, String tekil, String cogul) =>
    n == '1' ? '1 $tekil' : '$n $cogul';

final _kaliplar = <(RegExp, String Function(Match))>[
  (
    RegExp(r'^(\d+) / (\d+) sure cihazda$'),
    (m) => '${m[1]} / ${m[2]} surahs on device'
  ),
  (
    RegExp(r'^(\d+) / (\d+) sayfa cihazda$'),
    (m) => '${m[1]} / ${m[2]} pages on device'
  ),
  (RegExp(r'^(\d+) sonuç$'), (m) => _adet(m[1]!, 'result', 'results')),
  (
    RegExp(r'^(\d+) sonuç \(ilk (\d+) gösteriliyor\)$'),
    (m) => '${m[1]} results (showing the first ${m[2]})'
  ),
  (RegExp(r'^"(.+)" silinsin mi\?$'), (m) => 'Delete "${m[1]}"?'),
  (
    RegExp(r'^(\d+)/(\d+) ve (\d+) tur silinecek\.$'),
    (m) => '${m[1]}/${m[2]} and ${m[3]} rounds will be cleared.'
  ),
  (RegExp(r'^İmame: (\d+)$'), (m) => 'Marker bead: ${m[1]}'),
  (RegExp(r'^(\d+) Ayet$'), (m) => _adet(m[1]!, 'Verse', 'Verses')),
  (RegExp(r'^(\d+) ayet$'), (m) => _adet(m[1]!, 'verse', 'verses')),
  (RegExp(r'^(\d+)\. Cüz$'), (m) => 'Juz ${m[1]}'),
  (RegExp(r'^(\d+)\. Sayfa$'), (m) => 'Page ${m[1]}'),
  (RegExp(r'^Sayfa (\d+)$'), (m) => 'Page ${m[1]}'),
  (RegExp(r'^(\d+)\. sure$'), (m) => 'Surah ${m[1]}'),
  (
    RegExp(r'^(\d+) / (\d+) sure okundu$'),
    (m) => '${m[1]} / ${m[2]} surahs read'
  ),
  (RegExp(r'^(.+) için not$'), (m) => 'Note for ${m[1]}'),
  (RegExp(r'^Yer İmi \((.+)\)$'), (m) => 'Bookmark (${m[1]})'),
  (RegExp(r'^Ezberleme  ·  (.+)$'), (m) => 'Memorization  ·  ${m[1]}'),
  (
    RegExp(r'^(\d+) ayet x (\d+) = (\d+) çalma$'),
    (m) => '${m[1]} verses x ${m[2]} = ${m[3]} plays'
  ),
  (
    RegExp(r'^Aralık ve tekrar sayısı çok büyük \((\d+) ayet x (\d+) = (\d+) '
        r'çalma; en çok (\d+)\)\. Aralığı daraltın ya da tekrarı azaltın\.$'),
    (m) => 'The range and repeat count are too large (${m[1]} verses x '
        '${m[2]} = ${m[3]} plays; at most ${m[4]}). Narrow the range or '
        'reduce the repeats.'
  ),
  (
    RegExp(
        r'^(Sure ayetleri|Cüz ayetleri|Sayfa ayetleri|Sureler) yüklenemedi\. '
        r'İnternet bağlantınızı kontrol edip tekrar deneyin\.$'),
    (m) => 'Could not load the ${_yuklenenler[m[1]]}. Check your internet '
        'connection and try again.'
  ),
  (
    RegExp(r'^(Sure ayetleri|Cüz ayetleri|Sayfa ayetleri|Sureler) yüklenemedi '
        r'\(sunucu yanıtı: (\d+)\)\. Lütfen daha sonra tekrar deneyin\.$'),
    (m) => 'Could not load the ${_yuklenenler[m[1]]} (server response: '
        '${m[2]}). Please try again later.'
  ),
];

/// [metin]in İngilizcesi; bilinmiyorsa null (çağıran metni olduğu gibi bırakır).
String? ekCeviriEn(String metin) {
  final dogrudan = _sozluk[metin];
  if (dogrudan != null) return dogrudan;
  for (final (kalip, cevir) in _kaliplar) {
    final m = kalip.firstMatch(metin);
    if (m != null) return cevir(m);
  }
  return null;
}
