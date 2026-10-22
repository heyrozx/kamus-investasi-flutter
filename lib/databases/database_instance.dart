import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseInstance {
  final String _databaseName = "kamus_investasi.db";
  final int _databaseVersion = 1;

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
  Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    // lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database!;
  }

  // this opens the database (and creates it if it doesn't exist)
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $dictionaryTable (
            $dictionaryId INTEGER PRIMARY KEY,
            $dictionaryAlphabet TEXT NULL,
            $dictionaryTitle TEXT NULL,
            $dictionaryFullTitle TEXT NULL,
            $dictionaryCategory TEXT NULL,
            $dictionaryDescription TEXT NULL,
            $dictionaryCreatedAt TEXT NULL,
            $dictionaryUpdatedAt TEXT NULL
          )
          ''');

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
}
