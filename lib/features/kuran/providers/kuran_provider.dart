import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/result.dart';
import '../data/kuran_arama_indeksi.dart';
import '../data/kuran_kayitlari.dart';
import '../data/kuran_repository.dart';
import '../data/sayfa_indirici.dart';
import '../kuran_download_service.dart';
import '../kuran_models.dart';
import '../../../locator.dart';

class KuranProvider extends ChangeNotifier {
  /// [repo], [audioPlayer] ve [sayfalar] testte sahte vermek içindir.
  /// [ingilizceMi] uygulama dili İngilizce mi diye sorar (sure adı ve başlıklar
  /// buna göre üretilir).
  KuranProvider(
      {KuranRepository? repo,
      AudioPlayer? audioPlayer,
      SayfaDeposu? sayfalar,
      bool Function()? ingilizceMi})
      : _repo = repo ?? locator<KuranRepository>(),
        audioPlayer = audioPlayer ?? AudioPlayer(),
        _sayfalarVerilen = sayfalar,
        _ingilizceMi = ingilizceMi ?? (() => false) {
    _initAudio();
    fetchSurahs();
    fetchJuzs();
    _loadSavedBookmark();
    _loadSavedPreferences();
    _kayitlariYukle();
  }

  final KuranRepository _repo;
  final AudioPlayer audioPlayer;
  final bool Function() _ingilizceMi;
  final SayfaDeposu? _sayfalarVerilen;

  /// Mushaf sayfa görsellerinin cihaz önbelleği. Varsayılan tembel çözülür:
  /// sayfa indirme kullanılmadıkça SQLite'a/ağa dokunulmaz.
  SayfaDeposu get _sayfalar =>
      _sayfalarVerilen ?? KuranDownloadService.varsayilan;

  /// Ekranda görünen sure adı: İngilizcede Latin yazım ("Al-Baqarah"), yoksa
  /// Türkçe ad ("Bakara").
  String sureAdi(SurahModel s) =>
      _ingilizceMi() && s.nameSimple.isNotEmpty ? s.nameSimple : s.displayName;

  /// [id]. surenin görünen adı; liste henüz yüklenmediyse [yedek].
  String sureAdiId(int id, [String yedek = '']) {
    for (final s in surahs) {
      if (s.id == id) return sureAdi(s);
    }
    return yedek;
  }

  static const _ingilizceMealAdi = 'Saheeh International';

  /// Ayette gösterilecek meal: İngilizce arayüzde Saheeh International (varsa),
  /// yoksa Türkçe (Diyanet, eksikse Elmalılı).
  String mealMetni(AyahModel a) => _ingilizceMi() && a.translationEn.isNotEmpty
      ? a.translationEn
      : a.translation;

  /// [mealMetni]nin kaynak etiketi.
  String mealKaynagiEtiketi(AyahModel a) =>
      _ingilizceMi() && a.translationEn.isNotEmpty
          ? _ingilizceMealAdi
          : a.mealKaynagi;

  // ---------------- Tüm Kur'an'da meal arama ----------------

  final _indeks = KuranAramaIndeksi();

  /// Cihazdan okunan surelerin indeksi hazırlanıyor.
  bool aramaHazirlaniyor = false;

  /// Aramaya hazır (cihazda kayıtlı) sure sayısı (en çok 114).
  int get aramadakiSureSayisi => _indeks.sureSayisi;

  /// "Tümünü indir" çalışıyor.
  bool tumKuranIndiriliyor = false;

  /// Son indirme hatası (kullanıcı metni); yoksa null.
  String? indirmeHatasi;

