import 'package:ezan_vakti_uygulamasi/core/ekran_uyanik.dart';
import 'package:ezan_vakti_uygulamasi/core/i18n/ek_ceviriler.dart';
import 'package:ezan_vakti_uygulamasi/features/auth/auth_service.dart';
import 'package:ezan_vakti_uygulamasi/features/zikirmatik/zikir.dart';
import 'package:ezan_vakti_uygulamasi/features/zikirmatik/zikirmatik_page.dart';
import 'package:ezan_vakti_uygulamasi/features/zikirmatik/zikirmatik_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

Future<ZikirmatikProvider> _sayacAc(WidgetTester t, Zikir zikir,
    {int gorunum = 1, bool ingilizce = false}) async {
  SharedPreferences.setMockInitialValues({'zikirmatik_gorunum_turu': gorunum});
  final p = ZikirmatikProvider();
  await t.pump();
  await t.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<ZikirmatikProvider>.value(value: p),
      ChangeNotifierProvider<AuthService>.value(
          value: _SahteAuth(ingilizce: ingilizce) as AuthService),
    ],
    child: MaterialApp(home: ZikirmatikSayacPage(zikir: zikir)),
  ));
  await t.pump();
  return p;
}

Future<void> _ekran(WidgetTester t, Size boyut) async {
  await t.binding.setSurfaceSize(boyut);
  addTearDown(() => t.binding.setSurfaceSize(null));
}

/// Titreşim çağrılarını ('HapticFeedbackType.heavyImpact' gibi) toplar.
List<String> _titresimleriDinle(WidgetTester t) {
  final cagrilar = <String>[];
  t.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'HapticFeedback.vibrate') {
      cagrilar.add(call.arguments as String);
    }
    return null;
  });
  addTearDown(() => t.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));
  return cagrilar;
}

