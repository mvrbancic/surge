/// SQLite database initialization and singleton access.
library;

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton wrapper around the sqflite [Database].
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'surge.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('''
      CREATE TABLE trainings (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        created_at  TEXT    NOT NULL,
        updated_at  TEXT    NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE exercises (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        training_id      INTEGER NOT NULL REFERENCES trainings(id) ON DELETE CASCADE,
        position         INTEGER NOT NULL,
        type             TEXT    NOT NULL,
        name             TEXT,
        duration_seconds INTEGER NOT NULL,
        rep_count        INTEGER,
        inter_rep_pause  INTEGER
      )
    ''');
  }
}
