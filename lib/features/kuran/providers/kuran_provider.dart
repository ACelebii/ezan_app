import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/result.dart';
import '../data/kuran_repository.dart';
import '../kuran_models.dart';
import '../../../locator.dart';

class KuranProvider extends ChangeNotifier {
  final KuranRepository _repo = locator<KuranRepository>();
  final AudioPlayer audioPlayer = AudioPlayer();

  bool isSurahListLoading = true;
  bool isJuzListLoading = true;
  List<SurahModel> surahs = [];
  List<int> juzs = [];
  String? errorMessage;

  bool isAyahsLoading = false;
  List<AyahModel> currentAyahs = [];

  String activeTitle = "";
  SurahModel? activeSurah;
  int? activeJuz;
  int? activePage;

  int? activeAyahId;
  bool isPlaying = false;
  bool isRepeatOne = false; // YENİ: Tekrar Modu Durumu
  double speed = 1.0;
  double volume = 0.5;
  double brightness = 0.5;

  bool isBookmarked = false;

  String? savedBookmarkType;
  int? savedBookmarkId;
  String? savedBookmarkTitle;

  final Map<String, int> hafizList = {
    "Abdul Basit": 1,
    "Mishary Alafasy": 7,
    "Husary": 12,
    "Südais": 3,
  };
  String selectedHafizName = "Abdul Basit";

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

  KuranProvider() {
    _initAudio();
    fetchSurahs();
    fetchJuzs();
    _loadSavedBookmark();
  }

  void _initAudio() {
    audioPlayer.playerStateStream.listen((state) {
      isPlaying = state.playing;
      notifyListeners();
    });
    audioPlayer.currentIndexStream.listen((index) {
      if (index != null &&
          currentAyahs.isNotEmpty &&
          index < currentAyahs.length) {
        activeAyahId = currentAyahs[index].id;
        notifyListeners();
      }
    });
  }

  Future<void> _loadSavedBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    savedBookmarkType = prefs.getString('bookmark_type');
    savedBookmarkId = prefs.getInt('bookmark_id');
    savedBookmarkTitle = prefs.getString('bookmark_title');
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

  Future<void> loadSurahDetails(SurahModel surah) async {
    activeSurah = surah;
    activeJuz = null;
    activePage = null;
    activeTitle = "${surah.nameSimple} Suresi";
    isAyahsLoading = true;
    currentAyahs = [];
    errorMessage = null;

    audioPlayer.stop();
    _checkIfCurrentIsBookmarked();
    notifyListeners();

    final result =
        await _repo.getAyahsBySurah(surah.id, hafizList[selectedHafizName]!);
    if (result is Success<List<AyahModel>>) {
      currentAyahs = result.data ?? [];
    }

    isAyahsLoading = false;
    notifyListeners();
    Future.microtask(() => _setupPlaylist());
  }

  Future<void> loadJuzDetails(int juzNumber) async {
    activeJuz = juzNumber;
    activeSurah = null;
    activePage = null;
    activeTitle = "$juzNumber. Cüz";
    isAyahsLoading = true;
    currentAyahs = [];
    errorMessage = null;

    audioPlayer.stop();
    _checkIfCurrentIsBookmarked();
    notifyListeners();

    final result =
        await _repo.getAyahsByJuz(juzNumber, hafizList[selectedHafizName]!);
    if (result is Success<List<AyahModel>>) {
      currentAyahs = result.data ?? [];
    }

    isAyahsLoading = false;
    notifyListeners();
    Future.microtask(() => _setupPlaylist());
  }

  Future<void> loadPageDetails(int pageNumber) async {
    activePage = pageNumber;
    activeSurah = null;
    activeJuz = null;
    activeTitle = "$pageNumber. Sayfa";
    isAyahsLoading = true;
    currentAyahs = [];
    errorMessage = null;

    audioPlayer.stop();
    _checkIfCurrentIsBookmarked();
    notifyListeners();

    final result =
        await _repo.getAyahsByPage(pageNumber, hafizList[selectedHafizName]!);
    if (result is Success<List<AyahModel>>) {
      currentAyahs = result.data ?? [];
    }

    isAyahsLoading = false;
    notifyListeners();
    Future.microtask(() => _setupPlaylist());
  }

  Future<void> _setupPlaylist() async {
    if (currentAyahs.isEmpty) return;
    try {
      final playlist = ConcatenatingAudioSource(
        useLazyPreparation: true,
        children: currentAyahs
            .where((ayah) => ayah.audioUrl.isNotEmpty)
            .map((ayah) => AudioSource.uri(Uri.parse(ayah.audioUrl)))
            .toList(),
      );
      await audioPlayer.setAudioSource(playlist,
          initialIndex: 0, initialPosition: Duration.zero);
      // Eğer repeat açıksa yeni listede de aktif et
      await audioPlayer.setLoopMode(isRepeatOne ? LoopMode.one : LoopMode.off);
    } catch (e) {
      debugPrint("Ses yükleme hatası: $e");
    }
  }

  Future<void> togglePlay() async {
    if (isPlaying)
      await audioPlayer.pause();
    else
      await audioPlayer.play();
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

  Future<void> playSingleAyah(int index) async {
    activeAyahId = currentAyahs[index].id;
    notifyListeners();
    await audioPlayer.seek(Duration.zero, index: index);
    audioPlayer.play();
  }

  Future<void> toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();

    if (isBookmarked) {
      isBookmarked = false;
      savedBookmarkType = null;
      savedBookmarkId = null;
      savedBookmarkTitle = null;
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
      savedBookmarkTitle = activeTitle;

      if (savedBookmarkType != null) {
        await prefs.setString('bookmark_type', savedBookmarkType!);
        await prefs.setInt('bookmark_id', savedBookmarkId!);
        await prefs.setString('bookmark_title', savedBookmarkTitle!);
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
    if (speed == 1.0)
      speed = 1.25;
    else if (speed == 1.25)
      speed = 1.5;
    else if (speed == 1.5)
      speed = 2.0;
    else
      speed = 1.0;
    audioPlayer.setSpeed(speed);
    notifyListeners();
  }

  void setBgIndex(int index) {
    _bgIndex = index;
    notifyListeners();
  }

  void setPageStyle(String style) {
    _pageStyle = style;
    notifyListeners();
  }

  void setAyahTrackingStyle(String style) {
    _ayahTrackingStyle = style;
    notifyListeners();
  }

  void changeHafiz(String name) {
    selectedHafizName = name;
    notifyListeners();
    if (activeSurah != null)
      loadSurahDetails(activeSurah!);
    else if (activeJuz != null)
      loadJuzDetails(activeJuz!);
    else if (activePage != null) loadPageDetails(activePage!);
  }

  void setVolume(double val) {
    volume = val;
    audioPlayer.setVolume(val);
    notifyListeners();
  }

  void setBrightness(double val) {
    brightness = val;
    notifyListeners();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
}
