import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';
import '../../core/ekran_uyanik.dart';
import '../../core/i18n/cevir.dart';
import 'zikir.dart';
import 'zikirmatik_provider.dart';

// ============================================================================
// ORTAK BUTON TASARIMI (Glassmorphism / Şeffaf Kutu)
// ============================================================================
Widget _buildGlassButton(BuildContext context,
    {IconData? icon, String? text, required VoidCallback onTap}) {
  bool isDark = Theme.of(context).brightness == Brightness.dark;
  Color textColor = isDark ? Colors.white : Colors.black87;

  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: EdgeInsets.symmetric(
          horizontal: text != null ? 16 : 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, color: textColor, size: 18),
          if (icon != null && text != null) const SizedBox(width: 6),
          if (text != null)
            Text(text,
                style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}

// ============================================================================
// 1. ZİKİR LİSTESİ (ANA GİRİŞ SAYFASI)
// ============================================================================
class ZikirmatikPage extends StatefulWidget {
  const ZikirmatikPage({super.key});

  @override
  State<ZikirmatikPage> createState() => _ZikirmatikPageState();
}

class _ZikirmatikPageState extends State<ZikirmatikPage> {
  bool isEditing = false;

  /// Silme düğmesi açık olan zikir (ada değil nesneye bağlı: aynı adlı iki zikir karışmasın).
  Zikir? _showingDeleteFor;

  void _showAddPopup(BuildContext context, {Zikir? initialData}) async {
    final provider = context.read<ZikirmatikProvider>();
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Alt boşluk klavye kadar: yoksa alttaki alanlar (Okunuşu, Anlamı)
      // klavyenin arkasında kalıyor, yazılan görünmüyordu.
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ZikirEkleDuzenlePage(initialData: initialData),
        ),
      ),
    );
    if (result != null && result is Zikir) {
      if (initialData != null) {
        provider.zikirGuncelle(initialData, result);
      } else {
        provider.zikirEkle(result);
      }
    }
  }

  /// Kendi eklediğin bir zikri "Hazır" listesinden kalıcı siler (onaylı).
  Future<void> _hazirSil(Zikir z) async {
    final provider = context.read<ZikirmatikProvider>();
    final sil = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.t('"${z.ad}" silinsin mi?')),
        content: Text(context.t('Zikir ve sayacı kalıcı olarak silinir.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(context.t('Vazgeç'))),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(context.t('Sil'))),
        ],
      ),
    );
    if (sil == true) provider.hazirdanSil(z);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = context.watch<AuthService>();
    final zikirProvider = context.watch<ZikirmatikProvider>();
    final aktifZikirler = zikirProvider.aktifZikirler;
    final hazirZikirler = zikirProvider.hazirZikirler;
    Color cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    if (!zikirProvider.yuklendi) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGlassButton(context,
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => context.pop()),
                  Row(
                    children: [
                      _buildGlassButton(context,
                          icon: Icons.add, onTap: () => _showAddPopup(context)),
                      const SizedBox(width: 8),
                      _buildGlassButton(context,
                          text: isEditing
                              ? authService.translate("Bitti")
                              : authService.translate("Düzenle"), onTap: () {
                        setState(() {
                          isEditing = !isEditing;
                          _showingDeleteFor = null;
                        });
                      }),
                    ],
                  )
                ],
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4))
                              ]),
                    child: Column(
                      children: aktifZikirler.asMap().entries.map((entry) {
                        int index = entry.key;
                        var z = entry.value;
                        bool isLast = index == aktifZikirler.length - 1;
                        bool isDefault = z.varsayilan;
                        bool showDelete = identical(_showingDeleteFor, z);

                        Widget tile = ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: isDefault
                              ? Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color:
                                          Colors.blue.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.touch_app_rounded,
                                      color: Colors.blue, size: 20),
                                )
                              : (isEditing
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () => setState(() =>
                                              _showingDeleteFor =
                                                  showDelete ? null : z),
                                          child: const Icon(Icons.remove_circle,
                                              color: Colors.redAccent,
                                              size: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(Icons.radio_button_unchecked,
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.black26,
                                            size: 22),
                                      ],
                                    )
                                  : Icon(Icons.radio_button_unchecked,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black26,
                                      size: 22)),
                          title: Text(authService.translate(z.ad),
                              style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16)),
                          trailing: isEditing
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isDefault)
                                      Icon(Icons.edit,
                                          size: 18,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54),
                                    if (isDefault)
                                      Text("${z.sayi}/${z.hedef}",
                                          style: TextStyle(
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.black54,
                                              fontSize: 14)),
                                    const SizedBox(width: 10),
                                    Icon(Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black26),
                                    const SizedBox(width: 12),
                                    Icon(Icons.menu,
                                        size: 20,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black26),
                                    if (showDelete && !isDefault) ...[
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () {
                                          zikirProvider.aktiftenKaldir(z);
                                          setState(() {
                                            _showingDeleteFor = null;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                              color: Colors.redAccent,
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.delete_outline,
                                                  color: Colors.white,
                                                  size: 16),
                                              const SizedBox(width: 4),
                                              Text(context.t("Sil"),
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      )
                                    ]
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("${z.sayi}/${z.hedef}",
                                        style: TextStyle(
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black54,
                                            fontSize: 14)),
                                    const SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black26),
                                  ],
                                ),
                          onTap: () {
                            if (isEditing) {
                              if (!isDefault) {
                                _showAddPopup(context, initialData: z);
                              }
                            } else {
                              context.push('/zikirmatik/sayac', extra: z);
                            }
                          },
                        );

                        return Column(
                          children: [
                            isEditing
                                ? tile
                                : Dismissible(
                                    // Anahtar zikrin kendisi: ad ya da sıra
                                    // numarası anahtar olunca aynı adlı zikirler
                                    // çakışıyor, ortadakini silince satırlar
                                    // kayıp "silinmiş satır ağaçta kaldı" hatası
                                    // çıkıyordu (id'si olmayan hazır zikirler).
                                    key: ObjectKey(z),
                                    // Varsayılan zikir silinemez: kaydırılınca
                                    // satır veriden değil yalnız ekrandan
                                    // kayboluyordu.
                                    direction: isDefault
                                        ? DismissDirection.none
                                        : DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(
                                                  index == 0 ? 16 : 0),
                                              bottom: Radius.circular(
                                                  isLast ? 16 : 0))),
                                      child: const Icon(Icons.delete,
                                          color: Colors.white),
                                    ),
                                    onDismissed: (direction) =>
                                        zikirProvider.aktiftenKaldir(z),
                                    child: tile,
                                  ),
                            if (!isLast)
                              Divider(
                                  color:
                                      isDark ? Colors.white10 : Colors.black12,
                                  height: 1,
                                  indent: 50),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  if (hazirZikirler.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4))
                                ]),
                      child: Column(
                        children: hazirZikirler.asMap().entries.map((entry) {
                          int index = entry.key;
                          var z = entry.value;
                          bool isLast = index == hazirZikirler.length - 1;

                          return Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                leading: Icon(Icons.add_circle_outline,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                    size: 24),
                                title: Text(authService.translate(z.ad),
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500)),
                                // Yalnız kendi eklediğin zikirler (id'li) silinebilir.
                                trailing: !z.kendiEkledigim
                                    ? null
                                    : IconButton(
                                        tooltip: context.t('Kalıcı olarak sil'),
                                        icon: Icon(Icons.delete_outline,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black45),
                                        onPressed: () => _hazirSil(z),
                                      ),
                                onTap: () {
                                  zikirProvider.hazirdanEkle(z);
                                },
                              ),
                              if (!isLast)
                                Divider(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black12,
                                    height: 1,
                                    indent: 50),
                            ],
                          );
                        }).toList(),
                      ),
                    )
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. ZİKİR SAYACI (TESBİH RENKLERİ EKLENDİ)
// ============================================================================
class ZikirmatikSayacPage extends StatefulWidget {
  final Zikir zikir;
  const ZikirmatikSayacPage({super.key, required this.zikir});

