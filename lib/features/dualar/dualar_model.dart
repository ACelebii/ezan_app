class DuaItem {
  final String title;
  final String content;
  final String? reference;
  DuaItem({required this.title, required this.content, this.reference});
}

class DuaCategory {
  final String title;
  final List<DuaItem> items;
  DuaCategory({required this.title, required this.items});
}
