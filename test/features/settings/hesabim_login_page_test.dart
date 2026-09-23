import 'dart:async';

import 'package:ezan_vakti_uygulamasi/core/i18n/ceviri.dart';
import 'package:ezan_vakti_uygulamasi/features/auth/auth_service.dart';
import 'package:ezan_vakti_uygulamasi/features/settings/hesabim_login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class _SahteKullanici extends Fake implements User {
  @override
  String? get email => 'test@ornek.com';
}

class _SahteAuth extends ChangeNotifier with Fake implements AuthService {
  _SahteAuth({this.girisYapilmis = true, this.ingilizce = false});

  final bool girisYapilmis;
  final bool ingilizce;
  bool _yukleniyor = false;

  /// Testin tamamlayacağı kapı: null ise [deleteAccount] hemen döner.
  Completer<String?>? kapi;

  /// [deleteAccount] hemen dönerse bu sonucu verir.
  String? sonuc;

  int cagriSayisi = 0;

  @override
  User? get user => girisYapilmis ? _SahteKullanici() : null;
  @override
  bool get isLoading => _yukleniyor;
  @override
  String get uygulamaDili => ingilizce ? 'English' : 'Türkçe';
  @override
  String translate(String? text) => Ceviri.cevir(text, uygulamaDili);

  @override
  Future<void> logout() async {}

  @override
  Future<String?> deleteAccount() async {
    cagriSayisi++;
    _yukleniyor = true;
    notifyListeners();
    final r = kapi != null ? await kapi!.future : sonuc;
    _yukleniyor = false;
    notifyListeners();
    return r;
  }
}

Future<_SahteAuth> _ac(WidgetTester t, _SahteAuth auth) async {
  final router = GoRouter(routes: [
    GoRoute(
        path: '/',
        builder: (c, _) => Scaffold(
            body: TextButton(
                onPressed: () => c.push('/hesabim'), child: const Text('ac')))),
    GoRoute(path: '/hesabim', builder: (c, _) => const HesabimLoginPage()),
  ]);
  await t.pumpWidget(ChangeNotifierProvider<AuthService>.value(
      value: auth as AuthService,
      child: MaterialApp.router(routerConfig: router)));
  await t.tap(find.text('ac'));
  await t.pumpAndSettle();
  return auth;
}

void main() {
  testWidgets('giriş yapılmışken "Hesabımı Sil" görünür, onay penceresi açar', (t) async {
    final auth = await _ac(t, _SahteAuth());

    expect(find.text('Hesabımı Sil'), findsOneWidget);

    await t.tap(find.text('Hesabımı Sil'));
    await t.pumpAndSettle();

    expect(find.text('Hesabını silmek istediğine emin misin?'), findsOneWidget);
    expect(
        find.text(
            'Bu işlem geri alınamaz. Hesabın, ayarların ve aldığın hatim görevleri silinir.'),
        findsOneWidget);
    expect(auth.cagriSayisi, 0, reason: 'onay verilmeden silme çağrılmaz');
  });

  testWidgets('Vazgeç: pencere kapanır, hesap silinmez', (t) async {
    final auth = await _ac(t, _SahteAuth());

    await t.tap(find.text('Hesabımı Sil'));
    await t.pumpAndSettle();
    await t.tap(find.text('Vazgeç'));
    await t.pumpAndSettle();

    expect(find.text('Hesabını silmek istediğine emin misin?'), findsNothing);
    expect(auth.cagriSayisi, 0);
    expect(find.text('Hesabımı Sil'), findsOneWidget, reason: 'sayfa kapanmadı');
  });

  testWidgets('onaylayınca silinirken yükleniyor durumu gösterir, düğme kilitlenir', (t) async {
    final auth = await _ac(t, _SahteAuth());
    auth.kapi = Completer<String?>();

    await t.tap(find.text('Hesabımı Sil'));
    await t.pumpAndSettle();
    await t.tap(find.text('Hesabı Sil'));
    await t.pump();

    expect(auth.cagriSayisi, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    auth.kapi!.complete(null);
    await t.pumpAndSettle();
  });

  testWidgets('başarılı silme: başarı mesajı gösterir ve sayfadan çıkar', (t) async {
    final auth = _SahteAuth()..sonuc = null;
    await _ac(t, auth);

    await t.tap(find.text('Hesabımı Sil'));
    await t.pumpAndSettle();
    await t.tap(find.text('Hesabı Sil'));
    await t.pumpAndSettle();

    expect(find.text('Hesabın silindi.'), findsOneWidget);
    expect(find.text('ac'), findsOneWidget, reason: 'önceki sayfaya dönüldü');
  });

  testWidgets('hata: kırmızı ileti gösterir, sayfada kalır (tekrar denenebilir)', (t) async {
    final auth = _SahteAuth()
      ..sonuc = 'Bu işlem için tekrar giriş yapmanız gerekiyor.';
    await _ac(t, auth);

    await t.tap(find.text('Hesabımı Sil'));
    await t.pumpAndSettle();
    await t.tap(find.text('Hesabı Sil'));
    await t.pumpAndSettle();

    expect(find.text('Bu işlem için tekrar giriş yapmanız gerekiyor.'),
        findsOneWidget);
    expect(find.text('Hesabımı Sil'), findsOneWidget, reason: 'sayfada kaldı');
  });

  testWidgets('giriş yapılmamışken "Hesabımı Sil" görünmez', (t) async {
    await _ac(t, _SahteAuth(girisYapilmis: false));

    expect(find.text('Hesabımı Sil'), findsNothing);
  });

  testWidgets('İngilizce arayüzde düğme ve onay penceresi İngilizce', (t) async {
    final auth = _SahteAuth(ingilizce: true)..sonuc = null;
    await _ac(t, auth);

    expect(find.text('Delete My Account'), findsOneWidget);

    await t.tap(find.text('Delete My Account'));
    await t.pumpAndSettle();

    expect(find.text('Are you sure you want to delete your account?'),
        findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await t.tap(find.text('Delete Account'));
    await t.pumpAndSettle();

    expect(find.text('Your account has been deleted.'), findsOneWidget);
  });
}
