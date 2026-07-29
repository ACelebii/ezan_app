import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'kutuphane_model.dart';

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
                      ? const Center(
                          child: Text("Bu kitap için PDF henüz eklenmedi.",
                              style: TextStyle(color: Colors.black)))
                      : Stack(
                          children: [
                            SfPdfViewer.network(
                              widget.item.pdfUrl,
                              canShowScrollHead: false,
                              enableDoubleTapZooming: true,
                              onDocumentLoaded:
                                  (PdfDocumentLoadedDetails details) {
                                setState(() {
                                  _isLoading = false;
                                });
                              },
                              onDocumentLoadFailed:
                                  (PdfDocumentLoadFailedDetails details) {
                                setState(() {
                                  _isLoading = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "PDF yüklenirken hata oluştu! Linki kontrol edin.")));
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
