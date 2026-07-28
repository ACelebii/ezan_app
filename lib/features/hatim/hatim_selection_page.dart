import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'hatim_model.dart';
import 'hatim_provider.dart';
import '../auth/auth_service.dart';

class HatimSelectionPage extends StatelessWidget {
  final String hatimId;
  final String taskTitle;

  const HatimSelectionPage(
      {super.key, required this.hatimId, required this.taskTitle});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HatimProvider>();
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF2F2F7);
    Color cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black;
    Color subTextColor = isDark ? Colors.white70 : Colors.black87;

    final hatim = provider.findHatim(hatimId);
    HatimTask? task;
    if (hatim != null) {
      try {
        task = hatim.tasks.firstWhere((t) => t.title == taskTitle);
      } catch (_) {
        task = null;
      }
    }

    if (hatim == null || task == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text("Görev bulunamadı.",
              style: TextStyle(color: subTextColor)),
        ),
      );
    }

    final resolvedTask = task;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(resolvedTask.title,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "Lütfen seçtiğiniz görevleri yerine getirirken Kuran Okuma Adabı ve Kurallarına uyarak okuyalım.\n"
              "Seçtiğiniz sayfayı program haricinde bir yerden okuyacaksanız, aynı sayfa olmasına dikkat ediniz.",
              style: TextStyle(color: subTextColor, fontSize: 13, height: 1.4),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: resolvedTask.availableItems.length,
              itemBuilder: (context, index) {
                final item = resolvedTask.availableItems[index];
                final isTaken = item.isTaken;

                return InkWell(
                  onTap: () async {
                    // 1. GİRİŞ KONTROLÜ
                    final user = context.read<AuthService>().user;
                    if (user == null) {
                      context.push('/settings/hesabim');
                      return;
                    }

                    // 2. GÖREVİ AL VEYA BIRAK (Aç/Kapat Mantığı) — canlı
                    // dinleme sonucu yansıyacağı için burada yalnızca
                    // Firestore'a yazıyoruz, yerel state'i elle değiştirmiyoruz.
                    try {
                      await provider.toggleItem(
                        hatim,
                        resolvedTask,
                        item,
                        userId: user.uid,
                        userName: user.displayName ?? user.email ?? 'Kullanıcı',
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("İşlem başarısız: $e"),
                            backgroundColor: Colors.redAccent),
                      );
                      return;
                    }

                    // 3. KULLANICIYA GÖRSEL BİLDİRİM VER
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                        .clearSnackBars(); // Üst üste binmesini engeller
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            !isTaken
                                ? "${item.title} ${item.subtitle} Görevlerinize eklendi."
                                : "${item.title} ${item.subtitle} Görevlerinizden çıkarıldı.",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        backgroundColor:
                            !isTaken ? Colors.teal : Colors.redAccent,
                        duration: const Duration(milliseconds: 1000),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: isTaken
                          ? (isDark
                              ? Colors.teal.withValues(alpha: 0.15)
                              : Colors.teal.shade50)
                          : cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isTaken
                            ? Colors.teal
                            : (isDark ? Colors.white10 : Colors.black12),
                        width: isTaken ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // SAĞ ÜST KÖŞEDEKİ YUVARLAK VEYA TİK İŞARETİ
                        Positioned(
                          top: 12,
                          right: 12,
                          child: isTaken
                              ? const Icon(Icons.check_circle_rounded,
                                  color: Colors.teal, size: 24)
                              : Icon(Icons.circle_outlined,
                                  color: subTextColor, size: 20),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(item.title,
                                  style: TextStyle(
                                      color: isTaken ? Colors.teal : textColor,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(item.subtitle,
                                  style: TextStyle(
                                      color: isTaken
                                          ? Colors.teal.withValues(alpha: 0.8)
                                          : subTextColor,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
