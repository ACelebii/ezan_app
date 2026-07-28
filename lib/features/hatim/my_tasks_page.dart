import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // EKLENDİ
import 'hatim_provider.dart';
import 'hatim_model.dart';
// Senin mevcut Kuran modülü importların
import '../kuran/providers/kuran_provider.dart';
import '../kuran/kuran_models.dart';

class MyTasksPage extends StatelessWidget {
  const MyTasksPage({super.key});

  // --- OKUDUM ONAY POP-UP (Fotoğraf 5) ---
  void _showCompleteDialog(
      BuildContext context, HatimProvider provider, MyTask task) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "İlgili görevi\nokuduğunuzu\nonaylıyormusunuz?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 24),
              Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
              InkWell(
                onTap: () {
                  provider.completeTask(task); // Görevi tamamla ve sil
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: const Text("EVET",
                      style: TextStyle(
                          color: Color(0xFFFF3B30),
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- VAZGEÇ ONAY POP-UP (Fotoğraf 2) ---
  void _showDropDialog(
      BuildContext context, HatimProvider provider, MyTask task) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Onaylıyormusunuz?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 24),
              Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
              InkWell(
                onTap: () {
                  provider.dropTask(task); // Görevi havuza geri at ve sil
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: const Text("EVET",
                      style: TextStyle(
                          color: Color(0xFFFF3B30),
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HatimProvider>();
    const Color bgColor = Colors.black;
    const Color textColor = Colors.white;
    const Color subTextColor = Colors.white54;

    // Görevleri Hatim ID'sine göre grupla
    Map<String, List<MyTask>> groupedTasks = {};
    for (var task in provider.myTasks) {
      groupedTasks.putIfAbsent(task.hatim.id, () => []).add(task);
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                color: Colors.white10, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: textColor, size: 16),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text("Görevlerim",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SON KALDIĞIM YER PANELİ ---
            if (provider.lastReadTask != null) ...[
              const Padding(
                padding: EdgeInsets.only(left: 16.0, top: 16, bottom: 8),
                child: Text("Son Kaldığım Yer",
                    style: TextStyle(color: subTextColor, fontSize: 12)),
              ),
              ListTile(
                title: Text("${provider.lastReadTask!.hatim.id}. Hatim",
                    style: const TextStyle(
                        color: textColor, fontWeight: FontWeight.bold)),
                subtitle: Text(
                    "${provider.lastReadTask!.item.title} ${provider.lastReadTask!.item.subtitle}",
                    style: const TextStyle(color: subTextColor)),
                trailing: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("8 May 12:56",
                        style: TextStyle(color: subTextColor, fontSize: 12)),
                    SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: subTextColor),
                  ],
                ),
                onTap: () {
                  // Son okunan yere hızlı git (Aşağıdaki yönlendirme ile aynı mantık eklenebilir)
                },
              ),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 16),
            ],

            // --- GRUPLANMIŞ GÖREVLER LİSTESİ ---
            ...groupedTasks.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12),
                    child: Text("${entry.key}. Hatim",
                        style:
                            const TextStyle(color: subTextColor, fontSize: 14)),
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  ...entry.value.map((myTask) {
                    return Slidable(
                      key: ValueKey(myTask.item.id),
                      // SAĞDAN SOLA KAYDIRMA BUTONLARI (Fotoğraf 1)
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.5, // Ekranda kaplayacağı alan oranı
                        children: [
                          // OKUDUM BUTONU
                          CustomSlidableAction(
                            onPressed: (context) =>
                                _showCompleteDialog(context, provider, myTask),
                            backgroundColor: Colors.transparent,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30), // Kırmızı
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8),
                              alignment: Alignment.center,
                              child: const Text("Okudum",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ),
                          // VAZGEÇ BUTONU
                          CustomSlidableAction(
                            onPressed: (context) =>
                                _showDropDialog(context, provider, myTask),
                            backgroundColor: Colors.transparent,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A84FF), // Mavi
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8),
                              alignment: Alignment.center,
                              child: const Text("Vazgeç",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ],
                      ),
                      // LİSTE ELEMANININ GÖRÜNÜMÜ
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: const Icon(Icons.circle_outlined,
                                color: Colors.white54, size: 22),
                            title: Text(
                                "${myTask.item.title} ${myTask.item.subtitle}",
                                style: const TextStyle(
                                    color: textColor, fontSize: 16)),
                            subtitle: Text("Kalan Süre ${myTask.timeLeft}",
                                style: const TextStyle(
                                    color: subTextColor, fontSize: 12)),
                            trailing: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white),
                                child: const Icon(Icons.arrow_forward,
                                    color: Colors.black, size: 14),
                              ),
                              onPressed: () {
                                // 1. Son kalınan yer kaydet
                                provider.setLastReadTask(myTask);

                                // 2. Kuran sayfasına yönlendir (Mevcut entegrasyon)
                                if (myTask.taskType.title == "Sayfa" ||
                                    myTask.taskType.title == "Cüz" ||
                                    myTask.taskType.title == "Sure") {
                                  final kuranProvider = KuranProvider();
                                  if (myTask.taskType.title == "Sayfa") {
                                    kuranProvider
                                        .loadPageDetails(myTask.item.value);
                                  } else if (myTask.taskType.title == "Cüz") {
                                    kuranProvider
                                        .loadJuzDetails(myTask.item.value);
                                  } else if (myTask.taskType.title == "Sure") {
                                    kuranProvider.loadSurahDetails(SurahModel(
                                        id: myTask.item.value,
                                        nameSimple: myTask.item.title,
                                        nameArabic: "",
                                        versesCount: 0));
                                  }

                                  context.push('/kuran/surah-detail',
                                      extra: kuranProvider);
                                }
                              },
                            ),
                          ),
                          const Divider(
                              color: Colors.white10, height: 1, indent: 48),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              );
            }),

            if (provider.myTasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text("Henüz alınmış bir göreviniz bulunmuyor.",
                      style: TextStyle(color: subTextColor)),
                ),
              )
          ],
        ),
      ),
    );
  }
}
