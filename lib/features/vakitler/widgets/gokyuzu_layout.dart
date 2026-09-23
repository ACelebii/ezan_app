import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/vakit/vakit_modelleri.dart';
import '../gokyuzu_hesabi.dart';

/// "Gökyüzü" ana ekranı: arka plan o anki vakte göre renk değiştirir, güneş
/// (geceleri ay) gün içindeki yayında ilerler. Üstte gökyüzü, altta koyu bir
/// "zemin": geri sayım ve altı vakit orada, çünkü ufuk renkleri (açık mavi,
/// altın) beyaz yazı için fazla açık.
///
/// Ekran, uygulamanın açık/koyu temasından bağımsız hep koyudur; bu yüzden
/// durum çubuğu simgeleri de her zaman açık renklidir.
class GokyuzuLayout extends StatefulWidget {
  const GokyuzuLayout({
    super.key,
    required this.gunler,
    required this.simdi,
    required this.siradakiVakit,
    required this.remainingTime,
    required this.formatDuration,
    required this.vakitler,
    required this.buildWeatherHeader,
    required this.translate,
    this.tarihMetni,
    this.hicriMetni,
  });

  /// Dünden itibaren günlük vakitler (yayın ve rengin hesabı için).
  final List<GunlukVakit> gunler;
  final DateTime simdi;
  final String siradakiVakit;
  final Duration remainingTime;
  final String Function(Duration) formatDuration;

  /// `{"vakit": "İmsak", "saat": "05:17", ...}` satırları, vakit sırasıyla.
  final List<Map<String, String>> vakitler;
  final Widget Function(BuildContext, Color, Color) buildWeatherHeader;
  final String Function(String) translate;

  /// Başlığın altındaki tarih satırı: konumun takvimine göre miladi gün
  /// ("Pazar, 20 Eylül 2026") ve (varsa) hicri tarih ("8 Rebiülevvel 1448").
  final String? tarihMetni;
  final String? hicriMetni;

  @override
  State<GokyuzuLayout> createState() => _GokyuzuLayoutState();
}

class _GokyuzuLayoutState extends State<GokyuzuLayout> {
  static const _altin = Color(0xFFFFE9A8);

