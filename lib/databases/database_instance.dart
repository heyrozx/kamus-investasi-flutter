import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kamus_investasi/databases/dictionaries/dictionary_db_version.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseInstance {
  // User data (bookmarks, histories). The dictionary itself lives in a
  // separate read-only file that is attached to this connection.
  final String _databaseName = "kamus_investasi.db";
  final int _databaseVersion = 2;

  // Prebuilt by tool/dictionary_db from assets/datasets/dictionaries.json.
  static const String _dictionaryAsset = 'assets/db/dictionary.db';
  static const String _dictionaryDatabaseName = 'dictionary.db';

  // Dictionary Table
  final String dictionaryTable = 'dictionaries';
  final String dictionaryId = 'id';
  final String dictionaryAlphabet = 'alphabet';
  final String dictionaryTitle = 'title';
  final String dictionaryFullTitle = 'full_title';
  final String dictionaryDescription = 'description';
  final String dictionaryCategory = 'category';
  final String dictionaryCreatedAt = 'created_at';
  final String dictionaryUpdatedAt = 'updated_at';

  // Bookmark Table
  final String bookmarkTable = 'bookmarks';
  final String bookmarkId = 'id';
  final String bookmarkDictionaryId = 'dictionary_id';
  final String bookmarkDescription = 'description';
  final String bookmarkCreatedAt = 'created_at';
  final String bookmarkUpdatedAt = 'updated_at';

  // History Table
  final String historyTable = 'histories';
  final String historyId = 'id';
  final String historyDictionaryId = 'dictionary_id';
  final String historyDescription = 'description';
  final String historyCreatedAt = 'created_at';
  final String historyUpdatedAt = 'updated_at';

  // only have a single app-wide reference to the database
  static Future<Database>? _database;
  Future<Database> get database => _database ??= _initDatabase();

  // this opens the database (and creates it if it doesn't exist)
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String dictionaryPath = join(
      documentsDirectory.path,
      _dictionaryDatabaseName,
    );
    await _installDictionary(dictionaryPath);

    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      // Unqualified `dictionaries` in the repositories resolves to the
      // attached file, since the main database has no such table.
      onOpen: (db) =>
          db.execute('ATTACH DATABASE ? AS dictionary_db', [dictionaryPath]),
    );
  }

  // Copies the bundled dictionary on first launch, and again whenever the
  // bundled version differs from the installed one (i.e. after an app update
  // that changed the data). User data is in another file and is untouched.
  Future<void> _installDictionary(String path) async {
    if (await File(path).exists()) {
      try {
        Database installed = await openReadOnlyDatabase(path);
        final result = await installed.rawQuery('PRAGMA user_version');
        await installed.close();
        if (result.first.values.first == dictionaryDbVersion) return;
      } catch (e) {
        if (kDebugMode) print('--- Reinstalling dictionary database: $e');
      }
    }

    if (kDebugMode) {
      print('--- Installing dictionary database v$dictionaryDbVersion');
    }
    ByteData data = await rootBundle.load(_dictionaryAsset);
    File tmp = File('$path.tmp');
    await tmp.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    await tmp.rename(path);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $bookmarkTable (
            $bookmarkId INTEGER PRIMARY KEY,
            $bookmarkDictionaryId INTEGER NULL,
            $bookmarkDescription TEXT NULL,
            $bookmarkCreatedAt TEXT NULL,
            $bookmarkUpdatedAt TEXT NULL
          )
          ''');

    await db.execute('''
          CREATE TABLE $historyTable (
            $historyId INTEGER PRIMARY KEY,
            $historyDictionaryId INTEGER NULL,
            $historyDescription TEXT NULL,
            $historyCreatedAt TEXT NULL,
            $historyUpdatedAt TEXT NULL
          )
          ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 seeded the dictionary into this file at runtime. It now comes from
      // the attached dictionary.db; bookmark/history ids stay valid because
      // both use the JSON order (1..n) as id.
      await db.execute('DROP TABLE IF EXISTS $dictionaryTable');
    }
  }
}