  /// Cihazda kayıtlı surelerin meallerini aramaya hazırlar (internet gerekmez).
  Future<void> aramaIndeksiniHazirla() async {
    if (aramaHazirlaniyor) return;
    aramaHazirlaniyor = true;
    notifyListeners();
    try {
      final kayitli = (await _repo.onbellekliSureler()).toList()..sort();
      for (final id in kayitli) {
        if (_indeks.sureVar(id)) continue;
        final ayetler = await _repo.sureOnbellekten(id);
        if (ayetler != null && ayetler.isNotEmpty) {
          _indeks.sureEkle(id, ayetler);
        }
        // Arayüz donmasın: her sureden sonra sıradaki işlere yer bırak.
        await Future<void>.delayed(Duration.zero);
      }
    } finally {
      aramaHazirlaniyor = false;
      notifyListeners();
    }
  }

  /// Henüz cihazda olmayan bütün sureleri indirir (sırayla; ilk hatada durur,
  /// tekrar çağrılınca kaldığı yerden devam eder). Böylece meal araması tüm
  /// Kur'an'ı kapsar ve internetsiz çalışır.
  Future<void> tumKuraniIndir() async {
    if (tumKuranIndiriliyor) return;
    tumKuranIndiriliyor = true;
    indirmeHatasi = null;
    notifyListeners();
    try {
      final okuyucu = hafizList[selectedHafizName]!;
      for (var id = 1; id <= 114; id++) {
        if (_indeks.sureVar(id)) continue;
        final r = await _repo.getAyahsBySurah(id, okuyucu);
        final ayetler = r.data;
        if (r is Success<List<AyahModel>> &&
            ayetler != null &&
            ayetler.isNotEmpty) {
          _indeks.sureEkle(id, ayetler);
          notifyListeners();
        } else {
          indirmeHatasi = r.errorMessage ?? 'Sure ayetleri yüklenemedi.';
          break;
        }
      }
    } finally {
      tumKuranIndiriliyor = false;
      notifyListeners();
    }
  }

  // ---------------- Mushaf sayfa görselleri (Resim görünümü) ----------------

  /// Cihazdaki sağlam sayfa görseli sayısı (0..[kuranSayfaSayisi]).
  int sayfaCihazda = 0;

  /// "Tüm sayfaları indir" çalışıyor.
  bool sayfalarIndiriliyor = false;

  /// Son sayfa indirme hatası (kullanıcı metni); yoksa null.
  String? sayfaHatasi;

  bool _sayfaDurdur = false;

  /// Cihazdaki sayfa sayısını okur (ekran açılırken).
  Future<void> sayfaDurumunuYukle() async {
    try {
      sayfaCihazda = await _sayfalar.indirilenSayisi();
    } catch (e) {
      debugPrint('Sayfa durumu okunamadı: $e');
    }
    notifyListeners();
  }

  /// Cihazda olmayan bütün sayfa görsellerini indirir (Resim görünümü
  /// internetsiz çalışsın diye). İlk hatada durur, tekrar çağrılınca kalandan
  /// sürer; [sayfaIndirmesiniDurdur] hata vermeden durdurur.
  Future<void> tumSayfalariIndir() => _sayfalariIndir();

  /// Yalnızca şu an açık olan sure/cüz/sayfanın görsellerini indirir; tüm
  /// kitabı beklemeden o kısım internetsiz çalışsın diye. Zaten cihazdaysa
  /// hızlıca hiçbir şey yapmadan döner.
  Future<void> acikSayfalariIndir() => _sayfalariIndir(
      sayfalar: currentAyahs.map((a) => a.pageNumber).toSet());

  Future<void> _sayfalariIndir({Iterable<int>? sayfalar}) async {
    if (sayfalarIndiriliyor || (sayfalar != null && sayfalar.isEmpty)) return;
    sayfalarIndiriliyor = true;
    sayfaHatasi = null;
    _sayfaDurdur = false;
    notifyListeners();
    try {
      await _sayfalar.eksikleriIndir(
        sayfalar: sayfalar,
        ilerleme: (biten, _) {
          sayfaCihazda = biten;
          notifyListeners();
        },
        iptalMi: () => _sayfaDurdur,
      );
    } catch (e) {
      debugPrint('Sayfa indirme hatası: $e');
      sayfaHatasi = 'Sayfa görselleri indirilemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.';
    } finally {
      sayfalarIndiriliyor = false;
      notifyListeners();
    }
  }

