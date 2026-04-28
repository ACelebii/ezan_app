import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';

// ============================================================================
// ORTAK BUTON TASARIMI (Glassmorphism / Şeffaf Kutu)
// ============================================================================
Widget _buildGlassButton(BuildContext context,
    {IconData? icon, String? text, required VoidCallback onTap}) {
  bool isDark = Theme.of(context).brightness == Brightness.dark;
  Color textColor = isDark ? Colors.white : Colors.black87;

  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: EdgeInsets.symmetric(
          horizontal: text != null ? 16 : 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, color: textColor, size: 18),
          if (icon != null && text != null) const SizedBox(width: 6),
          if (text != null)
            Text(text,
                style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}

// ============================================================================
// 1. ZİKİR LİSTESİ (ANA GİRİŞ SAYFASI)
// ============================================================================
class ZikirmatikPage extends StatefulWidget {
  const ZikirmatikPage({super.key});

  @override
  State<ZikirmatikPage> createState() => _ZikirmatikPageState();
}

class _ZikirmatikPageState extends State<ZikirmatikPage> {
  bool isEditing = false;
  String? _showingDeleteFor;

  final List<Map<String, dynamic>> _aktifZikirler = [
    {
      "ad": "Zikirmatik",
      "sayi": 5,
      "hedef": 99,
      "imame": 33,
      "isDefault": true
    },
  ];

  final List<Map<String, dynamic>> _hazirZikirler = [
    {
      "ad": "100 Sübhânellâhi",
      "sayi": 0,
      "hedef": 100,
      "imame": 100,
      "arapca": "سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ سُبْحَانَ اللّٰهِ الْعَظِيمِ",
      "okunusu": "Sübhânellâhi ve bi hamdihî sübhânellâhil azîm",
      "anlami": "Allah'ü Teala'yı tesbih ederim, hamd O'na mahsustur.",
      "isDefault": false
    },
    {
      "ad": "99 Lâ havle",
      "sayi": 0,
      "hedef": 99,
      "imame": 99,
      "arapca":
          "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ الْعَلِيِّ الْعَظِيمِ",
      "okunusu": "Lâ havle ve lâ kuvvete illâ billâhil aliyyil azîm",
      "anlami": "Bütün kudret ve kuvvet, Aliyy ve Azîm olan Allah'a aittir.",
      "isDefault": false
    },
    {
      "ad": "Salavat",
      "sayi": 0,
      "hedef": 100,
      "imame": 25,
      "arapca":
          "اَللّٰهُمَّ صَلِّ عَلٰى سَيِّدِنَا مُحَمَّدٍ وَعَلٰى اٰلِ سَيِّدِنَا مُحَمَّدٍ",
      "okunusu":
          "Allahümme Salli Ala Seyyidina Muhammedin ve Ala Ali Seyyidina Muhammed",
      "anlami": "Allah'ım, efendimiz Hz. Muhammed'e ve aline salat eyle.",
      "isDefault": false
    },
  ];

  void _showAddPopup(BuildContext context,
      {Map<String, dynamic>? initialData}) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ZikirEkleDuzenlePage(initialData: initialData),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        if (initialData != null) {
          int index = _aktifZikirler.indexOf(initialData);
          if (index != -1) {
            result['sayi'] = initialData['sayi'];
            _aktifZikirler[index] = result;
          }
        } else {
          _aktifZikirler.add(result);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = context.watch<AuthService>();
    Color cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGlassButton(context,
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context)),
                  Row(
                    children: [
                      _buildGlassButton(context,
                          icon: Icons.add, onTap: () => _showAddPopup(context)),
                      const SizedBox(width: 8),
                      _buildGlassButton(context,
                          text: isEditing
                              ? authService.translate("Bitti")
                              : authService.translate("Düzenle"), onTap: () {
                        setState(() {
                          isEditing = !isEditing;
                          _showingDeleteFor = null;
                        });
                      }),
                    ],
                  )
                ],
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4))
                              ]),
                    child: Column(
                      children: _aktifZikirler.asMap().entries.map((entry) {
                        int index = entry.key;
                        var z = entry.value;
                        bool isLast = index == _aktifZikirler.length - 1;
                        bool isDefault = z['isDefault'] == true;
                        bool showDelete = _showingDeleteFor == z['ad'];

                        Widget tile = ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: isDefault
                              ? Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.touch_app_rounded,
                                      color: Colors.blue, size: 20),
                                )
                              : (isEditing
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () => setState(() =>
                                              _showingDeleteFor =
                                                  showDelete ? null : z['ad']),
                                          child: const Icon(Icons.remove_circle,
                                              color: Colors.redAccent,
                                              size: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(Icons.radio_button_unchecked,
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.black26,
                                            size: 22),
                                      ],
                                    )
                                  : Icon(Icons.radio_button_unchecked,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black26,
                                      size: 22)),
                          title: Text(authService.translate(z['ad']),
                              style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16)),
                          trailing: isEditing
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isDefault)
                                      Icon(Icons.edit,
                                          size: 18,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54),
                                    if (isDefault)
                                      Text("${z['sayi']}/${z['hedef']}",
                                          style: TextStyle(
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.black54,
                                              fontSize: 14)),
                                    const SizedBox(width: 10),
                                    Icon(Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black26),
                                    const SizedBox(width: 12),
                                    Icon(Icons.menu,
                                        size: 20,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black26),
                                    if (showDelete && !isDefault) ...[
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _aktifZikirler.remove(z);
                                            _hazirZikirler.add(z);
                                            _showingDeleteFor = null;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                              color: Colors.redAccent,
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.delete_outline,
                                                  color: Colors.white,
                                                  size: 16),
                                              SizedBox(width: 4),
                                              Text("Sil",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      )
                                    ]
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("${z['sayi']}/${z['hedef']}",
                                        style: TextStyle(
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black54,
                                            fontSize: 14)),
                                    const SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black26),
                                  ],
                                ),
                          onTap: () async {
                            if (isEditing) {
                              if (!isDefault)
                                _showAddPopup(context, initialData: z);
                            } else {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ZikirmatikSayacPage(zikirData: z)));
                              setState(() {});
                            }
                          },
                        );

                        return Column(
                          children: [
                            isEditing
                                ? tile
                                : Dismissible(
                                    key: Key(z['ad']),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(
                                                  index == 0 ? 16 : 0),
                                              bottom: Radius.circular(
                                                  isLast ? 16 : 0))),
                                      child: const Icon(Icons.delete,
                                          color: Colors.white),
                                    ),
                                    onDismissed: (direction) {
                                      if (!isDefault) {
                                        setState(() {
                                          _aktifZikirler.remove(z);
                                          _hazirZikirler.add(z);
                                        });
                                      }
                                    },
                                    child: tile,
                                  ),
                            if (!isLast)
                              Divider(
                                  color:
                                      isDark ? Colors.white10 : Colors.black12,
                                  height: 1,
                                  indent: 50),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  if (_hazirZikirler.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4))
                                ]),
                      child: Column(
                        children: _hazirZikirler.asMap().entries.map((entry) {
                          int index = entry.key;
                          var z = entry.value;
                          bool isLast = index == _hazirZikirler.length - 1;

                          return Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                leading: Icon(Icons.add_circle_outline,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                    size: 24),
                                title: Text(z['ad'],
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500)),
                                onTap: () {
                                  setState(() {
                                    _aktifZikirler.add(z);
                                    _hazirZikirler.remove(z);
                                  });
                                },
                              ),
                              if (!isLast)
                                Divider(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black12,
                                    height: 1,
                                    indent: 50),
                            ],
                          );
                        }).toList(),
                      ),
                    )
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. ZİKİR SAYACI (TESBİH RENKLERİ EKLENDİ)
// ============================================================================
class ZikirmatikSayacPage extends StatefulWidget {
  final Map<String, dynamic> zikirData;
  const ZikirmatikSayacPage({super.key, required this.zikirData});

