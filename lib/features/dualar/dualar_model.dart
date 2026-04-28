class DuaCategory {
  final String title;
  final List<DuaItem> items;

  DuaCategory({required this.title, required this.items});

  factory DuaCategory.fromJson(Map<String, dynamic> json) {
    return DuaCategory(
      title: json['category'] ?? '',
      items: (json['items'] as List).map((i) => DuaItem.fromJson(i)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': title,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class DuaItem {
  final String id;
  final String title;
  final String arabic;
  final String pronunciation;
  final String meaning;
  final String reference;

  DuaItem({
    required this.id,
    required this.title,
    required this.arabic,
    required this.pronunciation,
    required this.meaning,
    required this.reference,
  });

  factory DuaItem.fromJson(Map<String, dynamic> json) {
    return DuaItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      arabic: json['arabic'] ?? '',
      pronunciation: json['pronunciation'] ?? '',
      meaning: json['meaning'] ?? '',
      reference: json['reference'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'arabic': arabic,
      'pronunciation': pronunciation,
      'meaning': meaning,
      'reference': reference,
    };
  }
}
