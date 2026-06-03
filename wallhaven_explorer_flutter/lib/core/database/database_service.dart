// // AkonDeV 06/2026

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import '../../models/wallpaper.dart';

class DatabaseService {
  final String? _customPath;
  late final Database _db;

  DatabaseService({String? customPath}) : _customPath = customPath;

  Future<void> initializeDatabase() async {
    // // AkonDeV 06/2026
    String dbPath;
    if (_customPath != null) {
      dbPath = _customPath!;
    } else {
      final appDir = await getApplicationSupportDirectory();
      dbPath = p.join(appDir.path, 'localdata.db');
    }

    final file = File(dbPath);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    _db = sqlite3.open(dbPath);

    _db.execute('''
      CREATE TABLE IF NOT EXISTS Favorites (
        Id TEXT PRIMARY KEY,
        Url TEXT NOT NULL,
        Path TEXT,
        Resolution TEXT,
        Category TEXT,
        Tags TEXT,
        Uploader TEXT,
        ShortUrl TEXT,
        SavedAt TEXT NOT NULL
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS SearchHistory (
        Id INTEGER PRIMARY KEY AUTOINCREMENT,
        QueryText TEXT NOT NULL,
        FilterJson TEXT,
        Timestamp TEXT NOT NULL
      );
    ''');
  }

  Future<void> saveFavorite(Wallpaper wp) async {
    // // AkonDeV 06/2026
    final stmt = _db.prepare('''
      INSERT OR REPLACE INTO Favorites (Id, Url, Path, Resolution, Category, Tags, Uploader, ShortUrl, SavedAt)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''');
    
    stmt.execute([
      wp.id,
      wp.url,
      wp.path,
      wp.resolution,
      wp.category,
      wp.tags.join(','),
      wp.uploader,
      wp.shortUrl,
      DateTime.now().toUtc().toIso8601String(),
    ]);
    stmt.dispose();
  }

  Future<void> removeFavorite(String id) async {
    // // AkonDeV 06/2026
    final stmt = _db.prepare('DELETE FROM Favorites WHERE Id = ?;');
    stmt.execute([id]);
    stmt.dispose();
  }

  Future<List<Wallpaper>> getFavorites() async {
    // // AkonDeV 06/2026
    final ResultSet results = _db.select('SELECT Id, Url, Path, Resolution, Category, Tags, Uploader, ShortUrl FROM Favorites ORDER BY SavedAt DESC;');
    final list = <Wallpaper>[];
    for (final row in results) {
      final tagsStr = row['Tags'] as String? ?? '';
      list.add(Wallpaper(
        id: row['Id'] as String? ?? '',
        url: row['Url'] as String? ?? '',
        path: row['Path'] as String? ?? '',
        resolution: row['Resolution'] as String? ?? '',
        category: row['Category'] as String? ?? '',
        tags: tagsStr.isNotEmpty ? tagsStr.split(',') : [],
        uploader: row['Uploader'] as String? ?? '',
        shortUrl: row['ShortUrl'] as String? ?? '',
      ));
    }
    return list;
  }

  Future<bool> isFavorite(String id) async {
    // // AkonDeV 06/2026
    final stmt = _db.prepare('SELECT COUNT(1) FROM Favorites WHERE Id = ?;');
    final results = stmt.select([id]);
    stmt.dispose();
    if (results.isEmpty) return false;
    final count = results.first.columnAt(0) as int;
    return count > 0;
  }

  Future<void> saveSearchHistory(String queryText, String filterJson) async {
    // // AkonDeV 06/2026
    final stmt = _db.prepare('''
      INSERT INTO SearchHistory (QueryText, FilterJson, Timestamp)
      VALUES (?, ?, ?);
    ''');
    stmt.execute([
      queryText,
      filterJson,
      DateTime.now().toUtc().toIso8601String(),
    ]);
    stmt.dispose();
  }

  Future<List<Map<String, dynamic>>> getSearchHistory(int limit) async {
    // // AkonDeV 06/2026
    final stmt = _db.prepare('SELECT QueryText, FilterJson, Timestamp FROM SearchHistory ORDER BY Id DESC LIMIT ?;');
    final results = stmt.select([limit]);
    stmt.dispose();

    final list = <Map<String, dynamic>>[];
    for (final row in results) {
      list.add({
        'queryText': row['QueryText'] as String? ?? '',
        'filterJson': row['FilterJson'] as String? ?? '',
        'timestamp': row['Timestamp'] as String? ?? '',
      });
    }
    return list;
  }

  void close() {
    _db.dispose();
  }
}
