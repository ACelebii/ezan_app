// lib/features/kuran/kuran_kayit_sayfalari.dart
//
// Kur'an menüsündeki özelliklerin ekranları: Fihrist, Favori, Not, Okuma
// Listesi, Ezberleme ve Seslendirme (hafız seçimi). Hepsi [KuranProvider]'ı
// doğrudan alır (sayfalar ve sheet'ler Navigator'da provider'ın altında değil).

import '../../core/i18n/cevir.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/arama_metni.dart';
import 'data/kuran_kayitlari.dart';
import 'kuran_models.dart';
import 'providers/kuran_provider.dart';

const _zemin = Color(0xFF121212);
const _kart = Color(0xFF202020);
const _ustCubuk = Color(0xFF0F4C3A);
const _sheetRengi = Color(0xFF2C2C2C);

enum KuranOzelligi {
  fihrist,
  favori,
  not,
  okumaListesi,
  ezberleme,
  seslendirme
}

/// Menüden [ozellik]i açar. [sayfa], menüyü açan (kapanmayan) sayfanın
/// context'idir. [detayAcik]: sure ekranı zaten açıksa true; ayete/sureye
/// gidilince ikinci bir sure ekranı üst üste açılmaz.
void kuranOzelligiAc(
  BuildContext sayfa,
  KuranProvider provider,
  KuranOzelligi ozellik, {
  required bool detayAcik,
}) {
  void git(SurahModel sure, [int? ayetNo]) {
    provider.loadSurahDetails(sure, ayetNo: ayetNo);
    if (!detayAcik) sayfa.push('/kuran/surah-detail', extra: provider);
  }

  void sayfaAc(Widget s) =>
      Navigator.of(sayfa).push(MaterialPageRoute<void>(builder: (_) => s));

  switch (ozellik) {
    case KuranOzelligi.fihrist:
      sayfaAc(FihristSayfasi(provider: provider, git: git));
    case KuranOzelligi.favori:
      sayfaAc(FavoriSayfasi(provider: provider, git: git));
    case KuranOzelligi.not:
      sayfaAc(NotlarSayfasi(provider: provider, git: git));
    case KuranOzelligi.okumaListesi:
      sayfaAc(OkumaListesiSayfasi(provider: provider, git: git));
    case KuranOzelligi.ezberleme:
      _sheetAc(sayfa, EzberSheet(provider: provider));
    case KuranOzelligi.seslendirme:
      seslendirmeAc(sayfa, provider);
  }
}

/// Alt çubuktaki ve menüdeki "Seslendirme": hafız (okuyucu) seçimi.
void seslendirmeAc(BuildContext context, KuranProvider provider) =>
    _sheetAc(context, SeslendirmeSheet(provider: provider));

void _sheetAc(BuildContext context, Widget icerik) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _sheetRengi,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => icerik,
    );

/// [k] ayeti için not yazma/düzenleme penceresi; boş metinle kaydetmek notu siler.
Future<void> notDuzenle(
    BuildContext context, KuranProvider provider, AyetKaydi k) async {
  final sonuc = await showDialog<String>(
    context: context,
    builder: (_) => _NotDialog(
        baslik: '${provider.sureAdiId(k.sureId, k.sureAdi)} ${k.verseKey}',
        ilkMetin: k.not),
  );
  if (sonuc != null) await provider.kayitDegistir(k, not: sonuc);
}

typedef SureyeGit = void Function(SurahModel sure, [int? ayetNo]);

SurahModel? _sureBul(KuranProvider p, int id) {
  for (final s in p.surahs) {
    if (s.id == id) return s;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Ortak parçalar

class _Sayfa extends StatelessWidget {
  const _Sayfa({required this.baslik, required this.govde, this.ekle});

  final String baslik;
  final Widget govde;
  final VoidCallback? ekle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _zemin,
      appBar: AppBar(
        backgroundColor: _ustCubuk,
        foregroundColor: Colors.white,
        title: Text(baslik,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      floatingActionButton: ekle == null
          ? null
          : FloatingActionButton(
              onPressed: ekle,
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              tooltip: context.t('Sure ekle'),
              child: const Icon(Icons.add)),
      body: govde,
    );
  }
}

class _BosDurum extends StatelessWidget {
  const _BosDurum({required this.simge, required this.metin});

  final IconData simge;
  final String metin;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(simge, size: 56, color: Colors.white24),
              const SizedBox(height: 16),
              Text(metin,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, height: 1.5)),
            ],
          ),
        ),
      );
}

/// Favori ve Not sayfalarındaki ayet kartı.
class _AyetKarti extends StatelessWidget {
  const _AyetKarti({
    required this.kayit,
    required this.sureAdi,
    required this.meal,
    required this.onTap,
    required this.sagSimge,
    this.notOnde = false,
  });

  final AyetKaydi kayit;

