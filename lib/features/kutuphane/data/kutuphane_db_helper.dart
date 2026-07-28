import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class KutuphaneDbHelper {
  static final KutuphaneDbHelper instance = KutuphaneDbHelper._init();
  static Database? _database;

  KutuphaneDbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kutuphane.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, filePath);

    // Veritabanı daha önce kopyalanmışsa tekrar kopyalamaya gerek yok.
    if (!await File(path).exists()) {
      try {
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load(join("assets/db", filePath));
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        throw Exception("Veritabanı kopyalanamadı: $e");
      }
    }

    return await openDatabase(path);
  }
}
