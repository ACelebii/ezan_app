import 'package:flutter/material.dart';
import 'dualar_model.dart';
import 'dua_detail_page.dart';

class DualarPage extends StatelessWidget {
  final List<DuaCategory> categories = [
    DuaCategory(title: "Hac ve Umre", items: [
      DuaItem(
          title: "İhramlı kişi nasıl telbiye etmelidir",
          content: "...",
          reference: "Al-Bukhari, Muslim 2/841.")
    ]),
    DuaCategory(
        title: "Sabah-Akşam",
        items: [DuaItem(title: "Uykudan uyanıldığında", content: "...")]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dualar")),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return ExpansionTile(
            title: Text(cat.title),
            children: cat.items
                .map((item) => ListTile(
                      title: Text(item.title),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => DuaDetailPage(dua: item))),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}