  /// Uygulama diline göre sure adı (kayıttaki ad yalnız yedek).
  final String sureAdi;

  /// Kartta gösterilen meal (uygulama diline göre).
  final String meal;
  final VoidCallback onTap;
  final Widget sagSimge;

  /// Not sayfasında not, Arapça metinden önce ve belirgin gösterilir.
  final bool notOnde;

  @override
  Widget build(BuildContext context) {
    final not = kayit.not.isEmpty
        ? null
        : Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border:
                  const Border(left: BorderSide(color: Colors.amber, width: 3)),
            ),
            child: Text(kayit.not,
                style: const TextStyle(color: Colors.white, height: 1.4)),
          );
    return Card(
      color: _kart,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('$sureAdi  ·  ${kayit.verseKey}',
                        style: const TextStyle(
                            color: Colors.amber, fontWeight: FontWeight.bold)),
                  ),
                  sagSimge,
                ],
              ),
              if (notOnde && not != null) not,
              Text(kayit.arapca,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 22, height: 1.8)),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(meal,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.4)),
              ),
              if (!notOnde && not != null)
                Padding(padding: const EdgeInsets.only(right: 12), child: not),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fihrist

class FihristSayfasi extends StatelessWidget {
  const FihristSayfasi({super.key, required this.provider, required this.git});

  final KuranProvider provider;
  final SureyeGit git;