  void sayfaIndirmesiniDurdur() => _sayfaDurdur = true;

  /// Meal araması (uygulama dilindeki meal): cihazdaki TÜM surelerde.
  AramaSayfasi mealAra(String sorgu) =>
      _indeks.ara(sorgu, ingilizce: _ingilizceMi());

  /// Favori/Not kartındaki meal (kayıttaki dile göre; eski kayıtta Türkçe).
  String kartMeali(AyetKaydi k) =>
      _ingilizceMi() && k.mealEn.isNotEmpty ? k.mealEn : k.meal;

  /// "Bakara Suresi" / "Surah Al-Baqarah", "30. Cüz" / "Juz 30", "12. Sayfa" /
  /// "Page 12". Uygulama dili değişince kendiliğinden güncellenir.
  String _baslik(String tur, int id, {bool? ingilizce}) {
    final en = ingilizce ?? _ingilizceMi();
    switch (tur) {
      case 'surah':
        final ad =
            ingilizce == null ? sureAdiId(id) : _sureBul(id)?.displayName ?? '';
        if (ad.isEmpty) return '';
        return en ? 'Surah $ad' : '$ad Suresi';
      case 'juz':
        return en ? 'Juz $id' : '$id. Cüz';
      case 'page':
        return en ? 'Page $id' : '$id. Sayfa';
    }
    return '';
  }

  SurahModel? _sureBul(int id) {
    for (final s in surahs) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Açık sure/cüz/sayfanın başlığı.
  String get activeTitle {
    if (activeSurah != null) return _baslik('surah', activeSurah!.id);
    if (activeJuz != null) return _baslik('juz', activeJuz!);
    if (activePage != null) return _baslik('page', activePage!);
    return '';
  }

  /// Son başlatılan sure/cüz/sayfa yüklemesinin numarası. Kullanıcı hızlıca
  /// başka bir yere geçerse, eski yüklemenin geç gelen yanıtı yenisini ezmez.
  int _yuklemeNo = 0;

  bool isSurahListLoading = true;
  bool isJuzListLoading = true;
  List<SurahModel> surahs = [];
  List<int> juzs = [];
  String? errorMessage;

  bool isAyahsLoading = false;
  List<AyahModel> currentAyahs = [];

  SurahModel? activeSurah;
  int? activeJuz;
  int? activePage;

  int? activeAyahId;
  bool isPlaying = false;
  bool isRepeatOne = false; // YENİ: Tekrar Modu Durumu
  double speed = 1.0;
  double volume = 0.5;
  double brightness = 0.5;

  /// Favori işaretli ve/veya notlu ayetler (sure/ayet sırasında).
  List<AyetKaydi> ayetKayitlari = [];

  /// Okuma listesi (eklenme sırasında).
  List<OkumaOgesi> okumaListesi = [];

  /// Bir ayete gidildiğinde (Favori/Not) liste ekranının kaydıracağı
  /// `currentAyahs` indeksi; ekran kaydırınca [hedefiTemizle] ile silinir.
  int? hedefAyetIndex;

  /// Ezberleme çalma listesi (seçili aralık, ayet başına tekrarlı) kurulu mu.
  bool ezberModu = false;

  /// Bir ezberleme oturumunun en çok kaç ayet çalması (aralık x tekrar).
  static const enFazlaEzberCalma = 300;

  bool isBookmarked = false;

  String? savedBookmarkType;
  int? savedBookmarkId;

  /// Diske yazılan (Türkçe) başlık; liste yüklenmeden önce yedek olarak gösterilir.
  String? _kayitliBaslik;

  /// Yer iminin başlığı (uygulama diline göre); yer imi yoksa null.
  String? get savedBookmarkTitle {
    if (savedBookmarkType == null || savedBookmarkId == null) return null;
    final b = _baslik(savedBookmarkType!, savedBookmarkId!);
    return b.isNotEmpty ? b : _kayitliBaslik;
  }

  final Map<String, int> hafizList = {
    "Abdul Basit": 1,
    "Mishary Alafasy": 7,
    "Husary": 12,
    "Südais": 3,
  };
  String selectedHafizName = "Abdul Basit";

  /// just_audio çalma listesindeki her sıranın [currentAyahs] içindeki
  /// gerçek indeksi. Sesi olmayan ayetler çalma listesine hiç girmediği
  /// için bu eşleme olmadan `currentIndexStream`/`playSingleAyah` yanlış
  /// ayeti işaretler/çalar.
  List<int> _playlistAyahIndexes = [];

  int _bgIndex = 2;
  int get bgIndex => _bgIndex;
  String _pageStyle = "Resim";
  String get pageStyle => _pageStyle;
  String _ayahTrackingStyle = "Renk";
  String get ayahTrackingStyle => _ayahTrackingStyle;

  Color get backgroundColor {
    switch (_bgIndex) {
      case 0:
        return const Color(0xFF121212);
      case 1:
        return const Color(0xFFEFE8D6);
      case 2:
        return const Color(0xFF1B3B24);
      case 3:
        return const Color(0xFFFFFFFF);
      default:
        return const Color(0xFF1B3B24);
    }
  }

  Color get textColor =>
      (_bgIndex == 1 || _bgIndex == 3) ? Colors.black87 : Colors.white;

  Future<void> _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _bgIndex = prefs.getInt('kuran_bg_index') ?? _bgIndex;
    _pageStyle = prefs.getString('kuran_page_style') ?? _pageStyle;
    _ayahTrackingStyle =
        prefs.getString('kuran_ayah_tracking_style') ?? _ayahTrackingStyle;
    selectedHafizName =
        prefs.getString('kuran_hafiz_name') ?? selectedHafizName;
    volume = prefs.getDouble('kuran_volume') ?? volume;
    brightness = prefs.getDouble('kuran_brightness') ?? brightness;
    speed = prefs.getDouble('kuran_speed') ?? speed;
    audioPlayer.setVolume(volume);
    audioPlayer.setSpeed(speed);
    notifyListeners();
  }

