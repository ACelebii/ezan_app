import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_modelleri.dart';
import 'package:ezan_vakti_uygulamasi/features/vakitler/widgets/gokyuzu_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

GunlukVakit _gun(int gun, List<String> saatler) => GunlukVakit(
      tarih: DateTime.utc(2026, 9, gun),
      kaynak: VakitKaynagi.diyanet,
      saatler: {for (var i = 0; i < 6; i++) Vakit.values[i]: saatler[i]},
      anlar: {
        for (var i = 0; i < 6; i++)
          Vakit.values[i]: DateTime.utc(
              2026,
              9,
              gun,
              int.parse(saatler[i].split(':')[0]) - 3,
              int.parse(saatler[i].split(':')[1])),
      },
    );

final _gunler = [
  _gun(19, ['05:16', '06:41', '13:03', '16:30', '19:15', '20:35']),
  _gun(20, ['05:17', '06:42', '13:03', '16:29', '19:13', '20:33']),
  _gun(21, ['05:18', '06:43', '13:03', '16:28', '19:11', '20:31']),
];

final _vakitler = [
  for (final v in Vakit.values) {'vakit': v.ad, 'saat': _gunler[1].saatler[v]!},
];

Widget _ekran(List<GunlukVakit> gunler, DateTime simdi, String siradaki,
        Duration kalan,
        {String? tarih,
        String? hicri,
        TextDirection yon = TextDirection.ltr}) =>
    MaterialApp(
      home: Directionality(
        textDirection: yon,
        child: GokyuzuLayout(
          gunler: gunler,
          simdi: simdi,
          siradakiVakit: siradaki,
          remainingTime: kalan,
          formatDuration: (d) => '${d.inHours.toString().padLeft(2, '0')}:'
              '${(d.inMinutes % 60).toString().padLeft(2, '0')}:'
              '${(d.inSeconds % 60).toString().padLeft(2, '0')}',
          vakitler: _vakitler,
          buildWeatherHeader: (c, renk, vurgu) =>
              Text('İstanbul', style: TextStyle(color: renk)),
          translate: (t) => t,
          tarihMetni: tarih,
          hicriMetni: hicri,
        ),
      ),
    );

void main() {
  // İstanbul yerel saatinden an.
  DateTime an(int s, int d) => DateTime.utc(2026, 9, 20, s - 3, d);

  testWidgets('geri sayımı, sıradaki vakti ve altı vakti gösterir',
      (tester) async {
    await tester.pumpWidget(_ekran(
        _gunler, an(13, 3), 'İkindi', const Duration(hours: 3, minutes: 26)));

    expect(find.text('İkindi vaktine kalan'), findsOneWidget);
    expect(find.text('03:26:00'), findsOneWidget);
    for (final v in _vakitler) {
      expect(find.text(v['vakit']!), findsOneWidget);
      expect(find.text(v['saat']!), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('günün her saatinde ve vakit verisi yokken çizim hata vermez',
      (tester) async {
    for (final s in [0, 3, 5, 6, 9, 13, 17, 19, 20, 23]) {
      await tester.pumpWidget(
          _ekran(_gunler, an(s, 30), 'Öğle', const Duration(hours: 1)));
      expect(tester.takeException(), isNull, reason: '$s:30');
    }
    // Vakit verisi yok: yay çizilmez ama ekran çökmez.
    await tester.pumpWidget(_ekran(const [], an(12, 0), 'Öğle', Duration.zero));
    expect(tester.takeException(), isNull);
  });

  for (final boyut in [
    const Size(360, 640),
    const Size(320, 568),
    const Size(411, 900)
  ]) {
    testWidgets(
        '${boyut.width.toInt()}x${boyut.height.toInt()} ekranda taşma olmaz',
        (tester) async {
      tester.view.physicalSize = boyut * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_ekran(
          _gunler, an(13, 3), 'İkindi', const Duration(hours: 3, minutes: 26)));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'tarih ve hicri tarih başlığın altında görünür; verilmezse satır yok',
      (tester) async {
    await tester.pumpWidget(_ekran(
        _gunler, an(13, 3), 'İkindi', const Duration(hours: 3, minutes: 26),
        tarih: 'Pazar, 20 Eylül 2026', hicri: '8 Rebiülevvel 1448'));
    expect(find.text('Pazar, 20 Eylül 2026  ·  8 Rebiülevvel 1448'),
        findsOneWidget);

    await tester.pumpWidget(_ekran(
        _gunler, an(13, 3), 'İkindi', const Duration(hours: 3, minutes: 26),
        tarih: 'Pazar, 20 Eylül 2026'));
    expect(find.text('Pazar, 20 Eylül 2026'),
        findsOneWidget); // hicri yoksa yalnızca miladi

    await tester.pumpWidget(_ekran(
        _gunler, an(13, 3), 'İkindi', const Duration(hours: 3, minutes: 26)));
    expect(find.textContaining('·'), findsNothing);
  });

  testWidgets('durum çubuğu şeffaf ve simgeleri açık renkli (ekran hep koyu)',
      (tester) async {
    await tester.pumpWidget(
        _ekran(_gunler, an(13, 3), 'İkindi', const Duration(hours: 1)));
    final bolge = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first);
    expect(bolge.value.statusBarIconBrightness, Brightness.light);
    expect(bolge.value.statusBarColor, Colors.transparent);
  });

  for (final boyut in [
    const Size(360, 640),
    const Size(320, 568),
    const Size(411, 900)
  ]) {
    testWidgets(
        'sağdan sola (Arapça) yönde ${boyut.width.toInt()}x${boyut.height.toInt()} ekranda taşma olmaz',
        (tester) async {
      tester.view.physicalSize = boyut * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_ekran(
          _gunler, an(13, 3), 'İkindi', const Duration(hours: 3, minutes: 26),
          tarih: 'Pazar, 20 Eylül 2026 (uzun bir tarih metni)',
          hicri: '8 Rebiülevvel 1448',
          yon: TextDirection.rtl));
      expect(tester.takeException(), isNull);
      expect(find.text('03:26:00'), findsOneWidget);
    });
  }

  testWidgets(
      'hata ayıklama önizlemesi: çubuk kaydırılınca gökyüzü ilerler, yazıya dokunmak sıfırlar',
      (tester) async {
    await tester.pumpWidget(
        _ekran(_gunler, an(13, 3), 'İkindi', const Duration(hours: 1)));
    expect(find.text('önizleme (hata ayıklama)'), findsOneWidget);

    await tester.drag(find.byType(Slider), const Offset(120, 0));
    await tester.pump();
    expect(find.textContaining('önizleme +'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.textContaining('önizleme +'));
    await tester.pump();
    expect(find.text('önizleme (hata ayıklama)'), findsOneWidget);
  });
}