  @override
  State<ZikirmatikSayacPage> createState() => _ZikirmatikSayacPageState();
}

class _ZikirmatikSayacPageState extends State<ZikirmatikSayacPage> {
  // Android'de ses tuşu olayları Flutter'ın kendi tuş dinleyicisine hiç
  // ulaşmıyor (sistem ses göstergesi doğrudan native katmanda tüketiyor);
  // bu yüzden MainActivity.kt'teki dispatchKeyEvent yakalayıp bu kanaldan
  // bildiriyor. Yalnız bu ekran açıkken dinleniyor: diğer ekranlarda
  // (ör. Kur'an dinlerken) ses tuşu normal ses ayarını değiştirmeye devam eder.
  static const _sesTusuKanali = MethodChannel('com.acelebi.ezanvakti/ses_tusu');

  late int _count;
  late int _target;
  late int _loop;

  bool _isTapped = false;
  double _scale = 1.0;

  // --- TESBİH RENK PALETLERİ ---
  final List<List<Color>> _beadColorPalettes = [
    [Colors.white, const Color(0xFFFDE6C5), const Color(0xFFD4A373)], // Krem
    [
      const Color(0xFFE2B48A),
      const Color(0xFFB57041),
      const Color(0xFF5C3317)
    ], // Ahşap / Kahverengi
    [Colors.white, const Color(0xFFA0A0A0), const Color(0xFF404040)], // Gri
    [
      Colors.white.withValues(alpha: 0.9),
      Colors.redAccent.shade200,
      Colors.red.shade900
    ], // Kırmızı (Varsayılan)
    [
      const Color(0xFFC0E8C0),
      const Color(0xFF5AB95A),
      const Color(0xFF1B5E20)
    ], // Yeşil
  ];

