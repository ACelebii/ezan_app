import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_button.dart';
import 'providers/dualar_provider.dart';
import 'dualar_model.dart';

class DualarPage extends StatelessWidget {
  const DualarPage({super.key});

  @override
  Widget build(BuildContext context) {
    // RAM dostu, sadece sayfa açıldığında yaşayacak Provider
    return ChangeNotifierProvider(
      create: (_) => DualarProvider(),
      child: const DualarView(),
    );
  }
}

class DualarView extends StatelessWidget {
  const DualarView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DualarProvider>();
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDark ? Colors.white : Colors.black;
    Color bgColor = AppTheme.getBgColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: 16.0, top: 12.0, bottom: 20.0, right: 16.0),
              child: Row(
                children: [
                  GlassButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.pop(), // GoRouter temiz geri dönüş
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "Dualar",
                style: TextStyle(
                    color: textColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildContent(context, provider, isDark, textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DualarProvider provider,
      bool isDark, Color textColor) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(provider.errorMessage!, style: TextStyle(color: textColor)),
          ],
        ),
      );
    }

    if (provider.categories.isEmpty) {
      return const Center(child: Text("Gösterilecek dua bulunamadı."));
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: provider.categories.length,
      itemBuilder: (context, index) {
        final category = provider.categories[index];
        return _buildCategoryCard(context, category, isDark, textColor);
      },
    );
  }

  Widget _buildCategoryCard(BuildContext context, DuaCategory category,
      bool isDark, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 16.0, bottom: 8.0),
            child: Text(
              category.kategori,
              style: TextStyle(
                color: Colors.teal.shade400,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...category.dualar
              .map((dua) => _buildDuaItem(
                  context, dua, isDark, dua == category.dualar.last))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildDuaItem(
      BuildContext context, DuaModel dua, bool isDark, bool isLast) {
    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          title: Text(
            dua.baslik,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87),
          ),
          trailing: Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: isDark ? Colors.white54 : Colors.black54),
          onTap: () {
            // Rota üzerinden data (obje) göndererek geçiş yap
            context.push('/dualar/detail', extra: dua);
          },
        ),
        if (!isLast)
          Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: isDark ? Colors.white10 : Colors.black12),
      ],
    );
  }
}
