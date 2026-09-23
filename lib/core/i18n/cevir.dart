// lib/core/i18n/cevir.dart

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../features/auth/auth_service.dart';

extension CeviriBaglami on BuildContext {
  /// Dil değişince bu ekranın yeniden çizilmesi için `build` başında çağrılır.
  void dilIzle() {
    try {
      watch<AuthService>();
    } on ProviderNotFoundException {
      // AuthService yok (ör. testte): izlenecek dil de yok.
    }
  }

  /// [metin]i uygulama diline çevirir (Türkçe seçiliyse olduğu gibi döner).
  /// Ekran dil değişince yenilensin diye sayfanın `build`inde bir kez
  /// `context.watch<AuthService>()` çağrılmalıdır. AuthService yoksa (ör. testte)
  /// metin değişmeden döner.
  String t(String metin) {
    try {
      return read<AuthService>().translate(metin);
    } on ProviderNotFoundException {
      return metin;
    }
  }
}
