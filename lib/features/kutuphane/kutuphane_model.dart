class LibraryNode {
  final String id;
  final String? parentId;
  final String title;
  final String imageUrl;
  final String pdfUrl;
  final num sira;

  LibraryNode({
    required this.id,
    required this.parentId,
    required this.title,
    required this.imageUrl,
    required this.pdfUrl,
    required this.sira,
  });

  bool get isKitap => pdfUrl.isNotEmpty;

  factory LibraryNode.fromFirestore(String id, Map<String, dynamic> data) {
    return LibraryNode(
      id: id,
      parentId: data['parentId']?.toString(),
      title: data['title']?.toString() ?? 'Başlıksız',
      imageUrl: data['imageUrl']?.toString() ?? '',
      pdfUrl: data['pdfUrl']?.toString() ?? '',
      sira: (data['sira'] as num?) ?? 0,
    );
  }

  Map<String, dynamic> toCache() => {
        'id': id,
        'parentId': parentId,
        'title': title,
        'imageUrl': imageUrl,
        'pdfUrl': pdfUrl,
        'sira': sira,
      };

  factory LibraryNode.fromCache(Map<String, dynamic> data) {
    return LibraryNode(
      id: data['id'].toString(),
      parentId: data['parentId']?.toString(),
      title: data['title']?.toString() ?? 'Başlıksız',
      imageUrl: data['imageUrl']?.toString() ?? '',
      pdfUrl: data['pdfUrl']?.toString() ?? '',
      sira: (data['sira'] as num?) ?? 0,
    );
  }
}
