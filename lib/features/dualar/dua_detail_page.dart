import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_button.dart';
import 'dualar_model.dart';

class DuaDetailPage extends StatelessWidget {
  final DuaModel dua;

  const DuaDetailPage({super.key, required this.dua});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDark ? Colors.white : Colors.black87;
    Color bgColor = AppTheme.getBgColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: 16.0, top: 12.0, bottom: 10.0, right: 16.0),
              child: GlassButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => context.pop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dua.baslik,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    if (dua.arapca.isNotEmpty) ...[
                      Text("Arapça Okunuşu",
                          style: TextStyle(
                              color: Colors.teal.shade400,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        dua.arapca,
                        style: TextStyle(
                            color: textColor, fontSize: 24, height: 1.5),
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (dua.okunus.isNotEmpty) ...[
                      Text("Türkçe Okunuşu",
                          style: TextStyle(
                              color: Colors.teal.shade400,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(dua.okunus,
                          style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              height: 1.4,
                              fontStyle: FontStyle.italic)),
                      const SizedBox(height: 24),
                    ],
                    if (dua.anlam.isNotEmpty) ...[
                      Text("Anlamı",
                          style: TextStyle(
                              color: Colors.teal.shade400,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(dua.anlam,
                          style: TextStyle(
                              color: textColor, fontSize: 18, height: 1.4)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