  @override
  void initState() {
    super.initState();
    _count = widget.zikir.sayi;
    _target = widget.zikir.hedef;
    _loop = widget.zikir.tur;
    EkranUyanik.ac(); // sayarken ekran kararmasın
    _sesTusuKanali.setMethodCallHandler((call) async {
      if (call.method == 'basildi') _increment();
    });
    _sesTusuKanali.invokeMethod('dinlemeyiAyarla', true);
  }

  @override
  void dispose() {
    EkranUyanik.kapat();
    _sesTusuKanali.invokeMethod('dinlemeyiAyarla', false);
    _sesTusuKanali.setMethodCallHandler(null);
    super.dispose();
  }

  void _increment() {
    Feedback.forTap(context);
    var turTamam = false;
    setState(() {
      _count++;
      if (_count >= _target) {
        _loop++;
        _count = 0;
        turTamam = true;
      }
    });
    // Hedef tamamlanınca güçlü, her imamede orta şiddette titreşim (tesbihin
    // imame boncuğu gibi): ekrana bakmadan sayılabilsin.
    final imame = widget.zikir.imame;
    if (turTamam) {
      HapticFeedback.heavyImpact();
    } else if (imame != null && _count % imame == 0) {
      HapticFeedback.mediumImpact();
    }
    context
        .read<ZikirmatikProvider>()
        .sayaciGuncelle(widget.zikir, _count, tur: _loop);
  }