void main() {
  // Gerçek eklenti çağrılmasın; çağrılar kaydedilir.
  late List<bool> uyanikCagrilari;
  setUp(() {
    uyanikCagrilari = [];
    EkranUyanik.ayarla = (acik) async => uyanikCagrilari.add(acik);
  });

  group('ekran uyanık', () {
    testWidgets('sayaç açılınca ekran uyanık tutulur, kapanınca bırakılır',
        (t) async {
      await _sayacAc(t, Zikir(ad: 'x', hedef: 33, imame: 11));
      expect(uyanikCagrilari, [true]);

      await t.pumpWidget(const SizedBox()); // sayfa kapandı
      expect(uyanikCagrilari, [true, false]);
    });

    testWidgets('eklenti hata verse de sayaç çalışır (çökmez)', (t) async {
      EkranUyanik.ayarla = (_) async => throw Exception('eklenti yok');
      final z = Zikir(ad: 'x', hedef: 33, imame: 11);
      await _sayacAc(t, z);

      await t.tap(find.byType(ClipOval));
      await t.pump();

      expect(z.sayi, 1);
      expect(t.takeException(), isNull);
    });
  });

  group('büyük sayılar', () {
    // Halka 320 px, iç çapı ~254 px: sayı ve hedef bunun içinde kalmalı
    // (telefonda 99999/100000 halkanın üstüne taşıyordu).
    for (final (hedef, sayi) in [
      (99, 98),
      (1000, 999),
      (10000, 9999),
      (100000, 99999),
      (1000000, 999999),
    ]) {
      testWidgets('görünüm 1: $sayi / $hedef halkanın içine sığar, taşma yok',
          (t) async {
        await _ekran(t, const Size(360, 780));
        await _sayacAc(t, Zikir(ad: 'x', sayi: sayi, hedef: hedef, imame: 33));

        expect(t.takeException(), isNull,
            reason: 'RenderFlex taşması olmamalı');
        expect(
            t.getRect(find.text('$sayi')).left, greaterThanOrEqualTo(180 - 127),
            reason: 'sayının solu halkaya biniyor');
        expect(
            t.getRect(find.text('/$hedef')).right, lessThanOrEqualTo(180 + 127),
            reason: 'hedefin sağı halkaya biniyor');
      });
    }

    for (final gorunum in [2, 3]) {
      testWidgets('görünüm $gorunum: büyük sayı taşmaz', (t) async {
        await _ekran(t, const Size(360, 780));
        await _sayacAc(t, Zikir(ad: 'x', sayi: 99999, hedef: 100000, imame: 33),
            gorunum: gorunum);

        expect(t.takeException(), isNull);
        expect(t.getRect(find.text('/100000')).right,
            lessThanOrEqualTo(30 + 230 + 1));
      });
    }
  });

  group('Arapça, okunuşu, anlamı', () {
    Zikir zikir({String? arapca, String? anlami}) => Zikir(
        ad: 'x',
        hedef: 33,
        imame: 11,
        arapca: arapca ?? 'سُبْحَانَ اللّٰهِ',
        okunusu: 'Sübhânellâh',
        anlami: anlami ?? "Allah'ı tesbih ederim");

    for (final gorunum in [1, 2, 3]) {
      testWidgets('görünüm $gorunum: üç metin de görünür, taşma yok',
          (t) async {
        await _ekran(t, const Size(360, 780));
        await _sayacAc(t, zikir(), gorunum: gorunum);

        expect(find.text('سُبْحَانَ اللّٰهِ'), findsOneWidget);
        expect(find.text('Sübhânellâh'), findsOneWidget);
        expect(find.text("Allah'ı tesbih ederim"), findsOneWidget);
        expect(t.takeException(), isNull);
      });

      testWidgets('görünüm $gorunum: çok uzun metin ve küçük ekranda taşma yok',
          (t) async {
        await _ekran(t, const Size(320, 568));
        final uzun = List.filled(60, 'اللّٰهُ أَكْبَرُ').join(' ');
        await _sayacAc(
            t, zikir(arapca: uzun, anlami: List.filled(80, 'anlam').join(' ')),
            gorunum: gorunum);

        expect(t.takeException(), isNull);
      });
    }

    testWidgets('metin girilmemişse hiçbir şey eklenmez', (t) async {
      await _ekran(t, const Size(360, 780));
      await _sayacAc(
          t, Zikir(ad: 'x', hedef: 33, imame: 11, arapca: '  ', okunusu: ''));

      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(t.takeException(), isNull);
    });
  });

  group('titreşim', () {
    testWidgets('her imamede orta, hedef dolunca güçlü titreşim; arada yok',
        (t) async {
      final cagrilar = _titresimleriDinle(t);
      await _sayacAc(t, Zikir(ad: 'x', sayi: 0, hedef: 5, imame: 3));

      for (var i = 1; i <= 5; i++) {
        await t.tap(find.byType(ClipOval));
        await t.pump();
      }

      expect(cagrilar, [
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.heavyImpact'
      ]);
    });
  });

  group('ses tuşu', () {
    // Gerçek olayı MainActivity.kt yakalayıp bu kanaldan bildirir; testte
    // native tarafı "basildi" mesajıyla simüle ediyoruz.
    const kanal = MethodChannel('com.acelebi.ezanvakti/ses_tusu');

    setUp(() {
      // Dart -> native "dinlemeyiAyarla" çağrıları (initState/dispose)
      // sessizce başarıyla yanıtlansın.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(kanal, (call) async => null);
    });
    tearDown(() => TestDefaultBinaryMessengerBinding.instance
        .defaultBinaryMessenger
        .setMockMethodCallHandler(kanal, null));

    Future<void> basildiSimuleEt(WidgetTester t) async {
      final veri =
          const StandardMethodCodec().encodeMethodCall(const MethodCall('basildi'));
      await t.binding.defaultBinaryMessenger
          .handlePlatformMessage(kanal.name, veri, (_) {});
    }

    testWidgets('native "basildi" bildirince sayaç artar', (t) async {
      final z = Zikir(ad: 'x', hedef: 33, imame: 11);
      await _sayacAc(t, z);

      await basildiSimuleEt(t);
      await t.pump();
      await basildiSimuleEt(t);
      await t.pump();

      expect(z.sayi, 2);
    });
  });

  group('sıfırla', () {
    Future<void> menudenSifirla(WidgetTester t) async {
      await t.tap(find.byIcon(Icons.menu_rounded));
      await t.pumpAndSettle();
      await t.tap(find.text('Sıfırla'));
      await t.pumpAndSettle();
    }

    testWidgets('ilerleme varken önce sorar: Vazgeç korur, Sıfırla siler',
        (t) async {
      final zikir = Zikir(ad: 'x', sayi: 7, hedef: 10, imame: 5, tur: 2);
      await _sayacAc(t, zikir);

      await menudenSifirla(t);
      expect(find.text('Sayaç sıfırlansın mı?'), findsOneWidget);
      expect(find.text('7/10 ve 2 tur silinecek.'), findsOneWidget);
      await t.tap(find.text('Vazgeç'));
      await t.pumpAndSettle();
      expect(zikir.sayi, 7);

      await menudenSifirla(t);
      await t.tap(find.widgetWithText(TextButton, 'Sıfırla'));
      await t.pumpAndSettle();
      expect((zikir.sayi, zikir.tur), (0, 0));
    });

    testWidgets('kaybedilecek ilerleme yoksa soru sormaz', (t) async {
      await _sayacAc(t, Zikir(ad: 'x', sayi: 0, hedef: 10, imame: 5));

      await menudenSifirla(t);

      expect(find.text('Sayaç sıfırlansın mı?'), findsNothing);
    });
  });

  group('İngilizce arayüz', () {
    testWidgets('hazır zikirin okunuşu ve anlamı, imame ve menü İngilizce',
        (t) async {
      await _ekran(t, const Size(360, 780));
      final salavat = Zikir(
        ad: 'Salavat',
        hedef: 100,
        imame: 25,
        arapca: 'ا',
        okunusu:
            'Allahümme Salli Ala Seyyidina Muhammedin ve Ala Ali Seyyidina Muhammed',
        anlami: "Allah'ım, efendimiz Hz. Muhammed'e ve aline salat eyle.",
      );
      await _sayacAc(t, salavat, ingilizce: true);

      expect(find.text('Marker bead: 25'), findsOneWidget);
      expect(
          find.text(
              'Allahumma salli ala sayyidina Muhammadin wa ala ali sayyidina Muhammad'),
          findsOneWidget);
      expect(
          find.text(
              'O Allah, send blessings upon our master Muhammad and upon his family.'),
          findsOneWidget);

      await t.tap(find.byIcon(Icons.menu_rounded));
      await t.pumpAndSettle();
      for (final e in ['View 1', 'View 2', 'View 3', 'Prayer Beads', 'Reset']) {
        expect(find.text(e), findsOneWidget, reason: e);
      }
    });

    testWidgets('kullanıcının kendi yazdığı okunuş ve anlam çevrilmez',
        (t) async {
      await _ekran(t, const Size(360, 780));
      await _sayacAc(
          t,
          Zikir(
              ad: 'x',
              hedef: 33,
              imame: 11,
              okunusu: 'Benim okunuşum',
              anlami: 'Benim anlamım'),
          ingilizce: true);

      expect(find.text('Benim okunuşum'), findsOneWidget);
      expect(find.text('Benim anlamım'), findsOneWidget);
    });

    testWidgets('sıfırlama onayı İngilizce', (t) async {
      await _sayacAc(t, Zikir(ad: 'x', sayi: 7, hedef: 10, imame: 5, tur: 2),
          ingilizce: true);

      await t.tap(find.byIcon(Icons.menu_rounded));
      await t.pumpAndSettle();
      await t.tap(find.text('Reset'));
      await t.pumpAndSettle();

      expect(find.text('Reset the counter?'), findsOneWidget);
      expect(find.text('7/10 and 2 rounds will be cleared.'), findsOneWidget);
    });
  });
}
