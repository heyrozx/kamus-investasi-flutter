import 'package:kamus_investasi/databases/database_instance.dart';
import 'package:kamus_investasi/models/dictionary_model.dart';
import 'package:sqflite/sqflite.dart';

class DictionaryRepository {
  // reference to our single class that manages the database
  final dbInstance = DatabaseInstance();

  Future<List<DictionaryModel>> getAllDictionaryAlphabets(
      {String? alphabet}) async {
    Database db = await dbInstance.database;
    final data = await db.rawQuery(
        'SELECT ${dbInstance.dictionaryTable}.* FROM ${dbInstance.dictionaryTable} WHERE ${dbInstance.dictionaryTable}.${dbInstance.dictionaryAlphabet}=? ORDER BY upper(${dbInstance.dictionaryTable}.${dbInstance.dictionaryTitle}) ASC',
        [alphabet]);

    List<DictionaryModel> listDictionaries = [];
    if (data.isNotEmpty) {
      for (var i = 0; i < data.length; i++) {
        DictionaryModel dictionaryModel = DictionaryModel(
          id: int.parse(data[i]['id'].toString()),
          title: data[i]['title'].toString(),
          fullTitle: data[i]['full_title'].toString(),
          description: data[i]['description'].toString(),
          alphabet: data[i]['alphabet'].toString(),
          category: data[i]['category'].toString(),
          createdAt: data[i]['created_at'].toString(),
          updatedAt: data[i]['updated_at'].toString(),
        );
        listDictionaries.add(dictionaryModel);
      }
    }

    return listDictionaries;
  }

  Future<List<DictionaryModel>> getDictionaryAlphabets(
      {String? alphabet, String? q}) async {
    Database db = await dbInstance.database;
    final data = await db.rawQuery(
        'SELECT ${dbInstance.dictionaryTable}.* FROM ${dbInstance.dictionaryTable} WHERE ${dbInstance.dictionaryTable}.${dbInstance.dictionaryAlphabet}=? AND (${dbInstance.dictionaryTable}.${dbInstance.dictionaryTitle} LIKE ? OR ${dbInstance.dictionaryTable}.${dbInstance.dictionaryFullTitle} LIKE ?) ORDER BY upper(${dbInstance.dictionaryTable}.${dbInstance.dictionaryTitle}) ASC LIMIT 5',
        [alphabet, '%$q%', '%$q%']);

    List<DictionaryModel> listDictionaries = [];
    if (data.isNotEmpty) {
      for (var i = 0; i < data.length; i++) {
        DictionaryModel dictionaryModel = DictionaryModel(
          id: int.parse(data[i]['id'].toString()),
          title: data[i]['title'].toString(),
          fullTitle: data[i]['full_title'].toString(),
          description: data[i]['description'].toString(),
          alphabet: data[i]['alphabet'].toString(),
          category: data[i]['category'].toString(),
          createdAt: data[i]['created_at'].toString(),
          updatedAt: data[i]['updated_at'].toString(),
        );
        listDictionaries.add(dictionaryModel);
      }
    }

    return listDictionaries;
  }

  Future<List<DictionaryByAlphabets>> all(
      {int? limit, int? page, String? q}) async {
    // Setup pagination
    limit ??= 10;
    q ??= '';
    int offset = (limit * ((page ?? 0) + 1)) - limit;

    Database db = await dbInstance.database;
    final data = await db.rawQuery(
        'SELECT ${dbInstance.dictionaryTable}.alphabet  FROM ${dbInstance.dictionaryTable} WHERE ${dbInstance.dictionaryTable}.${dbInstance.dictionaryTitle} LIKE ? OR ${dbInstance.dictionaryTable}.${dbInstance.dictionaryFullTitle} LIKE ? GROUP BY ${dbInstance.dictionaryTable}.${dbInstance.dictionaryAlphabet} ORDER BY ${dbInstance.dictionaryTable}.${dbInstance.dictionaryTitle} ASC LIMIT $limit OFFSET $offset',
        ['%$q%', '%$q%']);

    List<DictionaryByAlphabets> listDictionaryAlphabets = [];
    if (data.isNotEmpty) {
      for (var i = 0; i < data.length; i++) {
        List<DictionaryModel>? listTransactions = await getDictionaryAlphabets(
            alphabet: data[i]['alphabet'].toString(), q: q);

        listDictionaryAlphabets.add(DictionaryByAlphabets(
            alphabet: data[i]['alphabet'].toString(),
            listDictionaries: listTransactions));
      }
    }

    return listDictionaryAlphabets;
  }

  Future<List<DictionaryModel>>? related(String category) async {
    Database db = await dbInstance.database;
    final data = await db.rawQuery(
        'SELECT * FROM ${dbInstance.dictionaryTable} WHERE ${dbInstance.dictionaryTable}.${dbInstance.dictionaryCategory} = ? order by random() LIMIT 8',
        [category]);
    // print(data);

    List<DictionaryModel> listDictionaries = [];
    if (data.isNotEmpty) {
      for (var i = 0; i < data.length; i++) {
        DictionaryModel dictionaryModel = DictionaryModel(
          id: int.parse(data[i]['id'].toString()),
          title: data[i]['title'].toString(),
          fullTitle: data[i]['full_title'].toString(),
          description: data[i]['description'].toString(),
          alphabet: data[i]['alphabet'].toString(),
          category: data[i]['category'].toString(),
          createdAt: data[i]['created_at'].toString(),
          updatedAt: data[i]['updated_at'].toString(),
        );
        listDictionaries.add(dictionaryModel);
      }
    }

    return listDictionaries;
  }

  Future first() async {
    Database db = await dbInstance.database;
    final data = await db.rawQuery(
        'SELECT * FROM ${dbInstance.dictionaryTable} ORDER BY ${dbInstance.dictionaryTable}.${dbInstance.dictionaryCreatedAt} DESC LIMIT 1',
        []);

    return data.length;
  }

  Future<int> count() async {
    Database db = await dbInstance.database;
    final data = await db.rawQuery(
        'SELECT COUNT(*) as total FROM ${dbInstance.dictionaryTable}', []);
    return int.parse(data[0]['total'].toString());
  }

  Future<DictionaryModel?> find(int id) async {
    Database db = await dbInstance.database;
    final data = await db.rawQuery(
        'SELECT * FROM ${dbInstance.dictionaryTable} WHERE ${dbInstance.dictionaryTable}.${dbInstance.dictionaryId}=$id ORDER BY ${dbInstance.dictionaryTable}.${dbInstance.dictionaryCreatedAt} DESC LIMIT 1',
        []);
    if (data.isNotEmpty) {
      return DictionaryModel.fromJson(data[0]);
    }
    return null;
  }
}
