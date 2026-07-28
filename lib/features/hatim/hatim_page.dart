import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'hatim_provider.dart';
import 'hatim_model.dart';

class HatimPage extends StatelessWidget {
  const HatimPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HatimProvider(),
      child: const HatimView(),
    );
  }
}

class HatimView extends StatelessWidget {
  const HatimView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HatimProvider>();
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF2F2F7);
    Color textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Hatimler",
          style: TextStyle(
              color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              final currentProvider = context.read<HatimProvider>();

              if (!currentProvider.isLoggedIn) {
                context.push('/hatim/auth', extra: currentProvider);
              } else {
                context.push('/hatim/my-tasks', extra: currentProvider);
              }
            },
            child: const Text("Görevlerim",
                style: TextStyle(
                    color: Colors.teal,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Üst Sekmeler (Kuran / Cevşen)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _buildTabCard(
                  context: context,
                  title: "Kuran-ı Kerim",
                  icon: Icons.menu_book_rounded,
                  colors: [const Color(0xFF3F51B5), const Color(0xFF1A237E)],
                  isActive: provider.activeTab == 0,
                  onTap: () => provider.setActiveTab(0),
                ),
                const SizedBox(width: 16),
                _buildTabCard(
                  context: context,
                  title: "Cevşen",
                  icon: Icons.brightness_auto_rounded,
                  colors: [const Color(0xFFFFB74D), const Color(0xFFF57C00)],
                  isActive: provider.activeTab == 1,
                  onTap: () => provider.setActiveTab(1),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 2. Hatim Listesi
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: provider.currentHatimler.length,
              separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: isDark ? Colors.white10 : Colors.black12,
                  indent: 16,
                  endIndent: 16),
              itemBuilder: (context, index) {
                final hatim = provider.currentHatimler[index];
                final isExpanded = provider.expandedHatimId == hatim.id;

                return _buildHatimItem(
                    context, hatim, isExpanded, provider, isDark);
              },
            ),
          ),
        ],
      ),
      // Sağ alt köşedeki + Butonu
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --- Üst Seçim Kartları (Kuran/Cevşen) ---
  Widget _buildTabCard(
      {required BuildContext context,
      required String title,
      required IconData icon,
      required List<Color> colors,
      required bool isActive,
      required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? colors
                  : [Colors.grey.shade800, Colors.grey.shade900],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isActive
                    ? colors.first.withValues(alpha: 0.5)
                    : Colors.transparent,
                width: 2),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: colors.last.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isActive ? Colors.white : Colors.white54, size: 36),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                    color: isActive ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- Hatim Liste Elemanı ---
  Widget _buildHatimItem(BuildContext context, HatimModel hatim,
      bool isExpanded, HatimProvider provider, bool isDark) {
    Color textColor = isDark ? Colors.white : Colors.black;
    Color subTextColor = isDark ? Colors.white54 : Colors.black54;

    return Column(
      children: [
        InkWell(
          onTap: () => provider.toggleExpand(hatim.id),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text("${hatim.id}. Hatim",
                            style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text(hatim.date,
                            style:
                                TextStyle(color: subTextColor, fontSize: 13)),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.people_alt_rounded,
                            color: subTextColor, size: 16),
                        const SizedBox(width: 4),
                        Text("${hatim.participants}",
                            style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_right_rounded,
                            color: subTextColor),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text("Okunma %${hatim.okunmaYuzdesi}",
                        style: const TextStyle(
                            color: Colors.cyan,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Text("Paylaşılma %${hatim.paylasilmaYuzdesi}",
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 4,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Container(
                            color: isDark ? Colors.white10 : Colors.black12),
                        FractionallySizedBox(
                          widthFactor: hatim.paylasilmaYuzdesi / 100,
                          child: Container(color: Colors.redAccent),
                        ),
                        FractionallySizedBox(
                          widthFactor: hatim.okunmaYuzdesi / 100,
                          child: Container(color: Colors.cyan),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Genişleyen Alt Menü
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Container(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: hatim.tasks
                  .map((task) =>
                      _buildTaskItem(context, hatim, task, isDark, textColor))
                  .toList(),
            ),
          ),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  // --- Alt Görev Elemanı ---
  Widget _buildTaskItem(BuildContext context, HatimModel hatim, HatimTask task,
      bool isDark, Color textColor) {
    Color subTextColor = isDark ? Colors.white54 : Colors.black54;

    // YENİ SAYFAYA MEVCUT PROVIDER'I ".value" İLE TAŞIYORUZ
    final provider = context.read<HatimProvider>();

    return InkWell(
      onTap: () {
        if (task.isLocked || task.availableCount == 0) return;

        context.push('/hatim/selection', extra: (provider, hatim, task));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(task.title, style: TextStyle(color: textColor, fontSize: 15)),
            Row(
              children: [
                Text("${task.availableCount}",
                    style: TextStyle(
                        color: task.isLocked ? subTextColor : textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Icon(
                    task.isLocked
                        ? Icons.lock_outline_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    color: subTextColor,
                    size: 18),
              ],
            )
          ],
        ),
      ),
    );
  }
}
