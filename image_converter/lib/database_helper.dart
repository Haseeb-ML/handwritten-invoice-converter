import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'invoice_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('invoices.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT';
    const realType = 'REAL';

    await db.execute('''
CREATE TABLE invoices (
  id $idType,
  imagePath $textType,
  createdAt $textType,
  vendorName $textType,
  vendorAddress $textType,
  invoiceTitle $textType,
  invoiceNumber $textType,
  date $textType,
  dueDate $textType,
  clientName $textType,
  clientAddress $textType,
  items $textType,
  taxRate $realType,
  discount $realType,
  notes $textType
)
''');
  }

  Future<InvoiceModel> insertInvoice(InvoiceModel invoice) async {
    final db = await instance.database;
    final id = await db.insert('invoices', invoice.toMap());
    invoice.id = id;
    return invoice;
  }

  Future<List<InvoiceModel>> getInvoices() async {
    final db = await instance.database;
    final orderBy = 'createdAt DESC';
    final result = await db.query('invoices', orderBy: orderBy);

    return result.map((json) => InvoiceModel.fromMap(json)).toList();
  }

  Future<int> deleteInvoice(int id) async {
    final db = await instance.database;
    return await db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