  /// Kayıtlı bir ilerleme varsa sıfırlamadan önce sorar (yanlışlıkla dokunuşla
  /// bin adetlik sayaç kaybolmasın).
  Future<void> _sifirlaOnayla() async {
    if (_count == 0 && _loop == 0) return;
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.t('Sayaç sıfırlansın mı?')),
        content: Text(context.t('$_count/$_target ve $_loop tur silinecek.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(context.t('Vazgeç'))),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(context.t('Sıfırla'))),
        ],
      ),
    );
    if (onay == true && mounted) _reset();
  }

  void _reset() {
    setState(() {
      _count = 0;
      _loop = 0;
    });
    context.read<ZikirmatikProvider>().sayaciGuncelle(widget.zikir, 0, tur: 0);
  }

  // --- RENK SEÇİCİ POPUP EKRANI ---
  void _showBeadColorPicker() {
    final provider = context.read<ZikirmatikProvider>();
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          bool isDark = Theme.of(context).brightness == Brightness.dark;
          return StatefulBuilder(builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.only(
                  bottom: 40, top: 10, left: 20, right: 20),
              decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black26,
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_beadColorPalettes.length, (index) {
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            provider.setTesbihRengi(index);
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: const Alignment(-0.3, -0.3),
                              radius: 0.8,
                              colors: _beadColorPalettes[index],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                            border: provider.tesbihRengi == index
                                ? Border.all(
                                    color: Colors.blue.withValues(alpha: 0.8),
                                    width: 3)
                                : Border.all(
                                    color: Colors.transparent, width: 3),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3))
                            ],
                          ),
                        ),
                      );
                    }),
                  )
                ],
              ),
            );
          });
        });
  }

  Widget _buildCountTexts(bool isDark, {bool alignLeft = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // Halkanın iç çapına (~254 px) sığmayan büyük sayılar (99999/100000)
        // halkanın üstüne taşıyordu: sığacak kadar küçülür.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 230),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text("$_count",
                    style: TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.w300,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.0)),
                Text("/$_target",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: isDark ? Colors.white54 : Colors.black45)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.autorenew_rounded,
                size: 16, color: isDark ? Colors.white54 : Colors.black45),
            const SizedBox(width: 4),
            Text("$_loop",
                style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white54 : Colors.black45)),
            if (widget.zikir.imame != null) ...[
              const SizedBox(width: 12),
              Text(context.t("İmame: ${widget.zikir.imame}"),
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.black38)),
            ],
          ],
        ),
      ],
    );
  }

  /// Zikrin Arapça, okunuşu ve anlamı (dolu olanlar); hiçbiri yoksa boş.
  /// Bu alanlar forma giriliyor ve hazır zikirlerde var ama daha önce hiçbir
  /// yerde gösterilmiyordu.
  Widget _buildZikirMetni(bool isDark, {bool alignLeft = false}) {
    final z = widget.zikir;
    if (!z.metniVar) return const SizedBox.shrink();
    final arapca = z.arapca.trim(),
        okunusu = z.okunusu.trim(),
        anlami = z.anlami.trim();
    final ana = isDark ? Colors.white : Colors.black87;
    final metin = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        if (arapca.isNotEmpty)
          Text(arapca,
              textDirection: TextDirection.rtl,
              textAlign: alignLeft ? TextAlign.start : TextAlign.center,
              style: TextStyle(fontSize: 26, height: 1.8, color: ana)),
        if (okunusu.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(context.t(okunusu),
                textAlign: alignLeft ? TextAlign.start : TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: ana.withValues(alpha: 0.85))),
          ),
        if (anlami.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(context.t(anlami),
                textAlign: alignLeft ? TextAlign.start : TextAlign.center,
                style:
                    TextStyle(fontSize: 13, color: ana.withValues(alpha: 0.6))),
          ),
      ],
    );
    if (alignLeft) {
      return Padding(padding: const EdgeInsets.only(top: 20), child: metin);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: SingleChildScrollView(child: metin),
      ),
    );
  }

  // --- RENGE GÖRE TESBİH OLUŞTURUCU ---
  List<Widget> _buildBeadSequence(bool isDark, int beadColorIndex) {
    List<double> sizes = [15, 25, 40, 60, 80, 60, 40, 25, 15];
    List<Widget> children = [];
    List<Color> currentPalette = _beadColorPalettes[beadColorIndex];
    Color separatorColor = currentPalette[1]
        .withValues(alpha: 0.6); // Ara noktalar için paletin orta rengi

    for (int i = 0; i < sizes.length; i++) {
      children.add(Container(
        width: sizes[i],
        height: sizes[i],
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 0.8,
            colors: currentPalette,
            stops: const [0.0, 0.4, 1.0],
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 5,
                offset: const Offset(2, 4))
          ],
        ),
      ));
      if (i != sizes.length - 1) {
        children.add(Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.all(6),
          decoration:
              BoxDecoration(color: separatorColor, shape: BoxShape.circle),
        ));
      }
    }
    return children;
  }

  @override
  Widget build(BuildContext context) {
    context.dilIzle();
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color topIconColor = isDark ? Colors.white : Colors.black87;
    final provider = context.watch<ZikirmatikProvider>();
    final currentView = provider.gorunumTuru;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF312E81)]
                : [const Color(0xFFE0F2FE), const Color(0xFFC4B5FD)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGlassButton(context,
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => context.pop()),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isDark ? Colors.white24 : Colors.black12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Theme(
                            data: Theme.of(context).copyWith(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent),
                            child: PopupMenuButton<String>(
                              icon: Icon(Icons.menu_rounded,
                                  color: topIconColor, size: 20),
                              offset: const Offset(0, 40),
                              color: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              onSelected: (value) {
                                if (value == 'v1') {
                                  provider.setGorunumTuru(1);
                                }
                                if (value == 'v2') {
                                  provider.setGorunumTuru(2);
                                }
                                if (value == 'v3') {
                                  provider.setGorunumTuru(3);
                                }
                                if (value == 'tesbih') {
                                  _showBeadColorPicker(); // Tesbih Renk Seçici
                                }
                                if (value == 'reset') {
                                  _sifirlaOnayla();
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                    value: 'v1',
                                    child: Row(children: [
                                      if (currentView == 1)
                                        const Icon(Icons.check,
                                            size: 18, color: Colors.blue)
                                      else
                                        const SizedBox(width: 18),
                                      const SizedBox(width: 12),
                                      Text(context.t('Görünüm 1'))
                                    ])),
                                PopupMenuItem(
                                    value: 'v2',
                                    child: Row(children: [
                                      if (currentView == 2)
                                        const Icon(Icons.check,
                                            size: 18, color: Colors.blue)
                                      else
                                        const SizedBox(width: 18),
                                      const SizedBox(width: 12),
                                      Text(context.t('Görünüm 2'))
                                    ])),
                                PopupMenuItem(
                                    value: 'v3',
                                    child: Row(children: [
                                      if (currentView == 3)
                                        const Icon(Icons.check,
                                            size: 18, color: Colors.blue)
                                      else
                                        const SizedBox(width: 18),
                                      const SizedBox(width: 12),
                                      Text(context.t('Görünüm 3'))
                                    ])),
                                const PopupMenuDivider(),
                                PopupMenuItem(
                                    value: 'tesbih',
                                    child: Row(children: [
                                      const SizedBox(width: 30),
                                      Text(context.t('Tesbih'))
                                    ])),
                                const PopupMenuDivider(),
                                PopupMenuItem(
                                    value: 'reset',
                                    child: Row(children: [
                                      const SizedBox(width: 18),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.refresh, size: 18),
                                      const SizedBox(width: 12),
                                      Text(context.t('Sıfırla'))
                                    ])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: currentView == 1
                    ? Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: AnimatedScale(
                            scale: _scale,
                            duration: const Duration(milliseconds: 100),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              width: 320,
                              height: 320,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: _isTapped
                                      ? [
                                          BoxShadow(
                                              color: Colors.redAccent
                                                  .withValues(alpha: 0.6),
                                              blurRadius: 50,
                                              spreadRadius: 15)
                                        ]
                                      : []),
                              child: ClipOval(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (_) => setState(() {
                                    _isTapped = true;
                                    _scale = 0.95;
                                  }),
                                  onTapUp: (_) {
                                    setState(() {
                                      _isTapped = false;
                                      _scale = 1.0;
                                    });
                                    _increment();
                                  },
                                  onTapCancel: () => setState(() {
                                    _isTapped = false;
                                    _scale = 1.0;
                                  }),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CustomPaint(
                                          size: const Size(320, 320),
                                          painter: ZikirRingPainter(
                                              progress: _count / _target,
                                              isDark: isDark)),
                                      _buildCountTexts(isDark,
                                          alignLeft: false),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => setState(() => _isTapped = true),
                        onTapUp: (_) {
                          setState(() => _isTapped = false);
                          _increment();
                        },
                        onTapCancel: () => setState(() => _isTapped = false),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 30,
                              top: 40,
                              // Sağdaki (görünüm 2) ya da alttaki (görünüm 3)
                              // tesbih boncuklarıyla çakışmasın.
                              right: currentView == 2 ? 120 : 30,
                              bottom: currentView == 3 ? 150 : 20,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCountTexts(isDark, alignLeft: true),
                                    _buildZikirMetni(isDark, alignLeft: true),
                                  ],
                                ),
                              ),
                            ),
                            if (currentView == 2)
                              Positioned(
                                  right: 16,
                                  top: 20,
                                  bottom: 20,
                                  child: Center(
                                      child: AnimatedSlide(
                                          offset: _isTapped
                                              ? const Offset(0, 0.05)
                                              : Offset.zero,
                                          duration:
                                              const Duration(milliseconds: 100),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: _buildBeadSequence(
                                                    isDark,
                                                    provider.tesbihRengi)),
                                          )))),
                            if (currentView == 3)
                              Positioned(
                                  left: 16,
                                  right: 16,
                                  bottom: 60,
                                  child: Center(
                                      child: AnimatedSlide(
                                          offset: _isTapped
                                              ? const Offset(0.05, 0)
                                              : Offset.zero,
                                          duration:
                                              const Duration(milliseconds: 100),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: _buildBeadSequence(
                                                    isDark,
                                                    provider.tesbihRengi)),
                                          )))),
                          ],
                        ),
                      ),
              ),
              if (currentView == 1) _buildZikirMetni(isDark),
            ],
          ),
        ),
      ),
    );
  }
}

class ZikirRingPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  ZikirRingPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final dotPaint = Paint()
      ..color = isDark ? Colors.white24 : Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 72; i++) {
      final angle = (i * 5) * pi / 180;
      canvas.drawCircle(
          Offset(center.dx + (radius) * cos(angle),
              center.dy + (radius) * sin(angle)),
          1.5,
          dotPaint);
    }

    final bgPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.blue.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 20),
        -pi / 2, 2 * pi, false, bgPaint);

    final progressPaint = Paint()
      ..color = Colors.redAccent.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 20),
        -pi / 2, 2 * pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ============================================================================
// 3. ZİKİR EKLE / DÜZENLE SAYFASI
// ============================================================================
class ZikirEkleDuzenlePage extends StatefulWidget {
  final Zikir? initialData;
  const ZikirEkleDuzenlePage({super.key, this.initialData});

  @override
  State<ZikirEkleDuzenlePage> createState() => _ZikirEkleDuzenlePageState();
}

class _ZikirEkleDuzenlePageState extends State<ZikirEkleDuzenlePage> {
  late TextEditingController adController;
  late TextEditingController adetController;
  late TextEditingController imameController;
  late TextEditingController arapcaController;
  late TextEditingController okunusuController;
  late TextEditingController anlamiController;

  @override
  void initState() {
    super.initState();
    adController = TextEditingController(text: widget.initialData?.ad ?? "");
    adetController = TextEditingController(
        text: widget.initialData?.hedef.toString() ?? "99");
    imameController = TextEditingController(
        text: widget.initialData?.imame?.toString() ?? "33");
    arapcaController =
        TextEditingController(text: widget.initialData?.arapca ?? "");
    okunusuController =
        TextEditingController(text: widget.initialData?.okunusu ?? "");
    anlamiController =
        TextEditingController(text: widget.initialData?.anlami ?? "");
  }