  @override
  State<ZikirmatikSayacPage> createState() => _ZikirmatikSayacPageState();
}

class _ZikirmatikSayacPageState extends State<ZikirmatikSayacPage> {
  late int _count;
  late int _target;
  int _loop = 0;

  bool _isTapped = false;
  double _scale = 1.0;
  int _currentView = 1;

  // --- TESBİH RENK PALETLERİ ---
  int _selectedBeadColorIndex = 3; // Varsayılan Kırmızı (index 3)
  final List<List<Color>> _beadColorPalettes = [
    [Colors.white, const Color(0xFFFDE6C5), const Color(0xFFD4A373)], // Krem
    [
      const Color(0xFFE2B48A),
      const Color(0xFFB57041),
      const Color(0xFF5C3317)
    ], // Ahşap / Kahverengi
    [Colors.white, const Color(0xFFA0A0A0), const Color(0xFF404040)], // Gri
    [
      Colors.white.withOpacity(0.9),
      Colors.redAccent.shade200,
      Colors.red.shade900
    ], // Kırmızı (Varsayılan)
    [
      const Color(0xFFC0E8C0),
      const Color(0xFF5AB95A),
      const Color(0xFF1B5E20)
    ], // Yeşil
  ];

  @override
  void initState() {
    super.initState();
    _count = widget.zikirData['sayi'];
    _target = widget.zikirData['hedef'];
  }

