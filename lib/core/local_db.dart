import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_data.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path,
        version: 2, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE library_items ADD COLUMN type TEXT');
      await db.execute('ALTER TABLE kuran_pages ADD COLUMN cüz INTEGER');
      await db.execute('ALTER TABLE kuran_pages ADD COLUMN sure_name TEXT');
    }
  }

  Future _createDB(Database db, int version) async {
    // Kütüphane ve diğer yapısal veriler için tablolar
    await db.execute('''
      CREATE TABLE library_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        image_path TEXT,
        content TEXT,
        parent_id INTEGER,
        type TEXT
      )
    ''');

    // Kuran sayfa meta verileri
    await db.execute('''
      CREATE TABLE kuran_pages (
        page_number INTEGER PRIMARY KEY,
        local_path TEXT,
        is_downloaded INTEGER DEFAULT 0,
        cüz INTEGER,
        sure_name TEXT
      )
    ''');

    // Sayfaları önceden oluştur
    for (int i = 1; i <= 604; i++) {
      await db.insert('kuran_pages', {'page_number': i});
    }
  }
}
