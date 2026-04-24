class LibraryNode {
  final String title;
  final String imagePath; // UI'daki o gerçek görseller için
  final String? content; // Sadece en son makale aşamasında dolu olur
  final List<LibraryNode>? children; // Alt kategoriler varsa dolu olur

  LibraryNode({
    required this.title,
    required this.imagePath,
    this.content,
    this.children,
  });

  // Bu düğüm bir makale mi yoksa alt kategorisi olan bir liste mi?
  bool get isArticle => content != null;
}
