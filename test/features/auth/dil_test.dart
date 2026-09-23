import 'package:ezan_vakti_uygulamasi/features/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('yalnızca çevirisi olan diller seçilebilir: Türkçe ve English', () {
    expect(desteklenenDiller, ['Türkçe', 'English']);
  });

  test('desteklenen dil olduğu gibi döner', () {
    expect(gecerliDil('Türkçe'), 'Türkçe');
    expect(gecerliDil('English'), 'English');
  });

  test('eskiden seçilmiş çevirisiz dil, boş ya da bozuk kayıt Türkçe olur', () {
    for (final kayit in [
      'العربية',
      'Deutsch',
      'Français',
      '',
      'english',
      42,
      null
    ]) {
      expect(gecerliDil(kayit), 'Türkçe', reason: '$kayit');
    }
  });
}