  void _increment() {
    Feedback.forTap(context);
    setState(() {
      _count++;
      if (_count >= _target) {
        _loop++;
        _count = 0;
      }
      widget.zikirData['sayi'] = _count;
    });
  }

  void _reset() {
    setState(() {
      _count = 0;
      _loop = 0;
      widget.zikirData['sayi'] = 0;
    });
  }

  // --- RENK SEÇİCİ POPUP EKRANI ---
  void _showBeadColorPicker() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          bool isDark = Theme.of(context).brightness == Brightness.dark;
          return StatefulBuilder(builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.only(
                  bottom: 40, top: 10, left: 20, right: 20),
              decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black26,
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_beadColorPalettes.length, (index) {
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            _selectedBeadColorIndex = index;
                          });
                          this.setState(
                              () {}); // Arkadaki ana sayfayı da yenile
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: const Alignment(-0.3, -0.3),
                              radius: 0.8,
                              colors: _beadColorPalettes[index],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                            border: _selectedBeadColorIndex == index
                                ? Border.all(
                                    color: Colors.blue.withOpacity(0.8),
                                    width: 3)
                                : Border.all(
                                    color: Colors.transparent, width: 3),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3))
                            ],
                          ),
                        ),
                      );
                    }),
                  )
                ],
              ),
            );
          });
        });
  }

  Widget _buildCountTexts(bool isDark, {bool alignLeft = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text("$_count",
                style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.w300,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.0)),
            Text("/$_target",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: isDark ? Colors.white54 : Colors.black45)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.autorenew_rounded,
                size: 16, color: isDark ? Colors.white54 : Colors.black45),
            const SizedBox(width: 4),
            Text("$_loop",
                style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white54 : Colors.black45)),
          ],
        ),
      ],
    );
  }

  // --- RENGE GÖRE TESBİH OLUŞTURUCU ---
  List<Widget> _buildBeadSequence(bool isDark) {
    List<double> sizes = [15, 25, 40, 60, 80, 60, 40, 25, 15];
    List<Widget> children = [];
    List<Color> currentPalette = _beadColorPalettes[_selectedBeadColorIndex];
    Color separatorColor = currentPalette[1]
        .withOpacity(0.6); // Ara noktalar için paletin orta rengi

    for (int i = 0; i < sizes.length; i++) {
      children.add(Container(
        width: sizes[i],
        height: sizes[i],
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 0.8,
            colors: currentPalette,
            stops: const [0.0, 0.4, 1.0],
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(2, 4))
          ],
        ),
      ));
      if (i != sizes.length - 1) {
        children.add(Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.all(6),
          decoration:
              BoxDecoration(color: separatorColor, shape: BoxShape.circle),
        ));
      }
    }
    return children;
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color topIconColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF312E81)]
                : [const Color(0xFFE0F2FE), const Color(0xFFC4B5FD)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGlassButton(context,
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context)),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isDark ? Colors.white24 : Colors.black12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {},
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(20)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Icon(Icons.g_translate_rounded,
                                  color: topIconColor, size: 18),
                            ),
                          ),
                          Container(
                              width: 1,
                              height: 16,
                              color: isDark ? Colors.white24 : Colors.black12),
                          Theme(
                            data: Theme.of(context).copyWith(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent),
                            child: PopupMenuButton<String>(
                              icon: Icon(Icons.menu_rounded,
                                  color: topIconColor, size: 20),
                              offset: const Offset(0, 40),
                              color: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              onSelected: (value) {
                                if (value == 'v1') {
                                  setState(() => _currentView = 1);
                                }
                                if (value == 'v2') {
                                  setState(() => _currentView = 2);
                                }
                                if (value == 'v3') {
                                  setState(() => _currentView = 3);
                                }
                                if (value == 'tesbih') {
                                  _showBeadColorPicker(); // Tesbih Renk Seçici
                                }
                                if (value == 'reset') {
                                  _reset();
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                    value: 'v1',
                                    child: Row(children: [
                                      if (_currentView == 1)
                                        const Icon(Icons.check,
                                            size: 18, color: Colors.blue)
                                      else
                                        const SizedBox(width: 18),
                                      const SizedBox(width: 12),
                                      const Text('Görünüm 1')
                                    ])),
                                PopupMenuItem(
                                    value: 'v2',
                                    child: Row(children: [
                                      if (_currentView == 2)
                                        const Icon(Icons.check,
                                            size: 18, color: Colors.blue)
                                      else
                                        const SizedBox(width: 18),
                                      const SizedBox(width: 12),
                                      const Text('Görünüm 2')
                                    ])),
                                PopupMenuItem(
                                    value: 'v3',
                                    child: Row(children: [
                                      if (_currentView == 3)
                                        const Icon(Icons.check,
                                            size: 18, color: Colors.blue)
                                      else
                                        const SizedBox(width: 18),
                                      const SizedBox(width: 12),
                                      const Text('Görünüm 3')
                                    ])),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                    value: 'tesbih',
                                    child: Row(children: [
                                      SizedBox(width: 30),
                                      Text('Tesbih')
                                    ])),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                    value: 'reset',
                                    child: Row(children: [
                                      SizedBox(width: 18),
                                      SizedBox(width: 12),
                                      Icon(Icons.refresh, size: 18),
                                      SizedBox(width: 12),
                                      Text('Sıfırla')
                                    ])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _currentView == 1
                    ? Center(
                        child: AnimatedScale(
                          scale: _scale,
                          duration: const Duration(milliseconds: 100),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width: 320,
                            height: 320,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: _isTapped
                                    ? [
                                        BoxShadow(
                                            color: Colors.redAccent
                                                .withOpacity(0.6),
                                            blurRadius: 50,
                                            spreadRadius: 15)
                                      ]
                                    : []),
                            child: ClipOval(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapDown: (_) => setState(() {
                                  _isTapped = true;
                                  _scale = 0.95;
                                }),
                                onTapUp: (_) {
                                  setState(() {
                                    _isTapped = false;
                                    _scale = 1.0;
                                  });
                                  _increment();
                                },
                                onTapCancel: () => setState(() {
                                  _isTapped = false;
                                  _scale = 1.0;
                                }),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CustomPaint(
                                        size: const Size(320, 320),
                                        painter: ZikirRingPainter(
                                            progress: _count / _target,
                                            isDark: isDark)),
                                    _buildCountTexts(isDark, alignLeft: false),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => setState(() => _isTapped = true),
                        onTapUp: (_) {
                          setState(() => _isTapped = false);
                          _increment();
                        },
                        onTapCancel: () => setState(() => _isTapped = false),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 30,
                              top: 40,
                              child: _buildCountTexts(isDark, alignLeft: true),
                            ),
                            if (_currentView == 2)
                              Positioned(
                                  right: 16,
                                  top: 20,
                                  bottom: 20,
                                  child: Center(
                                      child: AnimatedSlide(
                                          offset: _isTapped
                                              ? const Offset(0, 0.05)
                                              : Offset.zero,
                                          duration:
                                              const Duration(milliseconds: 100),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children:
                                                    _buildBeadSequence(isDark)),
                                          )))),
                            if (_currentView == 3)
                              Positioned(
                                  left: 16,
                                  right: 16,
                                  bottom: 60,
                                  child: Center(
                                      child: AnimatedSlide(
                                          offset: _isTapped
                                              ? const Offset(0.05, 0)
                                              : Offset.zero,
                                          duration:
                                              const Duration(milliseconds: 100),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children:
                                                    _buildBeadSequence(isDark)),
                                          )))),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ZikirRingPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  ZikirRingPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final dotPaint = Paint()
      ..color = isDark ? Colors.white24 : Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 72; i++) {
      final angle = (i * 5) * pi / 180;
      canvas.drawCircle(
          Offset(center.dx + (radius) * cos(angle),
              center.dy + (radius) * sin(angle)),
          1.5,
          dotPaint);
    }

    final bgPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.blue.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 20),
        -pi / 2, 2 * pi, false, bgPaint);

    final progressPaint = Paint()
      ..color = Colors.redAccent.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 20),
        -pi / 2, 2 * pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ============================================================================