  @override
  Widget build(BuildContext context) {
    return _Sayfa(
      baslik: context.t('Fihrist'),
      govde: ListenableBuilder(
        listenable: provider,
        builder: (context, _) => ListView.separated(
          itemCount: provider.surahs.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Colors.white12),
          itemBuilder: (context, i) {
            final s = provider.surahs[i];
            final ayrinti = [
              if (s.inisYeri.isNotEmpty) context.t(s.inisYeri),
              context.t('${s.versesCount} ayet'),
              if (s.startPage > 0) context.t('Sayfa ${s.startPage}'),
            ].join('  ·  ');
            return ListTile(
              leading: CircleAvatar(
                  backgroundColor: _ustCubuk,
                  child: Text('${s.id}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13))),
              title: Row(
                children: [
                  Expanded(
                      child: Text(provider.sureAdi(s),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold))),
                  Text(s.nameArabic,
                      textDirection: TextDirection.rtl,
                      style:
                          const TextStyle(color: Colors.amber, fontSize: 20)),
                ],
              ),
              subtitle: Text(ayrinti,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                git(s);
              },
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Favori

class FavoriSayfasi extends StatelessWidget {
  const FavoriSayfasi({super.key, required this.provider, required this.git});

  final KuranProvider provider;
  final SureyeGit git;

  @override
  Widget build(BuildContext context) {
    return _Sayfa(
      baslik: context.t('Favori Ayetler'),
      govde: ListenableBuilder(
        listenable: provider,
        builder: (context, _) {
          final liste = provider.ayetKayitlari.where((k) => k.favori).toList();
          if (liste.isEmpty) {
            return _BosDurum(
                simge: Icons.favorite_border,
                metin: context.t(
                    'Henüz favori ayet yok.\n\nBir sureyi Liste görünümünde '
                    'açıp ayetin altındaki kalp simgesine dokunarak favorilere '
                    'ekleyebilirsiniz.'));
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final k in liste)
                _AyetKarti(
                  kayit: k,
                  sureAdi: provider.sureAdiId(k.sureId, k.sureAdi),
                  meal: provider.kartMeali(k),
                  onTap: () {
                    final sure = _sureBul(provider, k.sureId);
                    if (sure == null) return;
                    Navigator.pop(context);
                    git(sure, k.ayetNo);
                  },
                  sagSimge: IconButton(
                    tooltip: context.t('Favoriden çıkar'),
                    icon: const Icon(Icons.favorite, color: Colors.amber),
                    onPressed: () => provider.kayitDegistir(k, favori: false),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Not

class NotlarSayfasi extends StatelessWidget {
  const NotlarSayfasi({super.key, required this.provider, required this.git});

  final KuranProvider provider;
  final SureyeGit git;

  @override
  Widget build(BuildContext context) {
    return _Sayfa(
      baslik: context.t('Notlarım'),
      govde: ListenableBuilder(
        listenable: provider,
        builder: (context, _) {
          final liste =
              provider.ayetKayitlari.where((k) => k.not.isNotEmpty).toList();
          if (liste.isEmpty) {
            return _BosDurum(
                simge: Icons.edit_note,
                metin: context
                    .t('Henüz not yok.\n\nBir sureyi Liste görünümünde açıp '
                        'ayetin altındaki not simgesine dokunarak o ayete not '
                        'yazabilirsiniz.'));
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final k in liste)
                _AyetKarti(
                  kayit: k,
                  sureAdi: provider.sureAdiId(k.sureId, k.sureAdi),
                  meal: provider.kartMeali(k),
                  notOnde: true,
                  onTap: () {
                    final sure = _sureBul(provider, k.sureId);
                    if (sure == null) return;
                    Navigator.pop(context);
                    git(sure, k.ayetNo);
                  },
                  sagSimge: IconButton(
                    tooltip: context.t('Notu düzenle'),
                    icon: const Icon(Icons.edit_outlined, color: Colors.amber),
                    onPressed: () => notDuzenle(context, provider, k),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _NotDialog extends StatefulWidget {
  const _NotDialog({required this.baslik, required this.ilkMetin});

  final String baslik;
  final String ilkMetin;

  @override
  State<_NotDialog> createState() => _NotDialogState();
}

class _NotDialogState extends State<_NotDialog> {
  late final _denetleyici = TextEditingController(text: widget.ilkMetin);

  @override
  void dispose() {
    _denetleyici.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _sheetRengi,
      title: Text(context.t('${widget.baslik} için not'),
          style: const TextStyle(color: Colors.white, fontSize: 16)),
      content: TextField(
        controller: _denetleyici,
        autofocus: true,
        minLines: 3,
        maxLines: 6,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: context.t('Notunuzu yazın'),
          hintStyle: const TextStyle(color: Colors.white38),
        ),
      ),
      actions: [
        if (widget.ilkMetin.isNotEmpty)
          TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: Text(context.t('Notu Sil'),
                  style: const TextStyle(color: Colors.redAccent))),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.t('Vazgeç'))),
        TextButton(
            onPressed: () => Navigator.pop(context, _denetleyici.text),
            child: Text(context.t('Kaydet'))),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Okuma listesi

class OkumaListesiSayfasi extends StatelessWidget {
  const OkumaListesiSayfasi(
      {super.key, required this.provider, required this.git});

  final KuranProvider provider;
  final SureyeGit git;

  @override
  Widget build(BuildContext context) {
    return _Sayfa(
      baslik: context.t('Okuma Listesi'),
      ekle: () => _sheetAc(context, _SureSecici(provider: provider)),
      govde: ListenableBuilder(
        listenable: provider,
        builder: (context, _) {
          final liste = provider.okumaListesi;
          if (liste.isEmpty) {
            return _BosDurum(
                simge: Icons.playlist_add,
                metin:
                    context.t('Okuma listeniz boş.\n\nSağ alttaki + ile okumak '
                        'istediğiniz sureleri ekleyin; okudukça işaretleyin.'));
          }
          final okunan = liste.where((o) => o.okundu).length;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.t('$okunan / ${liste.length} sure okundu'),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                        value: okunan / liste.length,
                        color: Colors.amber,
                        backgroundColor: Colors.white12),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 88),
                  children: [
                    for (final o in liste) _okumaSatiri(context, o),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _okumaSatiri(BuildContext context, OkumaOgesi o) {
    final sure = _sureBul(provider, o.sureId);
    final ad =
        sure == null ? context.t('${o.sureId}. sure') : provider.sureAdi(sure);
    return ListTile(
      leading: Checkbox(
        value: o.okundu,
        activeColor: Colors.amber,
        checkColor: Colors.black,
        side: const BorderSide(color: Colors.white54),
        onChanged: (_) => provider.okunduDegistir(o.sureId),
      ),
      title: Text('${o.sureId}. $ad',
          style: TextStyle(
              color: o.okundu ? Colors.white38 : Colors.white,
              decoration: o.okundu ? TextDecoration.lineThrough : null)),
      subtitle: sure == null
          ? null
          : Text(context.t('${sure.versesCount} ayet'),
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
      trailing: IconButton(
        tooltip: context.t('Listeden çıkar'),
        icon: const Icon(Icons.close, color: Colors.white38),
        onPressed: () => provider.okumadanCikar(o.sureId),
      ),
      onTap: sure == null
          ? null
          : () {
              Navigator.pop(context);
              git(sure);
            },
    );
  }
}

/// Okuma listesine eklenecek sureyi seçtirir; eklenenler listeden kalkar.
class _SureSecici extends StatefulWidget {
  const _SureSecici({required this.provider});

  final KuranProvider provider;

  @override
  State<_SureSecici> createState() => _SureSeciciState();
}

class _SureSeciciState extends State<_SureSecici> {
  String _aranan = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: 500,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(context.t('Listeye sure ekle'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (v) => setState(() => _aranan = aramaMetni(v)),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: context.t('Sure ara'),
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.provider,
                builder: (context, _) {
                  final varolan = {
                    for (final o in widget.provider.okumaListesi) o.sureId
                  };
                  final sureler = widget.provider.surahs
                      .where((s) =>
                          !varolan.contains(s.id) &&
                          (aramaMetni(s.displayName).contains(_aranan) ||
                              aramaMetni(s.nameSimple).contains(_aranan) ||
                              '${s.id}' == _aranan))
                      .toList();
                  if (sureler.isEmpty) {
                    return Center(
                        child: Text(context.t('Eklenecek sure kalmadı.'),
                            style: const TextStyle(color: Colors.white54)));
                  }
                  return ListView(
                    children: [
                      for (final s in sureler)
                        ListTile(
                          title: Text('${s.id}. ${widget.provider.sureAdi(s)}',
                              style: const TextStyle(color: Colors.white70)),
                          trailing: const Icon(Icons.add, color: Colors.amber),
                          onTap: () => widget.provider.okumayaEkle(s.id),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ezberleme

class EzberSheet extends StatefulWidget {
  const EzberSheet({super.key, required this.provider});

  final KuranProvider provider;

  @override
  State<EzberSheet> createState() => _EzberSheetState();
}

class _EzberSheetState extends State<EzberSheet> {
  static const _tekrarSecenekleri = [1, 3, 5, 7, 10, 20];

  int _ilk = 0;
  int _son = 0;
  int _tekrar = 3;
  String? _hata;

  @override
  void initState() {
    super.initState();
    final n = widget.provider.currentAyahs.length;
    _son = n == 0 ? 0 : (n < 5 ? n - 1 : 4);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final ayetler = p.currentAyahs;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ayetler.isEmpty
          ? SizedBox(
              height: 160,
              child: _BosDurum(
                  simge: Icons.replay,
                  metin: context.t(
                      'Ezberlemek için önce bir sure, cüz ya da sayfa açın.')))
          : ListenableBuilder(
              listenable: p,
              builder: (context, _) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t('Ezberleme  ·  ${p.activeTitle}'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                      context.t(
                          'Seçtiğiniz ayetler, her biri istediğiniz kadar tekrarlanarak sırayla çalınır.'),
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _ayetSecici('Başlangıç', _ilk, ayetler, (i) {
                        setState(() {
                          _ilk = i;
                          if (_son < i) _son = i;
                        });
                      })),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _ayetSecici('Bitiş', _son, ayetler, (i) {
                        setState(() {
                          _son = i;
                          if (_ilk > i) _ilk = i;
                        });
                      })),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(context.t('Her ayet kaç kez'),
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final t in _tekrarSecenekleri)
                        ChoiceChip(
                          label: Text('$t'),
                          selected: _tekrar == t,
                          selectedColor: Colors.amber,
                          labelStyle: TextStyle(
                              color:
                                  _tekrar == t ? Colors.black : Colors.white),
                          backgroundColor: Colors.white12,
                          onSelected: (_) => setState(() => _tekrar = t),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                      context.t(
                          '${_son - _ilk + 1} ayet x $_tekrar = ${(_son - _ilk + 1) * _tekrar} çalma'),
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                  if (_hata != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(context.t(_hata!),
                          style: const TextStyle(color: Colors.redAccent)),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (p.ezberModu)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await p.ezberiBitir();
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: Text(context.t('Ezberlemeyi Bitir')),
                          ),
                        ),
                      if (p.ezberModu) const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black),
                          onPressed: () async {
                            final hata = await p.ezberle(_ilk, _son, _tekrar);
                            if (!context.mounted) return;
                            if (hata == null) {
                              Navigator.pop(context);
                            } else {
                              setState(() => _hata = hata);
                            }
                          },
                          child: Text(context.t('Başlat')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _ayetSecici(String etiket, int deger, List<AyahModel> ayetler,
      ValueChanged<int> degisti) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.t(etiket), style: const TextStyle(color: Colors.white70)),
        DropdownButton<int>(
          isExpanded: true,
          value: deger,
          dropdownColor: const Color(0xFF3C3C3C),
          style: const TextStyle(color: Colors.white),
          items: [
            for (var i = 0; i < ayetler.length; i++)
              DropdownMenuItem(value: i, child: Text(ayetler[i].verseKey)),
          ],
          onChanged: (i) {
            if (i != null) degisti(i);
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Seslendirme (hafız seçimi)

class SeslendirmeSheet extends StatelessWidget {
  const SeslendirmeSheet({super.key, required this.provider});

  final KuranProvider provider;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.t('Seslendirme (Hafız)'),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                  context
                      .t('Açık olan sure seçtiğiniz hafızla yeniden yüklenir.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ),
            const SizedBox(height: 8),
            for (final ad in provider.hafizList.keys)
              ListTile(
                leading: Icon(
                    ad == provider.selectedHafizName
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: ad == provider.selectedHafizName
                        ? Colors.amber
                        : Colors.white54),
                title: Text(context.t(ad),
                    style: const TextStyle(color: Colors.white)),
                onTap: () {
                  if (ad != provider.selectedHafizName) {
                    provider.changeHafiz(ad);
                  }
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}