  @override
  void dispose() {
    adController.dispose();
    adetController.dispose();
    imameController.dispose();
    arapcaController.dispose();
    okunusuController.dispose();
    anlamiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.dilIzle();
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color fieldBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black;

    return SafeArea(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 10),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(10)),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGlassButton(context,
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context)),
                Text(
                    context.t(widget.initialData != null
                        ? "Zikri Düzenle"
                        : "Zikir Ekle"),
                    style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                _buildGlassButton(context, text: context.t("Kaydet"),
                    onTap: () {
                  final ad = adController.text.trim();
                  if (ad.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(context.t("Lütfen zikir adı girin."))));
                    return;
                  }
                  final hedef = int.tryParse(adetController.text) ?? 99;
                  if (hedef < 1) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(context.t("Adet en az 1 olmalı."))));
                    return;
                  }
                  final yeniZikir = Zikir(
                    id: widget.initialData?.id ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    ad: ad,
                    hedef: hedef,
                    imame: int.tryParse(imameController.text) ?? 33,
                    arapca: arapcaController.text,
                    okunusu: okunusuController.text,
                    anlami: anlamiController.text,
                  );
                  Navigator.pop(context, yeniZikir);
                }),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _buildInputLabel("Zikir Adı", isDark),
                _buildTextField(
                    adController, "Örn: Sübhânellâhi", fieldBg, textColor),
                _buildInputLabel("Adet", isDark),
                _buildTextField(adetController, "99", fieldBg, textColor,
                    isNumber: true),
                _buildInputLabel("İmame", isDark),
                _buildTextField(imameController, "33", fieldBg, textColor,
                    isNumber: true),
                _buildInputLabel("Arapça", isDark),
                _buildTextField(
                    arapcaController, "Arapça metin...", fieldBg, textColor),
                _buildInputLabel("Okunuşu", isDark),
                _buildTextField(
                    okunusuController, "Okunuşu...", fieldBg, textColor),
                _buildInputLabel("Anlamı", isDark),
                _buildTextField(
                    anlamiController, "Anlamı...", fieldBg, textColor),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6, top: 16),
      child: Text(context.t(text),
          style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, Color bg, Color textC,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      // Yalnız rakam (en çok 7 hane): "9.5" ya da çok uzun sayı sessizce 99'a
      // dönüyordu.
      inputFormatters: isNumber
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(7)
            ]
          : null,
      style: TextStyle(color: textC),
      decoration: InputDecoration(
        hintText: context.t(hint),
        hintStyle: TextStyle(color: textC.withValues(alpha: 0.3)),
        filled: true,
        fillColor: bg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