// 3. ZİKİR EKLE / DÜZENLE SAYFASI
// ============================================================================
class ZikirEkleDuzenlePage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const ZikirEkleDuzenlePage({super.key, this.initialData});

  @override
  State<ZikirEkleDuzenlePage> createState() => _ZikirEkleDuzenlePageState();
}

class _ZikirEkleDuzenlePageState extends State<ZikirEkleDuzenlePage> {
  late TextEditingController adController;
  late TextEditingController adetController;
  late TextEditingController imameController;
  late TextEditingController arapcaController;
  late TextEditingController okunusuController;
  late TextEditingController anlamiController;

  @override
  void initState() {
    super.initState();
    adController = TextEditingController(text: widget.initialData?['ad'] ?? "");
    adetController = TextEditingController(
        text: widget.initialData?['hedef']?.toString() ?? "99");
    imameController = TextEditingController(
        text: widget.initialData?['imame']?.toString() ?? "33");
    arapcaController =
        TextEditingController(text: widget.initialData?['arapca'] ?? "");
    okunusuController =
        TextEditingController(text: widget.initialData?['okunusu'] ?? "");
    anlamiController =
        TextEditingController(text: widget.initialData?['anlami'] ?? "");
  }

  @override
  void dispose() {
    adController.dispose();
    adetController.dispose();
    imameController.dispose();
    arapcaController.dispose();
    okunusuController.dispose();
    anlamiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color fieldBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black;

    return SafeArea(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 10),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(10)),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGlassButton(context,
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context)),
                Text(
                    widget.initialData != null ? "Zikri Düzenle" : "Zikir Ekle",
                    style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                _buildGlassButton(context, text: "Kaydet", onTap: () {
                  final yeniZikir = {
                    "ad": adController.text,
                    "sayi": 0,
                    "hedef": int.tryParse(adetController.text) ?? 99,
                    "imame": int.tryParse(imameController.text) ?? 33,
                    "arapca": arapcaController.text,
                    "okunusu": okunusuController.text,
                    "anlami": anlamiController.text,
                    "isDefault": false
                  };
                  Navigator.pop(context, yeniZikir);
                }),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _buildInputLabel("Zikir Adı", isDark),
                _buildTextField(
                    adController, "Örn: Sübhânellâhi", fieldBg, textColor),
                _buildInputLabel("Adet", isDark),
                _buildTextField(adetController, "99", fieldBg, textColor,
                    isNumber: true),
                _buildInputLabel("İmame", isDark),
                _buildTextField(imameController, "33", fieldBg, textColor,
                    isNumber: true),
                _buildInputLabel("Arapça", isDark),
                _buildTextField(
                    arapcaController, "Arapça metin...", fieldBg, textColor),
                _buildInputLabel("Okunuşu", isDark),
                _buildTextField(
                    okunusuController, "Okunuşu...", fieldBg, textColor),
                _buildInputLabel("Anlamı", isDark),
                _buildTextField(
                    anlamiController, "Anlamı...", fieldBg, textColor),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6, top: 16),
      child: Text(text,
          style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, Color bg, Color textC,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: textC),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: textC.withOpacity(0.3)),
        filled: true,
        fillColor: bg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}


