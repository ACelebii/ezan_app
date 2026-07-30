/// Hatırlatıcılarda seçilebilecek seslerin kataloğu.
///
/// [isAvailable] alanı false olan sesler için henüz bir ses dosyası yok;
/// bunlar Ses Seçimi ekranında "Yakında" rozetiyle kilitli gösterilir.
/// Yeni bir ses eklemek için: mp3'ü assets/sounds/ ve
/// android/app/src/main/res/raw/ altına koy, pubspec.yaml'a ekle, buradaki
/// kaydı isAvailable: true yap ve NotificationService'teki kanal listesine
/// ekle.
class ReminderSound {
  final String key;
  final String displayName;
  final String? assetPath;
  final bool isAvailable;

  const ReminderSound({
    required this.key,
    required this.displayName,
    required this.isAvailable,
    this.assetPath,
  });
}

class ReminderSounds {
  ReminderSounds._();

  static const varsayilan = ReminderSound(
    key: 'varsayilan',
    displayName: 'Varsayılan Bildirim Sesi',
    isAvailable: true,
  );

  static const uyari = ReminderSound(
    key: 'uyari',
    displayName: 'Uyarı Sesi',
    assetPath: 'assets/uyari.mp3',
    isAvailable: true,
  );

  static const ezanKisa = ReminderSound(
    key: 'ezan_kisa',
    displayName: 'Ezan',
    assetPath: 'assets/ezan_kisa.mp3',
    isAvailable: true,
  );

  static const melodi1 = ReminderSound(
    key: 'melodi_1',
    displayName: 'Melodi 1',
    assetPath: 'assets/melodi_1.mp3',
    isAvailable: true,
  );

  static const dingDong = ReminderSound(
    key: 'ding_dong',
    displayName: 'Ding Dong',
    assetPath: 'assets/ding_dong.mp3',
    isAvailable: true,
  );

  static const beep = ReminderSound(
    key: 'beep',
    displayName: 'Beep',
    assetPath: 'assets/beep.mp3',
    isAvailable: true,
  );

  static const melodi2 = ReminderSound(
    key: 'melodi_2',
    displayName: 'Melodi 2',
    assetPath: 'assets/melodi_2.mp3',
    isAvailable: true,
  );

  static const melodi3 = ReminderSound(
    key: 'melodi_3',
    displayName: 'Melodi 3',
    assetPath: 'assets/melodi_3.mp3',
    isAvailable: true,
  );

  static const melodi4 = ReminderSound(
    key: 'melodi_4',
    displayName: 'Melodi 4',
    assetPath: 'assets/melodi_4.mp3',
    isAvailable: true,
  );

  static const melodi19 = ReminderSound(
    key: 'melodi_19',
    displayName: 'Melodi 19',
    assetPath: 'assets/melodi_19.mp3',
    isAvailable: true,
  );

  static const all = <ReminderSound>[
    varsayilan,
    uyari,
    ezanKisa,
    melodi1,
    melodi2,
    melodi3,
    melodi4,
    melodi19,
    dingDong,
    beep,
    ReminderSound(key: 'sela', displayName: 'Sela', isAvailable: false),
    ReminderSound(key: 'kus_sesi_1', displayName: 'Kuş Sesi 1', isAvailable: false),
    ReminderSound(key: 'kisa_ezan_1', displayName: 'Kısa Ezan 1', isAvailable: false),
    ReminderSound(key: 'kisa_ezan_2', displayName: 'Kısa Ezan 2', isAvailable: false),
    ReminderSound(key: 'kisa_ezan_3', displayName: 'Kısa Ezan 3', isAvailable: false),
    ReminderSound(key: 'ezan_sultanahmet', displayName: 'Ezan Sultanahmet', isAvailable: false),
    ReminderSound(key: 'ezan_mekke', displayName: 'Ezan Mekke', isAvailable: false),
  ];

  static ReminderSound byKey(String key) =>
      all.firstWhere((s) => s.key == key, orElse: () => varsayilan);
}