  /// Yalnızca hata ayıklama derlemesinde: gökyüzünü şimdiden kaç dakika sonraki
  /// ana göre çizdiği (paleti gün boyu gezip görmek için). Sürümde hep 0.
  int _onizlemeDk = 0;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final durum =
        gokyuzuDurumu(w.gunler, w.simdi.add(Duration(minutes: _onizlemeDk)));
    final zemin1 = Color.lerp(durum.ufuk, Colors.black, 0.72)!;
    final zemin2 = Color.lerp(durum.ust, Colors.black, 0.85)!;
    final tarih = [
      if (w.tarihMetni != null) w.tarihMetni!,
      if (w.hicriMetni != null) w.hicriMetni!,
    ].join('  ·  ');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: durum.ust,
        body: Column(
          children: [
            Expanded(
              flex: 11,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [durum.ust, durum.ufuk]),
                ),
                child: Column(
                  children: [
                    SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: w.buildWeatherHeader(
                              context, Colors.white, _altin),
                        )),
                    if (tarih.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(tarih,
                              maxLines: 1,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    Expanded(
                      child: ClipRect(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(painter: _GokyuzuBoyaci(durum)),
                            if (kDebugMode) _onizlemeCubugu(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 9,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [zemin1, zemin2]),
                ),
                // Kısa ekranda sığmazsa kayar; sığıyorsa ortalanır.
                child: LayoutBuilder(
                  builder: (context, kutu) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: kutu.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(w.translate("${w.siradakiVakit} vaktine kalan"),
                              style: const TextStyle(
                                  color: _altin,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(w.formatDuration(w.remainingTime),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 60,
                                    fontWeight: FontWeight.w300,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ])),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              for (final v in w.vakitler)
                                Expanded(
                                    child: _VakitKutusu(
                                        v,
                                        v['vakit'] == w.siradakiVakit,
                                        w.translate)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hata ayıklama önizlemesi: kaydırınca gökyüzü şimdiden N dakika sonraki
  /// hâliyle çizilir (24 saat ileri). Yazıya dokunmak sıfırlar.
  Widget _onizlemeCubugu() {
    final saat = _onizlemeDk ~/ 60, dk = _onizlemeDk % 60;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _onizlemeDk = 0),
              child: Text(
                  _onizlemeDk == 0
                      ? 'önizleme (hata ayıklama)'
                      : 'önizleme +${saat}sa ${dk}dk',
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ),
            Expanded(
              // Slider, verilen bütün yüksekliği kaplar: sınırlanmazsa çubuk
              // ekranın ortasına oturur.
              child: SizedBox(
                height: 36,
                child: Slider(
                  min: 0,
                  max: 1440,
                  value: _onizlemeDk.toDouble(),
                  onChanged: (v) => setState(() => _onizlemeDk = v.round()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VakitKutusu extends StatelessWidget {
  const _VakitKutusu(this.vakit, this.siradaki, this.translate);

  final Map<String, String> vakit;
  final bool siradaki;
  final String Function(String) translate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: siradaki ? Colors.white.withValues(alpha: 0.16) : null,
        borderRadius: BorderRadius.circular(14),
        border: siradaki
            ? Border.all(color: Colors.white.withValues(alpha: 0.5))
            : null,
      ),
      child: Column(
        children: [
          Text(translate(vakit['vakit'] ?? ''),
              maxLines: 1,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: siradaki ? 0.95 : 0.6),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(vakit['saat'] ?? '--:--',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: siradaki ? FontWeight.w800 : FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

/// Yıldızlar, yay, ufuk çizgisi ve güneş/ay. Ufuk, çizim alanının alt kenarıdır
/// (altında zemin panel başlar); güneş ufukta yarı görünerek doğar ve batar.
class _GokyuzuBoyaci extends CustomPainter {
  _GokyuzuBoyaci(this.durum);

  final GokyuzuDurumu durum;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, rx = w * 0.40, ry = h * 0.78;

    // Yıldızlar: gökyüzü koyulaştıkça belirir (üst rengin parlaklığına göre).
    final karanlik = (1 - durum.ust.computeLuminance() / 0.06).clamp(0.0, 1.0);
    if (karanlik > 0) {
      final rastgele = math.Random(7);
      final firca = Paint();
      for (var i = 0; i < 45; i++) {
        final x = rastgele.nextDouble() * w;
        final y = rastgele.nextDouble() * h * 0.8;
        final parlaklik = 0.3 + rastgele.nextDouble() * 0.5;
        firca.color = Colors.white.withValues(alpha: parlaklik * karanlik);
        canvas.drawCircle(
            Offset(x, y), 0.6 + rastgele.nextDouble() * 1.1, firca);
      }
    }

    // Yay: soluk kesikli çizgi, geçilen kısmı belirgin.
    final yay = Path()
      ..addArc(
          Rect.fromCenter(center: Offset(cx, h), width: rx * 2, height: ry * 2),
          math.pi,
          math.pi);
    final metrik = yay.computeMetrics().first;
    final soluk = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var d = 0.0; d < metrik.length; d += 14) {
      canvas.drawPath(
          metrik.extractPath(d, math.min(d + 6, metrik.length)), soluk);
    }

    canvas.drawLine(
        Offset(0, h - 0.5),
        Offset(w, h - 0.5),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..strokeWidth = 1);

    final t = durum.ilerleme;
    if (t == null) return;

    canvas.drawPath(
        metrik.extractPath(0, metrik.length * t),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round);

    final p =
        Offset(cx - rx * math.cos(math.pi * t), h - ry * math.sin(math.pi * t));
    if (durum.gunduz) {
      canvas.drawCircle(
          p,
          64,
          Paint()
            ..shader = const RadialGradient(colors: [
              Color(0xB3FFE9A8),
              Color(0x00FFE9A8),
            ]).createShader(Rect.fromCircle(center: p, radius: 64)));
      canvas.drawCircle(p, 17, Paint()..color = const Color(0xFFFFF1B8));
    } else {
      canvas.drawCircle(
          p,
          46,
          Paint()
            ..shader = const RadialGradient(colors: [
              Color(0x66DCE3FF),
              Color(0x00DCE3FF),
            ]).createShader(Rect.fromCircle(center: p, radius: 46)));
      final hilal = Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: p, radius: 15)),
        Path()
          ..addOval(
              Rect.fromCircle(center: p + const Offset(7, -4), radius: 13)),
      );
      canvas.drawPath(hilal, Paint()..color = const Color(0xFFEDEFFF));
    }
  }

  @override
  bool shouldRepaint(_GokyuzuBoyaci eski) =>
      eski.durum.ust != durum.ust ||
      eski.durum.ufuk != durum.ufuk ||
      eski.durum.gunduz != durum.gunduz ||
      eski.durum.ilerleme != durum.ilerleme;
}
