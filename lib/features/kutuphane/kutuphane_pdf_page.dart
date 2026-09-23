import '../../core/i18n/cevir.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'kutuphane_model.dart';

/// "Son Okunan" kartının okuduğu/yazdığı SharedPreferences anahtarları.
/// Kütüphane ana sayfasındaki kart burada yazılan değerleri okur.
class KutuphaneSonOkunan {
  KutuphaneSonOkunan._();
  static const _idKey = 'kutuphane_son_okunan_id';
  static const _baslikKey = 'kutuphane_son_okunan_baslik';
  static const _gorselKey = 'kutuphane_son_okunan_gorsel';
  static const _pdfKey = 'kutuphane_son_okunan_pdf';
  static const _sayfaKey = 'kutuphane_son_okunan_sayfa';

  static Future<void> save(LibraryNode item, int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_idKey, item.id);
    await prefs.setString(_baslikKey, item.title);
    await prefs.setString(_gorselKey, item.imageUrl);
    await prefs.setString(_pdfKey, item.pdfUrl);
    await prefs.setInt(_sayfaKey, page);
  }

  static Future<({LibraryNode item, int page})?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_idKey);
    if (id == null) return null;
    final item = LibraryNode(
      id: id,
      parentId: null,
      title: prefs.getString(_baslikKey) ?? '',
      imageUrl: prefs.getString(_gorselKey) ?? '',
      pdfUrl: prefs.getString(_pdfKey) ?? '',
      sira: 0,
    );
    return (item: item, page: prefs.getInt(_sayfaKey) ?? 1);
  }

  static Future<int?> pageFor(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_idKey) != itemId) return null;
    return prefs.getInt(_sayfaKey);
  }
}

Widget _buildGlassButton(BuildContext context,
    {required IconData icon, required VoidCallback onTap}) {
  bool isDark = Theme.of(context).brightness == Brightness.dark;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
      ),
      child:
          Icon(icon, color: isDark ? Colors.white : Colors.black87, size: 20),
    ),
  );
}

class KutuphanePdfPage extends StatefulWidget {
  final LibraryNode item;
  const KutuphanePdfPage({super.key, required this.item});

  @override
  State<KutuphanePdfPage> createState() => _KutuphanePdfPageState();
}

class _KutuphanePdfPageState extends State<KutuphanePdfPage> {
  bool _isLoading = true;
  final PdfViewerController _pdfController = PdfViewerController();

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);

    return Scaffold(
      backgroundColor: bgColor,
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
                      onTap: () => context.pop()),
                  Expanded(
                    child: Text(
                      widget.item.title,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5))
                    ]),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  child: widget.item.pdfUrl.isEmpty
                      ? Center(
                          child: Text(
                              context.t("Bu kitap için PDF henüz eklenmedi."),
                              style: const TextStyle(color: Colors.black)))
                      : Stack(
                          children: [
                            SfPdfViewer.network(
                              widget.item.pdfUrl,
                              controller: _pdfController,
                              canShowScrollHead: false,
                              enableDoubleTapZooming: true,
                              onDocumentLoaded:
                                  (PdfDocumentLoadedDetails details) async {
                                setState(() {
                                  _isLoading = false;
                                });
                                final kaldigiSayfa =
                                    await KutuphaneSonOkunan.pageFor(
                                        widget.item.id);
                                if (kaldigiSayfa != null &&
                                    kaldigiSayfa > 1 &&
                                    kaldigiSayfa <=
                                        details.document.pages.count &&
                                    mounted) {
                                  _pdfController.jumpToPage(kaldigiSayfa);
                                }
                              },
                              onDocumentLoadFailed:
                                  (PdfDocumentLoadFailedDetails details) {
                                setState(() {
                                  _isLoading = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(context.t(
                                        "PDF yüklenirken hata oluştu! Linki kontrol edin."))));
                              },
                              onPageChanged: (PdfPageChangedDetails details) {
                                KutuphaneSonOkunan.save(
                                    widget.item, details.newPageNumber);
                              },
                            ),
                            if (_isLoading)
                              Container(
                                color: Colors.white,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.teal),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
