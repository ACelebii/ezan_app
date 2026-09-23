import 'package:ezan_vakti_uygulamasi/core/i18n/ek_ceviriler.dart';
import 'package:ezan_vakti_uygulamasi/features/auth/auth_service.dart';
import 'package:ezan_vakti_uygulamasi/features/zikirmatik/zikir.dart';
import 'package:ezan_vakti_uygulamasi/features/zikirmatik/zikirmatik_page.dart';
import 'package:ezan_vakti_uygulamasi/features/zikirmatik/zikirmatik_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gerçek ek sözlüğü kullanır; [ingilizce] ise çevirir.
class _SahteAuth extends ChangeNotifier with Fake implements AuthService {
  _SahteAuth({this.ingilizce = false});

  final bool ingilizce;

  @override
  String get uygulamaDili => ingilizce ? 'English' : 'Türkçe';
  @override
  String translate(String? text) =>
      text == null ? '' : (ingilizce ? ekCeviriEn(text) ?? text : text);
}

Future<ZikirmatikProvider> _listeyiAc(WidgetTester t,
    {bool ingilizce = false}) async {
  SharedPreferences.setMockInitialValues({});
  final p = ZikirmatikProvider();
  await t.pump();
  await t.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthService>.value(
          value: _SahteAuth(ingilizce: ingilizce) as AuthService),
      ChangeNotifierProvider<ZikirmatikProvider>.value(value: p),
    ],
    child: const MaterialApp(home: ZikirmatikPage()),
  ));
  await t.pump();
  return p;
}