  Future<void> _savePreference(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
  }

  void _initAudio() {
    audioPlayer.playerStateStream.listen((state) {
      isPlaying = state.playing;
      notifyListeners();
    });
    audioPlayer.currentIndexStream.listen((playlistIndex) {
      if (playlistIndex != null &&
          playlistIndex >= 0 &&
          playlistIndex < _playlistAyahIndexes.length) {
        final ayahIndex = _playlistAyahIndexes[playlistIndex];
        if (ayahIndex < currentAyahs.length) {
          activeAyahId = currentAyahs[ayahIndex].id;
          notifyListeners();
        }
      }
    });
  }

  Future<void> _loadSavedBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    savedBookmarkType = prefs.getString('bookmark_type');
    savedBookmarkId = prefs.getInt('bookmark_id');
    _kayitliBaslik = prefs.getString('bookmark_title');
    _checkIfCurrentIsBookmarked();
    notifyListeners();
  }

  void _checkIfCurrentIsBookmarked() {
    if (savedBookmarkType == 'surah' && activeSurah?.id == savedBookmarkId) {
      isBookmarked = true;
    } else if (savedBookmarkType == 'juz' && activeJuz == savedBookmarkId) {
      isBookmarked = true;
    } else if (savedBookmarkType == 'page' && activePage == savedBookmarkId) {
      isBookmarked = true;
    } else {
      isBookmarked = false;
    }
  }

  void clearError() {
    errorMessage = null;
  }

  Future<void> fetchSurahs() async {
    isSurahListLoading = true;
    notifyListeners();
    final result = await _repo.getSurahs();
    if (result is Success<List<SurahModel>>) {
      surahs = result.data ?? [];
    } else if (result is Failure<List<SurahModel>>) {
      errorMessage = result.errorMessage;
    }
    isSurahListLoading = false;
    notifyListeners();
  }

  Future<void> fetchJuzs() async {
    isJuzListLoading = true;
    notifyListeners();
    final result = await _repo.getJuzList();
    if (result is Success<List<int>>) {
      juzs = result.data ?? [];
    }
    isJuzListLoading = false;
    notifyListeners();
  }

  /// [ayetNo] verilirse (Favori/Not'tan gelişte) o ayet vurgulanır, liste
  /// oraya kaydırılır ve ses o ayetten başlar.
  Future<void> loadSurahDetails(SurahModel surah, {int? ayetNo}) async {
    activeSurah = surah;
    activeJuz = null;
    activePage = null;
    isAyahsLoading = true;
    currentAyahs = [];
    errorMessage = null;

    final no = ++_yuklemeNo;
    audioPlayer.stop();
    _checkIfCurrentIsBookmarked();
    notifyListeners();

    final result =
        await _repo.getAyahsBySurah(surah.id, hafizList[selectedHafizName]!);
    if (no != _yuklemeNo) return; // daha yeni bir yükleme başladı
    if (result is Success<List<AyahModel>>) {
      currentAyahs = result.data ?? [];
    } else if (result is Failure<List<AyahModel>>) {
      errorMessage = result.errorMessage;
    }

    if (currentAyahs.isNotEmpty) _indeks.sureEkle(surah.id, currentAyahs);

    var baslangic = 0;
    hedefAyetIndex = null;
    if (ayetNo != null) {
      final i =
          currentAyahs.indexWhere((a) => a.verseKey == '${surah.id}:$ayetNo');
      if (i >= 0) {
        baslangic = i;
        hedefAyetIndex = i;
        activeAyahId = currentAyahs[i].id;
      }
    }

    isAyahsLoading = false;
    notifyListeners();
    Future.microtask(() => _setupPlaylist(ayetIndeksi: baslangic));
  }

  Future<void> loadJuzDetails(int juzNumber) async {
    activeJuz = juzNumber;
    activeSurah = null;
    activePage = null;
    isAyahsLoading = true;
    currentAyahs = [];
    hedefAyetIndex = null;
    errorMessage = null;

    final no = ++_yuklemeNo;
    audioPlayer.stop();
    _checkIfCurrentIsBookmarked();
    notifyListeners();

    final result =
        await _repo.getAyahsByJuz(juzNumber, hafizList[selectedHafizName]!);
    if (no != _yuklemeNo) return; // daha yeni bir yükleme başladı
    if (result is Success<List<AyahModel>>) {
      currentAyahs = result.data ?? [];
    } else if (result is Failure<List<AyahModel>>) {
      errorMessage = result.errorMessage;
    }

    isAyahsLoading = false;
    notifyListeners();
    Future.microtask(() => _setupPlaylist());
  }

  Future<void> loadPageDetails(int pageNumber) async {
    activePage = pageNumber;
    activeSurah = null;
    activeJuz = null;
    isAyahsLoading = true;
    currentAyahs = [];
    hedefAyetIndex = null;
    errorMessage = null;

    final no = ++_yuklemeNo;
    audioPlayer.stop();
    _checkIfCurrentIsBookmarked();
    notifyListeners();

    final result =
        await _repo.getAyahsByPage(pageNumber, hafizList[selectedHafizName]!);
    if (no != _yuklemeNo) return; // daha yeni bir yükleme başladı
    if (result is Success<List<AyahModel>>) {
      currentAyahs = result.data ?? [];
    } else if (result is Failure<List<AyahModel>>) {
      errorMessage = result.errorMessage;
    }

    isAyahsLoading = false;
    notifyListeners();
    Future.microtask(() => _setupPlaylist());
  }

  Future<void> _setupPlaylist({int ayetIndeksi = 0}) async {
    _playlistAyahIndexes = [];
    ezberModu = false;
    if (currentAyahs.isEmpty) return;
    try {
      final sources = <AudioSource>[];
      for (var i = 0; i < currentAyahs.length; i++) {
        if (currentAyahs[i].audioUrl.isNotEmpty) {
          _playlistAyahIndexes.add(i);
          sources.add(AudioSource.uri(Uri.parse(currentAyahs[i].audioUrl)));
        }
      }
      if (sources.isEmpty) return;
      final bas = _playlistAyahIndexes.indexOf(ayetIndeksi);
      await audioPlayer.setAudioSources(sources,
          initialIndex: bas < 0 ? 0 : bas, initialPosition: Duration.zero);
      // Eğer repeat açıksa yeni listede de aktif et
      await audioPlayer.setLoopMode(isRepeatOne ? LoopMode.one : LoopMode.off);
    } catch (e) {
      debugPrint("Ses yükleme hatası: $e");
    }
  }

  Future<void> togglePlay() async {
    if (isPlaying) {
      await audioPlayer.pause();
    } else {
      await audioPlayer.play();
    }
  }

  // YENİ: Stop Tuşu İşlevi
  Future<void> stopAudio() async {
    await audioPlayer.stop();
    activeAyahId = null; // Ayet vurgusunu temizle
    notifyListeners();
  }

  // YENİ: Repeat (Tekrar) Tuşu İşlevi
  Future<void> toggleRepeat() async {
    isRepeatOne = !isRepeatOne;
    await audioPlayer.setLoopMode(isRepeatOne ? LoopMode.one : LoopMode.off);
    notifyListeners();
  }

  /// [index] `currentAyahs` içindeki konumdur (UI listeleri bu diziyi
  /// gösterir). Sesi olmayan bir ayete tıklanırsa sessizce yok sayılır.
  Future<void> playSingleAyah(int index) async {
    if (index < 0 || index >= currentAyahs.length) return;
    // Ezberleme aralığının dışındaki bir ayete dokunulduysa tam listeyi kur.
    if (ezberModu && !_playlistAyahIndexes.contains(index)) {
      await _setupPlaylist(ayetIndeksi: index);
    }
    final playlistIndex = _playlistAyahIndexes.indexOf(index);
    if (playlistIndex == -1) return;
    activeAyahId = currentAyahs[index].id;
    notifyListeners();
    await audioPlayer.seek(Duration.zero, index: playlistIndex);
    audioPlayer.play();
  }

  Future<void> toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();

    if (isBookmarked) {
      isBookmarked = false;
      savedBookmarkType = null;
      savedBookmarkId = null;
      _kayitliBaslik = null;
      await prefs.remove('bookmark_type');
      await prefs.remove('bookmark_id');
      await prefs.remove('bookmark_title');
    } else {
      isBookmarked = true;
      if (activeSurah != null) {
        savedBookmarkType = 'surah';
        savedBookmarkId = activeSurah!.id;
      } else if (activeJuz != null) {
        savedBookmarkType = 'juz';
        savedBookmarkId = activeJuz;
      } else if (activePage != null) {
        savedBookmarkType = 'page';
        savedBookmarkId = activePage;
      }
      // Diske Türkçe (dilden bağımsız) başlık yazılır; ekranda dile göre üretilir.
      _kayitliBaslik = _baslik(savedBookmarkType ?? '', savedBookmarkId ?? 0,
          ingilizce: false);

      if (savedBookmarkType != null) {
        await prefs.setString('bookmark_type', savedBookmarkType!);
        await prefs.setInt('bookmark_id', savedBookmarkId!);
        await prefs.setString('bookmark_title', _kayitliBaslik!);
      }
    }
    notifyListeners();
  }

  Future<bool> goToBookmark() async {
    if (savedBookmarkType == null || savedBookmarkId == null) return false;

    if (savedBookmarkType == 'surah') {
      try {
        final surah = surahs.firstWhere((s) => s.id == savedBookmarkId);
        await loadSurahDetails(surah);
        return true;
      } catch (e) {
        return false;
      }
    } else if (savedBookmarkType == 'juz') {
      await loadJuzDetails(savedBookmarkId!);
      return true;
    } else if (savedBookmarkType == 'page') {
      await loadPageDetails(savedBookmarkId!);
      return true;
    }
    return false;
  }

  void changeSpeed() {
    if (speed == 1.0) {
      speed = 1.25;
    } else if (speed == 1.25) {
      speed = 1.5;
    } else if (speed == 1.5) {
      speed = 2.0;
    } else {
      speed = 1.0;
    }
    audioPlayer.setSpeed(speed);
    _savePreference('kuran_speed', speed);
    notifyListeners();
  }

  void setBgIndex(int index) {
    _bgIndex = index;
    _savePreference('kuran_bg_index', index);
    notifyListeners();
  }

  void setPageStyle(String style) {
    _pageStyle = style;
    _savePreference('kuran_page_style', style);
    notifyListeners();
  }

  void setAyahTrackingStyle(String style) {
    _ayahTrackingStyle = style;
    _savePreference('kuran_ayah_tracking_style', style);
    notifyListeners();
  }

  void changeHafiz(String name) {
    selectedHafizName = name;
    _savePreference('kuran_hafiz_name', name);
    notifyListeners();
    yenidenYukle();
  }

  /// Açık olan sure/cüz/sayfayı yeniden yükler (hafız değişince ya da yükleme
  /// hatasından sonra "Tekrar Dene"). Açık bir şey yoksa bir şey yapmaz.
  Future<void> yenidenYukle() async {
    if (activeSurah != null) {
      await loadSurahDetails(activeSurah!);
    } else if (activeJuz != null) {
      await loadJuzDetails(activeJuz!);
    } else if (activePage != null) {
      await loadPageDetails(activePage!);
    }
  }

  void setVolume(double val) {
    volume = val;
    audioPlayer.setVolume(val);
    _savePreference('kuran_volume', val);
    notifyListeners();
  }

  void setBrightness(double val) {
    brightness = val;
    _savePreference('kuran_brightness', val);
    notifyListeners();
  }

  // ---------------- Favori, not, okuma listesi ----------------

  Future<void> _kayitlariYukle() async {
    ayetKayitlari = await KuranKayitlari.ayetleriOku();
    okumaListesi = await KuranKayitlari.okumaOku();
    notifyListeners();
  }

  AyetKaydi? kayit(AyahModel a) {
    for (final k in ayetKayitlari) {
      if (k.verseKey == a.verseKey) return k;
    }
    return null;
  }

  bool favoriMi(AyahModel a) => kayit(a)?.favori ?? false;

  String notu(AyahModel a) => kayit(a)?.not ?? '';

  /// [a] için kayıt (yoksa henüz saklanmamış boş bir kayıt).
  AyetKaydi ayetKaydi(AyahModel a) {
    final k = kayit(a);
    if (k == null) {
      return AyetKaydi(
          verseKey: a.verseKey,
          sureAdi: _sureAdi(a.verseKey),
          arapca: a.textUthmani,
          meal: a.translation,
          mealEn: a.translationEn);
    }
    // Eski kayıtta İngilizce meal yoktu: ayet şimdi yüklüyse tamamlanır.
    return k.mealEn.isEmpty && a.translationEn.isNotEmpty
        ? k.kopya(mealEn: a.translationEn)
        : k;
  }

  String _sureAdi(String verseKey) {
    final id = int.tryParse(verseKey.split(':').first);
    for (final s in surahs) {
      if (s.id == id) return s.displayName;
    }
    return '';
  }

  /// [k] kaydının favori işaretini ve/veya notunu değiştirir; ikisi de
  /// boşalırsa kayıt silinir. ([not] boş metin = notu sil.)
  Future<void> kayitDegistir(AyetKaydi k, {bool? favori, String? not}) async {
    final yeni = k.kopya(favori: favori, not: not?.trim());
    ayetKayitlari = [
      for (final e in ayetKayitlari)
        if (e.verseKey != k.verseKey) e,
      if (!yeni.bos) yeni,
    ]..sort((a, b) =>
        a.sureId != b.sureId ? a.sureId - b.sureId : a.ayetNo - b.ayetNo);
    notifyListeners();
    await KuranKayitlari.ayetleriYaz(ayetKayitlari);
  }

  Future<void> okumayaEkle(int sureId) async {
    if (okumaListesi.any((o) => o.sureId == sureId)) return;
    okumaListesi = [...okumaListesi, OkumaOgesi(sureId: sureId)];
    notifyListeners();
    await KuranKayitlari.okumaYaz(okumaListesi);
  }

  Future<void> okumadanCikar(int sureId) async {
    okumaListesi = [
      for (final o in okumaListesi)
        if (o.sureId != sureId) o
    ];
    notifyListeners();
    await KuranKayitlari.okumaYaz(okumaListesi);
  }

  Future<void> okunduDegistir(int sureId) async {
    okumaListesi = [
      for (final o in okumaListesi)
        o.sureId == sureId ? o.kopya(okundu: !o.okundu) : o
    ];
    notifyListeners();
    await KuranKayitlari.okumaYaz(okumaListesi);
  }

  /// Liste ekranı kaydırmayı yaptıktan sonra çağırır (yeniden çizim istemez).
  void hedefiTemizle() => hedefAyetIndex = null;

  /// Açık listeyi [index]. ayete (`currentAyahs` indeksi) kaydırır ve vurgular
  /// (Meal aramasından).
  void ayeteKaydir(int index) {
    if (index < 0 || index >= currentAyahs.length) return;
    hedefAyetIndex = index;
    activeAyahId = currentAyahs[index].id;
    notifyListeners();
  }

  // ---------------- Ezberleme ----------------

  /// `currentAyahs` içinde [ilk]..[son] (dahil) aralığındaki her ayeti [tekrar]
  /// kez art arda çalar. Başarılıysa null, değilse kullanıcıya gösterilecek
  /// hata metnini döndürür.
  Future<String?> ezberle(int ilk, int son, int tekrar) async {
    final aralik = <int>[
      if (ilk >= 0 && son < currentAyahs.length && ilk <= son)
        for (var i = ilk; i <= son; i++)
          if (currentAyahs[i].audioUrl.isNotEmpty) i,
    ];
    if (aralik.isEmpty || tekrar < 1) {
      return 'Seçilen aralıkta çalınacak sesli ayet yok.';
    }
    if (aralik.length * tekrar > enFazlaEzberCalma) {
      return 'Aralık ve tekrar sayısı çok büyük '
          '(${aralik.length} ayet x $tekrar = ${aralik.length * tekrar} çalma; '
          'en çok $enFazlaEzberCalma). Aralığı daraltın ya da tekrarı azaltın.';
    }
    final sira = [
      for (final i in aralik)
        for (var k = 0; k < tekrar; k++) i
    ];
    try {
      await audioPlayer.setAudioSources([
        for (final i in sira)
          AudioSource.uri(Uri.parse(currentAyahs[i].audioUrl))
      ], initialIndex: 0, initialPosition: Duration.zero);
      await audioPlayer.setLoopMode(LoopMode.off);
    } catch (e) {
      debugPrint('Ezberleme sesi yüklenemedi: $e');
      return 'Ses yüklenemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.';
    }
    _playlistAyahIndexes = sira;
    isRepeatOne = false;
    ezberModu = true;
    notifyListeners();
    audioPlayer.play();
    return null;
  }

  /// Ezberleme aralığını bırakıp sure/cüz/sayfanın tam çalma listesine döner.
  Future<void> ezberiBitir() async {
    await audioPlayer.stop();
    await _setupPlaylist();
    activeAyahId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
}
