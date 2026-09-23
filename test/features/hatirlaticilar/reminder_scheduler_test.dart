import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_modelleri.dart';
import 'package:ezan_vakti_uygulamasi/features/hatirlaticilar/data/reminder_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

/// İstanbul (UTC+3) için bir gün. Vakitler her gün biraz kayar (gerçekte de
/// öyle); böylece "her gün aynı saat" hatası testte yakalanır. Bildirim
/// planı yalnızca `anlar`ı kullanır, `saatler` yer tutucudur.
GunlukVakit _gun(int yil, int ay, int gun) {
  DateTime an(int saat, int dakika) =>
      DateTime.utc(yil, ay, gun, saat, dakika + gun % 20)
          .subtract(const Duration(hours: 3));
  return GunlukVakit(
    tarih: DateTime.utc(yil, ay, gun),
    kaynak: VakitKaynagi.diyanet,
    saatler: {for (final v in Vakit.values) v: '00:00'},
    anlar: {
      Vakit.imsak: an(5, 15),
      Vakit.gunes: an(6, 41),
      Vakit.ogle: an(13, 3),
      Vakit.ikindi: an(16, 31),
      Vakit.aksam: an(19, 15),
      Vakit.yatsi: an(20, 35),
    },
  );
}

/// 20 Eylül 2026 (Pazar) başlayan 20 günlük veri: 14 günlük ufuktan uzun.
final _gunler = [for (var i = 0; i < 20; i++) _gun(2026, 9, 20 + i)];
final _bugun = DateTime.utc(2026, 9, 20);

/// 20.09.2026 10:00 İstanbul: o günün imsak ve güneşi geçti, öğle geçmedi.
final _simdi = DateTime.utc(2026, 9, 20, 7);

List<PlanliBildirim> _planla({
  Map<String, dynamic> hatirlaticilar = const {},
  Map<String, dynamic> vakitEzan = const {},
  Map<String, dynamic> vaktindeKil = const {},
  DateTime? bugun,
  DateTime? simdi,
  ({DateTime start, DateTime end})? ramazan,
  DateTime? ertelemeBitisi,
}) =>
    ReminderScheduler.planla(
      gunler: _gunler,
      bugun: bugun ?? _bugun,
      simdi: simdi ?? _simdi,
      hatirlaticilar: hatirlaticilar,
      vakitEzanAyarlari: vakitEzan,
      vaktindeKilAyarlari: vaktindeKil,
      ramazan: ramazan,
      ertelemeBitisi: ertelemeBitisi,
    );

GunlukVakit _gunuBul(DateTime tarih) =>
    _gunler.firstWhere((g) => g.tarih == tarih);

