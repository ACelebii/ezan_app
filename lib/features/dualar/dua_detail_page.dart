import 'package:flutter/material.dart';
import 'dualar_model.dart';

class DuaDetailPage extends StatefulWidget {
  final DuaItem dua;
  const DuaDetailPage({super.key, required this.dua});

  @override
  State<DuaDetailPage> createState() => _DuaDetailPageState();
}

class _DuaDetailPageState extends State<DuaDetailPage> {
  double fontSize = 18.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.dua.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(widget.dua.content, style: TextStyle(fontSize: fontSize)),
            Slider(
                value: fontSize,
                min: 12,
                max: 30,
                onChanged: (v) => setState(() => fontSize = v)),
          ],
        ),
      ),
    );
  }
}