void main() {
  testWidgets(
      'ortadaki zikri kaydırıp silince doğru zikir kalkar; ekran bozulmaz',
      (t) async {
    final p = await _listeyiAc(t);
    p.hazirdanEkle(p.hazirZikirler[0]); // 100 Sübhânellâhi
    p.hazirdanEkle(p.hazirZikirler[0]); // 99 Lâ havle
    await t.pump();
    expect(p.aktifZikirler.map((z) => z.ad),
        ['Zikirmatik', '100 Sübhânellâhi', '99 Lâ havle']);

    await t.drag(find.text('100 Sübhânellâhi').first, const Offset(-600, 0));
    await t.pumpAndSettle();

    expect(t.takeException(), isNull);
    expect(p.aktifZikirler.map((z) => z.ad), ['Zikirmatik', '99 Lâ havle']);
    // Kalan iki zikir da ekranda görünür yükseklikte (biri çökmüş olmasın).
    for (final ad in ['Zikirmatik', '99 Lâ havle']) {
      expect(t.getSize(find.widgetWithText(ListTile, ad).first).height,
          greaterThan(40),
          reason: '$ad satırı görünür olmalı');
    }
  });

  testWidgets(
      'varsayılan "Zikirmatik" satırı kaydırılınca ne silinir ne ekrandan kaybolur',
      (t) async {
    final p = await _listeyiAc(t);

    await t.drag(find.text('Zikirmatik').first, const Offset(-600, 0));
    await t.pumpAndSettle();

    expect(t.takeException(), isNull);
    expect(p.aktifZikirler.map((z) => z.ad), ['Zikirmatik']);
    expect(find.text('Zikirmatik'), findsOneWidget,
        reason: 'varsayılan satır kaybolmamalı');
  });

  testWidgets(
      'Zikir Ekle formu: klavye açıkken en alttaki alan klavyenin üstünde kalır',
      (t) async {
    await t.binding.setSurfaceSize(const Size(360, 780));
    // Klavye: 320 mantıksal piksel (FakeViewPadding fiziksel piksel ister).
    t.view.viewInsets = FakeViewPadding(bottom: 320 * t.view.devicePixelRatio);
    addTearDown(() {
      t.view.resetViewInsets();
      t.binding.setSurfaceSize(null);
    });
    await _listeyiAc(t);
    await t.tap(find.byIcon(Icons.add));
    await t.pumpAndSettle();

    final sonAlan = find.byType(TextField).last; // Anlamı
    await t.ensureVisible(sonAlan);
    await t.pumpAndSettle();

    expect(t.getRect(sonAlan).bottom, lessThanOrEqualTo(780 - 320),
        reason: 'alan klavyenin arkasında kalmamalı');
  });

  testWidgets(
      'Hazır listesinde yalnız kendi eklediğin zikirde sil düğmesi var; onayla kalıcı silinir',
      (t) async {
    final p = await _listeyiAc(t);
    p.zikirEkle(Zikir(id: '1', ad: 'Benim', hedef: 10, imame: 5));
    p.aktiftenKaldir(p.aktifZikirler.last); // hazır listesine düşer
    await t.pump();
    final hazirAdet = p.hazirZikirler.length;

    expect(find.byTooltip('Kalıcı olarak sil'), findsOneWidget,
        reason: 'hazır (fabrika) zikirlerde sil düğmesi olmamalı');

    await t.tap(find.byTooltip('Kalıcı olarak sil'));
    await t.pumpAndSettle();
    expect(find.text('"Benim" silinsin mi?'), findsOneWidget);
    await t.tap(find.text('Vazgeç'));
    await t.pumpAndSettle();
    expect(p.hazirZikirler.length, hazirAdet, reason: 'Vazgeç silmez');

    await t.tap(find.byTooltip('Kalıcı olarak sil'));
    await t.pumpAndSettle();
    await t.tap(find.text('Sil'));
    await t.pumpAndSettle();
    expect(p.hazirZikirler.any((z) => z.ad == 'Benim'), isFalse);
    expect(p.hazirZikirler.length, hazirAdet - 1);
    expect(find.byTooltip('Kalıcı olarak sil'), findsNothing);
  });

  testWidgets(
      'Zikir Ekle formunda Adet ve İmame yalnız rakam kabul eder (en çok 7 hane)',
      (t) async {
    await t.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await _listeyiAc(t);
    await t.tap(find.byIcon(Icons.add));
    await t.pumpAndSettle();

    final adet = find.byType(TextField).at(1);
    await t.enterText(adet, '1a2.b3-');
    expect(t.widget<TextField>(adet).controller!.text, '123');
    await t.enterText(adet, '123456789');
    expect(t.widget<TextField>(adet).controller!.text, '1234567');
    final imame = find.byType(TextField).at(2);
    await t.enterText(imame, '4,5');
    expect(t.widget<TextField>(imame).controller!.text, '45');
  });

  group('İngilizce arayüz', () {
    testWidgets(
        'liste: Düzenle, hazır zikir adları ve kalıcı silme penceresi İngilizce',
        (t) async {
      final p = await _listeyiAc(t, ingilizce: true);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('100 Subhanallah'), findsOneWidget);
      expect(find.text('Salawat'), findsOneWidget);
      expect(find.text('Salavat'), findsNothing);

      p.zikirEkle(Zikir(id: '1', ad: 'Benim', hedef: 10, imame: 5));
      p.aktiftenKaldir(p.aktifZikirler.last);
      await t.pump();
      await t.tap(find.byTooltip('Delete permanently'));
      await t.pumpAndSettle();

      expect(find.text('Delete "Benim"?'), findsOneWidget,
          reason: 'kullanıcının yazdığı ad çevrilmez, kalıp çevrilir');
      expect(
          find.text('The dhikr and its counter will be permanently deleted.'),
          findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets(
        'Zikir Ekle formu: başlık, etiketler ve doğrulama iletisi İngilizce',
        (t) async {
      // MediaQuery de bu boyutu görsün (form yüksekliği ondan hesaplanır).
      t.view.physicalSize = const Size(1080, 4500);
      addTearDown(t.view.resetPhysicalSize);
      await _listeyiAc(t, ingilizce: true);
      await t.tap(find.byIcon(Icons.add));
      await t.pumpAndSettle();

      for (final e in [
        'Add Dhikr',
        'Dhikr Name',
        'Count',
        'Marker Bead',
        'Arabic',
        'Transliteration',
        'Meaning'
      ]) {
        expect(find.text(e), findsOneWidget, reason: e);
      }
      expect(find.text('e.g. Subhanallah'), findsOneWidget);

      // Save düğmesi ana sözlükten çevrilir; sahte çeviri onu bilmez.
      await t.tap(find.text('Kaydet'));
      await t.pump();
      expect(find.text('Please enter a dhikr name.'), findsOneWidget);
    });

    testWidgets('Türkçede metinler olduğu gibi kalır', (t) async {
      await _listeyiAc(t);

      expect(find.text('Düzenle'), findsOneWidget);
      expect(find.text('100 Sübhânellâhi'), findsOneWidget);
    });
  });
}
