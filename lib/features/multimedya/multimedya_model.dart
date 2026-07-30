enum MultimediaType { video, ayet, hadis, wallpaper }

MultimediaType _typeFromString(String value) {
  return MultimediaType.values.firstWhere(
    (t) => t.name == value,
    orElse: () => MultimediaType.video,
  );
}

class MultimediaItem {
  final String id;
  final MultimediaType type;
  final String category;
  final String title;
  final String subtitle;
  final String text;
  final String imageUrl;
  final String contentUrl;
  final String channelIconUrl;
  final num sira;

  MultimediaItem({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.text,
    required this.imageUrl,
    required this.contentUrl,
    required this.channelIconUrl,
    required this.sira,
  });

  // YouTube video linkinden video ID'sini çıkarır (watch?v=, youtu.be/, shorts/ biçimleri).
  String? get _youtubeId {
    final uri = Uri.tryParse(contentUrl);
    if (uri == null) return null;
    if (uri.queryParameters.containsKey('v')) return uri.queryParameters['v'];
    final segments = uri.pathSegments;
    if (segments.isEmpty) return null;
    if (uri.host.contains('youtu.be')) return segments.first;
    final marker = segments.indexOf('shorts');
    if (marker != -1 && marker + 1 < segments.length) {
      return segments[marker + 1];
    }
    return null;
  }

  // imageUrl boşsa YouTube ID'sinden thumbnail türetir (savunma amaçlı, veri girişinde
  // imageUrl her zaman doldurulmalı).
  String get displayThumbnail {
    if (imageUrl.isNotEmpty) return imageUrl;
    final id = _youtubeId;
    if (id == null) return '';
    return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }

  String get fullImageUrl => contentUrl.isNotEmpty ? contentUrl : imageUrl;

  factory MultimediaItem.fromFirestore(String id, Map<String, dynamic> data) {
    return MultimediaItem(
      id: id,
      type: _typeFromString(data['type']?.toString() ?? 'video'),
      category: data['category']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      subtitle: data['subtitle']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      contentUrl: data['contentUrl']?.toString() ?? '',
      channelIconUrl: data['channelIconUrl']?.toString() ?? '',
      sira: (data['sira'] as num?) ?? 0,
    );
  }

  Map<String, dynamic> toCache() => {
        'id': id,
        'type': type.name,
        'category': category,
        'title': title,
        'subtitle': subtitle,
        'text': text,
        'imageUrl': imageUrl,
        'contentUrl': contentUrl,
        'channelIconUrl': channelIconUrl,
        'sira': sira,
      };

  factory MultimediaItem.fromCache(Map<String, dynamic> data) {
    return MultimediaItem(
      id: data['id'].toString(),
      type: _typeFromString(data['type']?.toString() ?? 'video'),
      category: data['category']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      subtitle: data['subtitle']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      contentUrl: data['contentUrl']?.toString() ?? '',
      channelIconUrl: data['channelIconUrl']?.toString() ?? '',
      sira: (data['sira'] as num?) ?? 0,
    );
  }
}