void main() {
  group('ReminderScheduler.planla', () {
    final acik = {'enabled': true};

    test('hiçbir şey açık değilse plan boştur', () {
      expect(_planla(), isEmpty);
    });

    test('ezan: her gün, o günün GERÇEK vaktinde (her gün aynı saat değil)',
        () {
      final plan = _planla(vakitEzan: {
        'ogle': {'enabled': true, 'sound': 'ezan_kisa'},
      });

      // 20.09'un öğlesi 10:03Z'de, simdi'den sonra; 14 gün, 14 bildirim.
      expect(plan, hasLength(14));
      expect(plan.first.baslik, 'Öğle Ezanı');
      expect(plan.first.govde, 'Öğle vakti girdi.');
      expect(plan.first.ses, 'ezan_kisa');
      for (var i = 0; i < plan.length; i++) {
        final tarih = _bugun.add(Duration(days: i));
        expect(plan[i].an, _gunuBul(tarih).anlar[Vakit.ogle], reason: '$tarih');
      }
      // 27.09 öğlesi, 20.09 öğlesi + 7 gün DEĞİL: vakit kaymış.
      expect(plan[7].an, isNot(plan[0].an.add(const Duration(days: 7))));
    });

    test('ufuk 14 gündür: veri 20 gün olsa da 4 Ekim ve sonrası kurulmaz', () {
      final plan = _planla(vakitEzan: {'yatsi': acik});

      expect(plan, hasLength(14));
      expect(plan.last.an.isBefore(DateTime.utc(2026, 10, 3, 23)), isTrue);
    });

    test('geçmişte kalan an kurulmaz (bugünün imsakı geçti)', () {
      final plan = _planla(vakitEzan: {'imsak': acik});

      expect(plan, hasLength(13)); // 21.09 - 03.10
      expect(plan.every((b) => b.an.isAfter(_simdi)), isTrue);
    });

    test('günler ayarı: yalnızca seçili günlere kurulur (0=Pazar)', () {
      final plan = _planla(vakitEzan: {
        'ogle': {
          'enabled': true,
          'gunler': [true, false, false, false, false, false, false],
        },
      });

      // 14 gün içindeki Pazarlar: 20.09 ve 27.09.
      expect(plan, hasLength(2));
    });

    test('vaktinden önce uyarı: vakitten N dakika önce, ezandan bağımsız', () {
      final plan = _planla(vakitEzan: {
        'ikindi': {'onceEnabled': true, 'onceDakika': 30, 'onceSound': 'beep'},
      });

      expect(plan, hasLength(14));
      expect(plan.first.baslik, 'İkindi Vaktine Yaklaşıyor');
      expect(plan.first.govde, 'İkindi vaktine yaklaşık 30 dakika kaldı.');
      expect(plan.first.ses, 'beep');
      expect(
          plan.first.an,
          _gunuBul(_bugun)
              .anlar[Vakit.ikindi]!
              .subtract(const Duration(minutes: 30)));
    });

    test('sayılar Firestore\'dan double gelse de çalışır, eksikse varsayılan',
        () {
      final plan = _planla(vakitEzan: {
        'ikindi': {'onceEnabled': true, 'onceDakika': 30.0},
        'aksam': {'onceEnabled': true},
      });

      expect(plan.first.govde, contains('30 dakika'));
      expect(plan.last.govde, contains('45 dakika')); // varsayılan
    });

    test('Vaktinde Kıl: vakit girdikten 30 ve 40 dakika sonra', () {
      final plan = _planla(vaktindeKil: {
        'yatsi': {
          'enabled': true,
          'ilkUyariDakika': 30,
          'siklikDakika': 10,
          'sound': 'melodi_19',
        },
      });

      expect(plan, hasLength(28)); // 14 gün x 2 uyarı
      final yatsi = _gunuBul(_bugun).anlar[Vakit.yatsi]!;
      final ilk = plan.firstWhere((b) => b.baslik == 'Haydi kalk!');
      final ikinci = plan.firstWhere((b) => b.baslik == 'Hatırlatma');
      expect(ilk.an, yatsi.add(const Duration(minutes: 30)));
      expect(ikinci.an, yatsi.add(const Duration(minutes: 40)));
      expect(ilk.govde, 'Vakit girdi, Yatsı namazını kıl.');
    });

    test('Vaktinde Kıl, gece yarısını geçse de doğru ana düşer', () {
      // Eski kod saat:dakika modülüyle çalışıyordu; mutlak an bu sorunu
      // taşımaz. Yatsıyı 23:50'ye çeken bir gün.
      final gec = GunlukVakit(
        tarih: DateTime.utc(2026, 9, 20),
        kaynak: VakitKaynagi.diyanet,
        saatler: {for (final v in Vakit.values) v: '00:00'},
        anlar: {
          for (final v in Vakit.values)
            v: DateTime.utc(2026, 9, 20, 23, 50)
                .subtract(const Duration(hours: 3)),
        },
      );
      final plan = ReminderScheduler.planla(
        gunler: [gec],
        bugun: _bugun,
        simdi: DateTime.utc(2026, 9, 19),
        hatirlaticilar: const {},
        vakitEzanAyarlari: const {},
        vaktindeKilAyarlari: {'yatsi': acik},
      );

      // 23:50 + 30 dk = 21.09 00:20 İstanbul = 20.09 21:20 UTC.
      expect(plan.first.an, DateTime.utc(2026, 9, 20, 21, 20));
    });

    test('Teheccüt: her gün imsaktan 45 dakika önce', () {
      final plan = _planla(hatirlaticilar: {'teheccut': acik});

      expect(plan, hasLength(13)); // bugünün imsakı geçti
      expect(plan.first.baslik, 'Teheccüt Vakti');
      expect(
          plan.first.an,
          _gunuBul(DateTime.utc(2026, 9, 21))
              .anlar[Vakit.imsak]!
              .subtract(const Duration(minutes: 45)));
    });

    test('Cuma yalnızca Cuma günlerine, öğleden 60 dakika önce kurulur', () {
      final plan = _planla(hatirlaticilar: {'cuma': acik});

      expect(plan, hasLength(2)); // 25.09 ve 02.10
      expect(plan.first.baslik, 'Cuma Namazı Hatırlatması');
      expect(
          plan.first.an,
          _gunuBul(DateTime.utc(2026, 9, 25))
              .anlar[Vakit.ogle]!
              .subtract(const Duration(minutes: 60)));
    });

    test('oruç: Pazartesi ve Perşembe, imsaktan 60 dakika önce', () {
      final plan = _planla(hatirlaticilar: {'oruc': acik});

      expect(plan.map((b) => b.baslik), [
        'Pazartesi Orucu', // 21.09
        'Perşembe Orucu', // 24.09
        'Pazartesi Orucu', // 28.09
        'Perşembe Orucu', // 01.10
      ]);
    });

    test('Ramazan: yalnızca aralığın içindeki günlere kurulur', () {
      final plan = _planla(
        hatirlaticilar: {'ramazan': acik},
        ramazan: (start: DateTime(2026, 9, 22), end: DateTime(2026, 9, 25)),
      );

      expect(plan, hasLength(4));
      expect(plan.every((b) => b.baslik == 'Ramazan Davulcusu'), isTrue);
      expect(plan.every((b) => b.id >= 200 && b.id <= 213), isTrue);
    });

    test('Ramazan açık ama aralık yoksa hiçbir şey kurulmaz', () {
      expect(_planla(hatirlaticilar: {'ramazan': acik}), isEmpty);
    });

    test(
        'her şey açıkken: 314 bildirim, id\'ler benzersiz, 500 sınırının altında',
        () {
      final plan = _planla(
        simdi: DateTime.utc(2026, 9, 19, 21), // bugünün her vakti ilerde
        hatirlaticilar: {
          for (final k in ['cuma', 'oruc', 'teheccut', 'ramazan']) k: acik,
        },
        vakitEzan: {
          for (final k in ReminderScheduler.vakitKeys)
            k: {'enabled': true, 'onceEnabled': true},
        },
        vaktindeKil: {
          for (final k in ReminderScheduler.vaktindeKilKeys) k: acik,
        },
        ramazan: (start: DateTime(2026, 9, 1), end: DateTime(2026, 12, 1)),
      );

      // ezan 84 + önce 84 + kıl 112 + teheccüt 14 + cuma 2 + oruç 4 + ramazan 14
      expect(plan, hasLength(314));
      expect(plan.map((b) => b.id).toSet(), hasLength(314));
      expect(
          plan.every((b) =>
              (b.id >= 1000 && b.id < 1500) || (b.id >= 200 && b.id <= 213)),
          isTrue);
    });

    test('bir bildirim, yenilemeler arasında aynı id\'yi taşır', () {
      final ayar = {'ogle': acik};
      final bugunPlani = _planla(vakitEzan: ayar);
      // Ertesi gün açıldı: bugun = 21.09.
      final yarinPlani = _planla(
          vakitEzan: ayar,
          bugun: DateTime.utc(2026, 9, 21),
          simdi: DateTime.utc(2026, 9, 21, 7));

      final ortak = _gunuBul(DateTime.utc(2026, 9, 25)).anlar[Vakit.ogle]!;
      int idOf(List<PlanliBildirim> plan) =>
          plan.firstWhere((b) => b.an == ortak).id;
      expect(idOf(bugunPlani), idOf(yarinPlani));
    });
  });

  group('ReminderScheduler.planla: Bildirimleri Ertele', () {
    final acik = {'enabled': true};

    test('ertelemeBitisinden önceki bildirimler üretilmez, sonrakiler üretilir',
        () {
      // Öğle ezanı her gün; 22.09 öğlesinden hemen sonrasına kadar ertelendi.
      final bitis = _gunuBul(DateTime.utc(2026, 9, 22))
          .anlar[Vakit.ogle]!
          .add(const Duration(minutes: 1));

      final plan = _planla(vakitEzan: {'ogle': acik}, ertelemeBitisi: bitis);

      // 20, 21, 22.09 öğleleri elendi; 23.09'dan itibaren 11 gün kaldı.
      expect(plan, hasLength(11));
      expect(plan.every((b) => !b.an.isBefore(bitis)), isTrue);
      expect(
          plan.first.an, _gunuBul(DateTime.utc(2026, 9, 23)).anlar[Vakit.ogle]);
    });

    test('bitişle tam aynı an dahildir (çalar)', () {
      final an = _gunuBul(DateTime.utc(2026, 9, 21)).anlar[Vakit.ogle]!;

      final plan = _planla(vakitEzan: {'ogle': acik}, ertelemeBitisi: an);

      expect(plan.first.an, an);
    });

    test('erteleme yoksa (null) hiçbir şey elenmez', () {
      expect(_planla(vakitEzan: {'ogle': acik}), hasLength(14));
    });

    test('bütün 14 günü kapsayan erteleme planı boşaltır', () {
      final plan = _planla(
          vakitEzan: {'ogle': acik, 'yatsi': acik},
          hatirlaticilar: {'cuma': acik, 'oruc': acik, 'teheccut': acik},
          ertelemeBitisi: DateTime.utc(2026, 12, 1));

      expect(plan, isEmpty);
    });
  });

  group('ReminderScheduler.farkHesapla', () {
    PlanliBildirim b(int id, {int an = 1000, String ses = 'uyari'}) =>
        PlanliBildirim(id, 'başlık', 'gövde',
            DateTime.fromMillisecondsSinceEpoch(an, isUtc: true), ses);

    test('sistem boşsa hepsi kurulur, iptal yok', () {
      final fark = ReminderScheduler.farkHesapla(
          plan: [b(1000), b(1001)], bekleyen: {}, tamZamanli: true);

      expect(fark.kurulacak.map((x) => x.id), [1000, 1001]);
      expect(fark.iptal, isEmpty);
    });

    test('parmak izi aynı olan bekleyen bildirim yeniden kurulmaz', () {
      final plan = [b(1000), b(1001)];
      final fark = ReminderScheduler.farkHesapla(
          plan: plan,
          bekleyen: {
            1000: plan[0].parmakIzi(true),
            1001: plan[1].parmakIzi(true),
          },
          tamZamanli: true);

      expect(fark.kurulacak, isEmpty);
      expect(fark.iptal, isEmpty);
    });

    test('an, ses ya da tam zamanlı izni değişince yeniden kurulur', () {
      final eski = b(1000);
      final bekleyen = {1000: eski.parmakIzi(true)};

      expect(
          ReminderScheduler.farkHesapla(
                  plan: [b(1000, an: 2000)],
                  bekleyen: bekleyen,
                  tamZamanli: true)
              .kurulacak,
          hasLength(1));
      expect(
          ReminderScheduler.farkHesapla(
                  plan: [b(1000, ses: 'beep')],
                  bekleyen: bekleyen,
                  tamZamanli: true)
              .kurulacak,
          hasLength(1));
      // İzin sonradan verildi ya da geri alındı.
      expect(
          ReminderScheduler.farkHesapla(
                  plan: [eski], bekleyen: bekleyen, tamZamanli: false)
              .kurulacak,
          hasLength(1));
    });

    test('sistemden silinmiş (zorla durdurma) bildirim yeniden kurulur', () {
      final plan = [b(1000), b(1001)];
      final fark = ReminderScheduler.farkHesapla(
          plan: plan,
          bekleyen: {1000: plan[0].parmakIzi(true)},
          tamZamanli: true);

      expect(fark.kurulacak.map((x) => x.id), [1001]);
    });

    test('plandan çıkan bizim id iptal edilir, başkasının id\'sine dokunulmaz',
        () {
      final fark = ReminderScheduler.farkHesapla(
        plan: [b(1000)],
        bekleyen: {
          1000: b(1000).parmakIzi(true),
          1005: 'x', // yeni aralık, planda yok
          300: null, // eski haftalık ezan
          101: null, // eski Cuma
          407: null, // eski Vaktinde Kıl
          229: null, // eski Ramazan
          5000: null, // başka bir özelliğin bildirimi
          9001: 'x', // başka
          1500: 'x', // aralığın dışı
        },
        tamZamanli: true,
      );

      expect(fark.iptal.toSet(), {1005, 300, 101, 407, 229});
    });

    test('eski bildirimin id\'si planda varsa (Ramazan 200) yeniden kurulur',
        () {
      // Eski kurulumdaki payload'sız bildirim, yeni planla eşleşmez.
      final fark = ReminderScheduler.farkHesapla(
          plan: [b(200)], bekleyen: {200: null}, tamZamanli: true);

      expect(fark.kurulacak.map((x) => x.id), [200]);
      expect(fark.iptal, isEmpty);
    });
  });

  group('ReminderScheduler.ramadanWindowFromEntries', () {
    final entries = [
      {
        'yil': 2025,
        'ay': 'Mart',
        'gunNo': '1',
        'baslik': "Ramazan'ın İlk Günü",
      },
      {
        'yil': 2025,
        'ay': 'Mart',
        'gunNo': '30',
        'baslik': 'Ramazan Bayramı',
      },
      {
        'yil': 2026,
        'ay': 'Şubat',
        'gunNo': '18',
        'baslik': "Ramazan'ın İlk Günü",
      },
      {
        'yil': 2026,
        'ay': 'Mart',
        'gunNo': '20',
        'baslik': 'Ramazan Bayramı',
      },
    ];

    test('returns the window that contains "today"', () {
      final window = ReminderScheduler.ramadanWindowFromEntries(
          entries, DateTime(2026, 3, 1));
      expect(window, isNotNull);
      expect(window!.start, DateTime(2026, 2, 18));
      expect(window.end, DateTime(2026, 3, 19));
    });

    test('returns the next upcoming window when today is before it', () {
      final window = ReminderScheduler.ramadanWindowFromEntries(
          entries, DateTime(2025, 6, 1));
      expect(window, isNotNull);
      expect(window!.start, DateTime(2026, 2, 18));
    });

    test('returns null when no window covers or follows "today"', () {
      final window = ReminderScheduler.ramadanWindowFromEntries(
          entries, DateTime(2026, 4, 1));
      expect(window, isNull);
    });

    test('falls back to a 29-day window when no Bayram entry is found', () {
      final noBayram = [
        {
          'yil': 2030,
          'ay': 'Ocak',
          'gunNo': '10',
          'baslik': "Ramazan'ın İlk Günü",
        },
      ];
      final window = ReminderScheduler.ramadanWindowFromEntries(
          noBayram, DateTime(2030, 1, 15));
      expect(window, isNotNull);
      expect(window!.start, DateTime(2030, 1, 10));
      expect(window.end, DateTime(2030, 2, 8));
    });
  });
}
