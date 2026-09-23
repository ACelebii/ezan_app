import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/vakit/diyanet_kaynagi.dart';
import '../../core/vakit/yer_bulucu.dart';
import '../../locator.dart';
import 'settings_common.dart';

/// Dünyanın her yerinden yer seçtirir: Ülke → (Şehir/Eyalet) → İlçe, Diyanet'in
/// listeleriyle. Seçim bitince yerin [Konum]u (koordinat + saat dilimi dahil)
/// `context.pop(konum)` ile döner. Tek şehirli ülkelerde şehir basamağı atlanır.
class DunyaYerSecPage extends StatefulWidget {
  const DunyaYerSecPage({super.key, this.diyanet, this.bulucu});

  /// Testte sahte servis vermek içindir; verilmezse gerçekleri kurulur.
  final DiyanetKaynagi? diyanet;
  final YerBulucu? bulucu;

  @override
  State<DunyaYerSecPage> createState() => _DunyaYerSecPageState();
}

class _DunyaYerSecPageState extends State<DunyaYerSecPage> {
  late final DiyanetKaynagi _diyanet =
      widget.diyanet ?? locator<DiyanetKaynagi>();
  late final YerBulucu _bulucu = widget.bulucu ?? YerBulucu();
  final _arama = TextEditingController();
  final _onbellek = <String, List<DiyanetYeri>>{};

  /// Yapılan seçimler: [] → ülkeler, [ülke] → şehirler, [ülke, şehir] → ilçeler.
  final _secim = <DiyanetYeri>[];

  /// Şehir basamağı (tek şehir olduğu için) kendiliğinden geçildi mi?
  bool _sehirAtlandi = false;

  List<DiyanetYeri> _liste = const [];
  bool _yukleniyor = true;
  bool _hata = false;
  bool _bulunuyor = false;
  int _istek = 0;

  static const _basliklar = ['Ülke Seç', 'Şehir Seç', 'İlçe Seç'];

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void dispose() {
    _arama.dispose();
    super.dispose();
  }

  bool get _turkiye =>
      _secim.isNotEmpty && _secim.first.id == diyanetTurkiyeUlkeId;

  Future<List<DiyanetYeri>> _listeGetir() async {
    final anahtar = '${_secim.length}/${_secim.isEmpty ? 0 : _secim.last.id}';
    final eldeki = _onbellek[anahtar];
    if (eldeki != null) return eldeki;
    final liste = switch (_secim.length) {
      0 => await _diyanet.ulkeler(),
      1 => await _diyanet.sehirler(_secim[0].id),
      _ => await _diyanet.ilceler(_secim[1].id),
    };
    // Türkçe alfabeye uygun sıra (Diyanet listeleri kendi sırasındadır).
    return _onbellek[anahtar] = List.of(liste)
      ..sort((a, b) => aramaMetni(a.ad).compareTo(aramaMetni(b.ad)));
  }

  Future<void> _yukle() async {
    final istek = ++_istek;
    setState(() {
      _yukleniyor = true;
      _hata = false;
    });
    try {
      var liste = await _listeGetir();
      if (!mounted || istek != _istek) return;
      if (_secim.length == 1 && liste.length == 1) {
        _secim.add(liste.single);
        _sehirAtlandi = true;
        liste = await _listeGetir();
        if (!mounted || istek != _istek) return;
      }
      setState(() {
        _liste = liste;
        _yukleniyor = false;
      });
    } on DiyanetHatasi catch (e) {
      debugPrint('Yer listesi alınamadı: $e');
      if (!mounted || istek != _istek) return;
      setState(() {
        _hata = true;
        _yukleniyor = false;
      });
    }
  }

  void _geri() {
    if (_bulunuyor) return;
    if (_secim.isEmpty) {
      context.pop();
      return;
    }
    _secim.removeLast();
    if (_sehirAtlandi) {
      _secim.removeLast();
      _sehirAtlandi = false;
    }
    _arama.clear();
    _yukle();
  }

  void _sec(DiyanetYeri yer) {
    if (_secim.length < 2) {
      _secim.add(yer);
      _arama.clear();
      _yukle();
    } else {
      _konumuBul(yer);
    }
  }

  Future<void> _konumuBul(DiyanetYeri ilce) async {
    setState(() => _bulunuyor = true);
    try {
      final konum =
          await _bulucu.bul(ulke: _secim[0], sehir: _secim[1], ilce: ilce);
      if (mounted) context.pop(konum);
    } on YerBulucuHatasi catch (e) {
      debugPrint('Yer bulunamadı: $e');
      if (!mounted) return;
      setState(() => _bulunuyor = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.read<AuthService>().translate(
              "Bu yer eklenemedi. İnternet bağlantınızı kontrol edin ya da başka bir yer deneyin."))));
    }
  }

  /// Ülke adı Türkçe, diğerleri Diyanet'te İngilizce (Türkiye hariç) yazılır.
  String _gorunenAd(DiyanetYeri yer) =>
      baslikYaz(yer.ad, turkce: _secim.isEmpty || _turkiye);

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final gorunenler = yerleriSuz(_liste, _arama.text);

    return Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: PopScope(
        canPop: _secim.isEmpty && !_bulunuyor,
        onPopInvokedWithResult: (kapandi, _) {
          if (!kapandi) _geri();
        },
        child: Scaffold(
          backgroundColor: getBgColor(context),
          appBar: AppBar(
            leading: buildBeautifulBackButton(context, onPressed: _geri),
            backgroundColor: getBgColor(context),
            elevation: 0,
            centerTitle: true,
            title: Text(authService.translate(_basliklar[_secim.length]),
                style: TextStyle(
                    color: getTextColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ),
          body: Stack(
            children: [
              AbsorbPointer(
                  absorbing: _bulunuyor,
                  child: _icerik(authService, gorunenler)),
              if (_bulunuyor)
                Center(
                    child: CircularProgressIndicator(
                        color: getAccentColor(context))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _icerik(AuthService authService, List<DiyanetYeri> gorunenler) {
    if (_yukleniyor) {
      return Center(
          child: CircularProgressIndicator(color: getAccentColor(context)));
    }
    if (_hata) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(authService.translate("Liste alınamadı."),
              style: const TextStyle(color: Colors.redAccent)),
          TextButton(
              onPressed: _yukle,
              child: Text(authService.translate("Tekrar Dene"),
                  style: TextStyle(color: getTextColor(context)))),
        ]),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            controller: _arama,
            style: TextStyle(color: getTextColor(context)),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
                hintText: authService.translate("Ara"),
                hintStyle: TextStyle(color: getSubTextColor(context)),
                prefixIcon: Icon(Icons.search, color: getSubTextColor(context)),
                filled: true,
                fillColor: getTextFieldColor(context),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0)),
          ),
        ),
        Expanded(
          child: gorunenler.isEmpty
              ? Center(
                  child: Text(authService.translate("Sonuç yok"),
                      style: TextStyle(color: getSubTextColor(context))))
              : ListView.separated(
                  itemCount: gorunenler.length,
                  separatorBuilder: (_, __) => Divider(
                      color: getDividerColor(context), height: 1, indent: 16),
                  itemBuilder: (context, i) => ListTile(
                    title: Text(_gorunenAd(gorunenler[i]),
                        style: TextStyle(color: getTextColor(context))),
                    trailing: _secim.length < 2
                        ? Icon(Icons.chevron_right,
                            color: getSubTextColor(context))
                        : null,
                    onTap: () => _sec(gorunenler[i]),
                  ),
                ),
        ),
      ],
    );
  }
}
