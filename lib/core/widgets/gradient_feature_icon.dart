import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Menü ve gösterge paneli kısayol ızgaralarında kullanılan, parlak
/// gradyanlı özellik ikonlarının anahtarları. Her anahtar
/// assets/icons/gradient/<key>.svg dosyasına karşılık gelir.
enum GradientFeatureIconKey {
  kuran,
  kutuphane,
  hutbe,
  multimedya,
  diniGunler,
  anaSayfa,
  zikirmatik,
  camiler,
  hatim,
  kazalar,
  ajanda,
  ayarlar,
  imsakiye,
  pusula,
  dualar,
}

extension on GradientFeatureIconKey {
  String get _assetName {
    switch (this) {
      case GradientFeatureIconKey.kuran:
        return 'kuran';
      case GradientFeatureIconKey.kutuphane:
        return 'kutuphane';
      case GradientFeatureIconKey.hutbe:
        return 'hutbe';
      case GradientFeatureIconKey.multimedya:
        return 'multimedya';
      case GradientFeatureIconKey.diniGunler:
        return 'dini_gunler';
      case GradientFeatureIconKey.anaSayfa:
        return 'ana_sayfa';
      case GradientFeatureIconKey.zikirmatik:
        return 'zikirmatik';
      case GradientFeatureIconKey.camiler:
        return 'camiler';
      case GradientFeatureIconKey.hatim:
        return 'hatim';
      case GradientFeatureIconKey.kazalar:
        return 'kazalar';
      case GradientFeatureIconKey.ajanda:
        return 'ajanda';
      case GradientFeatureIconKey.ayarlar:
        return 'ayarlar';
      case GradientFeatureIconKey.imsakiye:
        return 'imsakiye';
      case GradientFeatureIconKey.pusula:
        return 'pusula';
      case GradientFeatureIconKey.dualar:
        return 'dualar';
    }
  }
}

/// Menü/gösterge paneli kısayol ızgaralarındaki tek bir özelliği temsil
/// eden, parlak gradyan zeminli yuvarlak-köşeli ikon karosu.
class GradientFeatureIcon extends StatelessWidget {
  final GradientFeatureIconKey iconKey;
  final double size;

  const GradientFeatureIcon({
    super.key,
    required this.iconKey,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/gradient/${iconKey._assetName}.svg',
      width: size,
      height: size,
    );
  }
}
