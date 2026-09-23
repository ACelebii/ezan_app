import 'package:ezan_vakti_uygulamasi/core/vakit/kayitli_sehir.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_modelleri.dart';
import 'package:ezan_vakti_uygulamasi/features/auth/auth_service.dart';
import 'package:ezan_vakti_uygulamasi/features/settings/cities_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class _SahteAuth extends ChangeNotifier with Fake implements AuthService {
  _SahteAuth(this.kayitli);

  final List<KayitliSehir> kayitli;
  List<KayitliSehir>? kaydedilen;

  @override
  String get uygulamaDili => 'Türkçe';
  @override
  String translate(String? text) => text ?? '';
  @override
  List<KayitliSehir> get kayitliSehirler => kayitli;
  @override
  Future<void> sehirleriKaydet(List<KayitliSehir> liste) async =>
      kaydedilen = liste;
}

KayitliSehir _il(String ad, {bool secili = false}) => KayitliSehir.fromMap({
      'isim': ad,
      'sehir': 'Türkiye',
      'tur': 'Diyanet Takvimi',
      'secili': secili ? 'true' : 'false',
    })!;

const _los = KayitliSehir(
    isim: 'Los Angeles',
    ulke: 'Amerika Birleşik Devletleri',
    tur: 'Diyanet Takvimi',
    konum: Konum(
        ad: 'Los Angeles',
        saatDilimi: 'America/Los_Angeles',
        diyanetIlceId: 8626,
        enlem: 34.05,
        boylam: -118.24));

Future<_SahteAuth> _ac(WidgetTester tester, List<KayitliSehir> sehirler) async {
  final auth = _SahteAuth(sehirler);
  final router = GoRouter(routes: [
    GoRoute(
        path: '/',
        builder: (c, _) => Scaffold(
            body: Center(
                child: ElevatedButton(
                    onPressed: () => c.push('/sehirler'),
                    child: const Text('ac'))))),
    GoRoute(path: '/sehirler', builder: (c, _) => const CitiesPage()),
  ]);
  await tester.pumpWidget(ChangeNotifierProvider<AuthService>.value(
      value: auth as AuthService,
      child: MaterialApp.router(routerConfig: router)));
  await tester.tap(find.text('ac'));
  await tester.pumpAndSettle();
  return auth;
}

void main() {
  testWidgets(
      'şehirler ad, ülke ve hesaplama yöntemiyle listelenir; seçili olanda onay işareti var',
      (tester) async {
    await _ac(tester, [_il('İstanbul', secili: true), _il('Ankara'), _los]);

    expect(find.text('İstanbul'), findsOneWidget);
    expect(find.text('Los Angeles'), findsOneWidget);
    expect(find.textContaining('Amerika Birleşik Devletleri'), findsOneWidget);
    expect(find.textContaining('Diyanet Takvimi'), findsNWidgets(3));
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('bir şehre dokunmak onu seçer ve sayfayı kapatır',
      (tester) async {
    final auth =
        await _ac(tester, [_il('İstanbul', secili: true), _il('Ankara'), _los]);

    await tester.tap(find.text('Los Angeles'));
    await tester.pumpAndSettle();

    expect([for (final s in auth.kaydedilen!) '${s.isim}:${s.secili}'],
        ['İstanbul:false', 'Ankara:false', 'Los Angeles:true']);
    expect(find.text('ac'), findsOneWidget, reason: 'sayfa kapanmalı');
  });

  testWidgets('düzenleme modunda şehre dokunmak seçmez', (tester) async {
    final auth =
        await _ac(tester, [_il('İstanbul', secili: true), _il('Ankara')]);

    await tester.tap(find.text('Düzenle'));
    await tester.pump();
    await tester.tap(find.text('Ankara'));
    await tester.pumpAndSettle();

    expect(auth.kaydedilen, isNull);
    expect(find.text('Şehirler'), findsOneWidget);
  });

  testWidgets('seçili şehir silinirse ilk kalan şehir seçilir', (tester) async {
    final auth = await _ac(
        tester, [_il('İstanbul', secili: true), _il('Ankara'), _il('İzmir')]);

    await tester.tap(find.text('Düzenle'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.remove_circle).first); // İstanbul
    await tester.pumpAndSettle();

    expect([for (final s in auth.kaydedilen!) '${s.isim}:${s.secili}'],
        ['Ankara:true', 'İzmir:false']);
  });

  testWidgets('seçili olmayan şehir silinince seçim değişmez', (tester) async {
    final auth = await _ac(
        tester, [_il('İstanbul', secili: true), _il('Ankara'), _il('İzmir')]);

    await tester.tap(find.text('Düzenle'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.remove_circle).at(1)); // Ankara
    await tester.pumpAndSettle();

    expect([for (final s in auth.kaydedilen!) '${s.isim}:${s.secili}'],
        ['İstanbul:true', 'İzmir:false']);
  });

  testWidgets('son kalan şehir silinemez: uyarı çıkar, kayıt değişmez',
      (tester) async {
    final auth = await _ac(tester, [_il('İstanbul', secili: true)]);

    await tester.tap(find.text('Düzenle'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.remove_circle));
    await tester.pump();

    expect(find.text('En az bir şehir kalmalıdır.'), findsOneWidget);
    expect(auth.kaydedilen, isNull);
  });
}
