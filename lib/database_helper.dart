import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  Future<void> initializeApp() async {
    await initializeDatabase();

    await saveAllergy("새우깡", ["밀", "새우", "우유"]);
    await saveAllergy("딸기우유", ["우유"]);
    await saveAllergy("홈런볼", ["밀", "우유"]);

  }
  Future<void> saveUserAllergens(List<String> allergens) async {
    final db = await database;
    final allergensString = allergens.join(', ');

    await db.rawInsert(
      'INSERT OR REPLACE INTO users (id, allergens) VALUES (?, ?)',
      [1, allergensString],
    );
  }




  Future<List<String>> getUserAllergens() async {
    final db = await database;
    final results = await db.query('users', where: 'id = ?', whereArgs: [1]);
    if (results.isNotEmpty) {
      final allergensString = results.first['allergens'] as String;
      return allergensString.split(', ');
    } else {
      return []; // 사용자의 알레르기 정보가 없을 경우 빈 리스트를 반환
    }
  }




  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initializeDatabase();
    return _database!;
  }

  Future<Database> initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'my_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE allergies(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          productName TEXT,
          allergens TEXT
        )
      ''');

        await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          allergens TEXT
        )
      ''');
      },
    );
  }


  Future<void> saveAllergy(String productName, List<String> allergens) async {
    final db = await database;
    final allergensString = allergens.join(', ');
    await db.insert(
      'allergies',
      {'productName': productName, 'allergens': allergensString},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> getAllProducts() async {
    final db = await database;
    final results = await db.query('allergies');
    return results.map((e) => e['productName'] as String).toList();
  }

  Future<String?> compareProducts(String extractedText) async {
    final products = await getAllProducts();
    String? matchedProduct;
    for (var product in products) {
      if (extractedText.contains(product)) {
        matchedProduct = product;
        break;
      }
    }
    return matchedProduct;
  }


  Future<List<String>> getAllergensByProductName(String productName) async {
    final db = await database;
    final results = await db.query(
      'allergies',
      where: 'productName = ?',
      whereArgs: [productName],
    );
    return results.map((e) => e['allergens'] as String).toList();
  }

}