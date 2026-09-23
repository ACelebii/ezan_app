import 'dart:async';

import 'package:ezan_vakti_uygulamasi/core/utils/result.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/data/kuran_repository.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/data/sayfa_indirici.dart';
import 'package:ezan_vakti_uygulamasi/features/kuran/kuran_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

/// Yalnızca sağlayıcının çağırdığı üyeler. Ses listesi kurulunca çağrılar
/// kaydedilir (gerçek ses çalınmaz).
class SahteOynatici extends Fake implements AudioPlayer {
  int durdurma = 0;
  int oynatma = 0;

  /// Her `setAudioSources` çağrısındaki adresler ve başlangıç sırası.
  final kurulanListeler = <List<String>>[];
  final baslangicIndeksleri = <int?>[];
  final atlamalar = <int?>[];

  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();
  @override
  Stream<int?> get currentIndexStream => const Stream.empty();
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> setLoopMode(LoopMode mode) async {}
  @override
  Future<void> stop() async => durdurma++;
  @override
  Future<void> play() async => oynatma++;
  @override
  Future<void> seek(Duration? position, {int? index}) async =>
      atlamalar.add(index);
  @override
  Future<Duration?> setAudioSources(
    List<AudioSource> audioSources, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
    ShuffleOrder? shuffleOrder,
  }) async {
    kurulanListeler.add(
        [for (final k in audioSources) (k as UriAudioSource).uri.toString()]);
    baslangicIndeksleri.add(initialIndex);
    return null;
  }

  @override
  Future<void> dispose() async {}
}

SurahModel sahteSure(int id, String tr) => SurahModel(
    id: id,
    nameSimple: 'Sure$id',
    nameArabic: '',
    versesCount: 5,
    turkishName: tr);

/// Sesi olmayan ayet.
AyahModel sahteAyet(int id, String metin) => AyahModel(
    id: id,
    verseKey: '$id:1',
    textUthmani: metin,
    translation: '',
    audioUrl: '',
    pageNumber: 1);

/// [sure]:[no] ayeti; sesi ve meali vardır.
AyahModel sesliAyet(int sure, int no) => AyahModel(
    id: sure * 1000 + no,
    verseKey: '$sure:$no',
    textUthmani: 'ayet-$no',
    translation: 'meal-$no',
    translationEn: 'english-$no',
    audioUrl: 'https://ses.test/$sure-$no.mp3',
    pageNumber: 1);

/// Meal aramasında kullanılan ayet ([tr] Diyanet, [en] Saheeh International).
AyahModel aramaAyeti(int sure, int no, String tr, [String en = '']) => AyahModel(
    id: sure * 1000 + no,
    verseKey: '$sure:$no',
    textUthmani: 'ar-$no',
    translation: tr,
    translationEn: en,
    audioUrl: '',
    pageNumber: 1);

/// Her ayet yükleme çağrısı, testin elle tamamlayacağı bir [Completer] bekler
/// (ya da [hazirSureler]de varsa hemen döner). [onbellek] cihazdaki kayıtlı
/// sureleri, [hataSure] indirilirken hata verecek sureyi temsil eder.
class SahteDeposu extends KuranRepository {
  SahteDeposu({List<SurahModel>? sureler})
      : sureler = sureler ?? [sahteSure(1, 'Fâtiha'), sahteSure(2, 'Bakara')];

  final List<SurahModel> sureler;
  final sureIstekleri = <int, Completer<Result<List<AyahModel>>>>{};
  final okuyucular = <int>[];
  final onbellek = <int, List<AyahModel>>{};
  final hazirSureler = <int, List<AyahModel>>{};
  final indirilenler = <int>[];
  int? hataSure;

  @override
  Future<Set<int>> onbellekliSureler() async => onbellek.keys.toSet();

  @override
  Future<List<AyahModel>?> sureOnbellekten(int sureId) async => onbellek[sureId];

  @override
  Future<Result<List<SurahModel>>> getSurahs() async => Success(sureler);

  @override
  Future<Result<List<AyahModel>>> getAyahsBySurah(int surahId, int reciterId) {
    okuyucular.add(reciterId);
    if (hataSure == surahId) {
      return Future.value(Failure('Sure ayetleri yüklenemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.'));
    }
    final hazir = hazirSureler[surahId];
    if (hazir != null) {
      indirilenler.add(surahId);
      onbellek[surahId] = hazir;
      return Future.value(Success(hazir));
    }
    return (sureIstekleri[surahId] = Completer()).future;
  }

  @override
  Future<Result<List<AyahModel>>> getAyahsByJuz(
          int juzId, int reciterId) async =>
      Success([sahteAyet(juzId, 'cuz')]);
}

/// Ağa/diske dokunmadan, verilen sayıda sayfayı adım adım "indiren" sahte depo.
class SahteSayfalar implements SayfaDeposu {
  SahteSayfalar({this.baslangic = 0, this.toplam = 10});

  int baslangic;
  final int toplam;
  Object? hata;
  bool okumaHatasi = false;

  /// Her sayfa indirmesi, testin tamamlayacağı bir kapıyı bekler (null: beklemez).
  Completer<void>? kapi;
  int cagri = 0;

  /// Son çağrıda istenen [sayfalar] (kısmi indirme testleri için); tüm kitap
  /// istenmişse null.
  Iterable<int>? sonIstenenSayfalar;

  @override
  Future<int> indirilenSayisi() async {
    if (okumaHatasi) throw StateError('db kapalı');
    return baslangic;
  }

  @override
  Future<void> eksikleriIndir({
    Iterable<int>? sayfalar,
    void Function(int biten, int toplam)? ilerleme,
    bool Function()? iptalMi,
  }) async {
    cagri++;
    sonIstenenSayfalar = sayfalar;
    // Gerçek SayfaIndirici gibi: [sayfalar] verilirse yalnız o kadarı (en
    // fazla) "eksik" sayılır; verilmezse kitabın tamamı tamamlanana kadar sürer.
    var kalan = sayfalar?.length ?? (toplam - baslangic);
    ilerleme?.call(baslangic, toplam);
    while (kalan > 0 && baslangic < toplam) {
      if (iptalMi?.call() ?? false) return;
      if (kapi != null) await kapi!.future;
      if (hata != null) throw hata!;
      baslangic++;
      kalan--;
      ilerleme?.call(baslangic, toplam);
      await Future<void>.delayed(Duration.zero);
    }
  }
}
