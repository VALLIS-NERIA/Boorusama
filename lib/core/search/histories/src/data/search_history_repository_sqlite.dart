// Package imports:
import 'package:sqlite3/sqlite3.dart';

// Project imports:
import '../search_history.dart';
import 'search_history_repository.dart';

class SearchHistoryRepositorySqlite implements SearchHistoryRepository {
  SearchHistoryRepositorySqlite({required this.db});

  final Database db;

  void initialize() {
    _createTableIfNotExists();
  }

  void _createTableIfNotExists() {
    db
      ..execute('''
    CREATE TABLE IF NOT EXISTS $kSearchHistoryTable (
      id INTEGER PRIMARY KEY,
      query TEXT NOT NULL,
      type TEXT NOT NULL,
      booru_type_name TEXT NOT NULL,
      site_url TEXT NOT NULL, 
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      search_count INTEGER DEFAULT 1,
      UNIQUE(query, type)
    );
  ''')
      ..execute('''
    CREATE INDEX IF NOT EXISTS idx_search_history_updated_at 
    ON $kSearchHistoryTable (updated_at);
  ''');
  }

  @override
  Future<List<SearchHistory>> getHistories() async {
    final result = db
        .select('SELECT * FROM $kSearchHistoryTable ORDER BY updated_at DESC');

    return result.map((row) {
      return SearchHistory(
        query: row['query'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row['created_at'] as int,
        ),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          row['updated_at'] as int,
        ),
        searchCount: row['search_count'] as int,
        queryType: parseQueryType(row['type'] as String?),
        booruTypeName: row['booru_type_name'] as String,
        siteUrl: row['site_url'] as String,
      );
    }).toList();
  }

  @override
  Future<List<SearchHistory>> addHistory(
    String query, {
    required QueryType queryType,
    required String booruTypeName,
    required String siteUrl,
  }) async {
    if (query.isEmpty) return getHistories();

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    try {
      db
        ..execute('BEGIN TRANSACTION')
        ..execute(
          '''
        INSERT INTO $kSearchHistoryTable (query, created_at, updated_at, search_count, type, booru_type_name, site_url)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(query, type) DO UPDATE SET
          search_count = search_count + 1,
          updated_at = ? 
        ''',
          [query, now, now, 1, queryType.name, booruTypeName, siteUrl, now],
        )
        ..execute('COMMIT');
    } catch (error) {
      db.execute('ROLLBACK');
      rethrow;
    }

    return getHistories();
  }

  @override
  Future<List<SearchHistory>> removeHistory(SearchHistory history) async {
    try {
      db
        ..execute('BEGIN TRANSACTION')
        ..execute(
          'DELETE FROM $kSearchHistoryTable WHERE query = ? AND type = ?',
          [history.query, history.queryType?.name],
        )
        ..execute('COMMIT');
    } catch (error) {
      db.execute('ROLLBACK');
      rethrow;
    }

    return getHistories();
  }

  @override
  Future<bool> clearAll() async {
    try {
      db
        ..execute('BEGIN TRANSACTION')
        ..execute('DELETE FROM $kSearchHistoryTable')
        ..execute('COMMIT');
      return true;
    } catch (error) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }
}
