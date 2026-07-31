import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  /// Sabit/dinamik bir arkaplanı olan sayfalar (ör. Pusula'nın her zaman
  /// koyu teması, Kuran'ın kullanıcı seçimine göre değişen arkaplan rengi)
  /// için sistem temasından bağımsız bir ikon rengi verir. Belirtilmezse
  /// açık/koyu sistem temasına göre otomatik seçilir.
  final Color? iconColor;
  final double size;

  const GlassButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
        ),
        child: Icon(
          icon,
          color: iconColor ?? (isDark ? Colors.white : Colors.black87),
          size: size,
        ),
      ),
    );
  }
}
