import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'db_factory.dart';

/// Local-first SQLite database. No data ever leaves the device through
/// this layer — sync/cloud backup, if ever added, must be opt-in.
///
/// Runs on: Android/iOS via the standard `sqflite` plugin, Windows/Linux/
/// macOS via `sqflite_common_ffi` (native FFI bindings — this is what
/// makes the portable desktop build work with zero extra setup on the
/// target machine), and the web via `sqflite_common_ffi_web` (WASM SQLite
/// backed by IndexedDB). `initDatabaseFactory()` (see db_factory.dart)
/// picks the right one at compile time; everything below this line calls
/// the exact same `openDatabase` API regardless of platform.
class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    await initDatabaseFactory();
    const dbName = 'debt_manager.db';

    if (kIsWeb) {
      // The web factory has no filesystem concept — it manages its own
      // IndexedDB-backed storage keyed by the database name.
      return openDatabase(dbName, version: 1, onCreate: _onCreate);
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, dbName);
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        defaultCurrency TEXT NOT NULL DEFAULT 'AED',
        createdAt TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE persons (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        notes TEXT
      );
    ''');

    // No interest / APR / penalty columns by design.
    await db.execute('''
      CREATE TABLE debts (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL CHECK(type IN ('LENT','BORROWED')),
        personId TEXT NOT NULL,
        originalAmount REAL NOT NULL CHECK(originalAmount > 0),
        currency TEXT NOT NULL,
        debtDate TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        description TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        manuallyMarkedPaid INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (personId) REFERENCES persons (id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        debtId TEXT NOT NULL,
        amount REAL NOT NULL CHECK(amount > 0),
        paymentDate TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (debtId) REFERENCES debts (id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        debtId TEXT NOT NULL,
        reminderDate TEXT NOT NULL,
        reminderType TEXT NOT NULL,
        isEnabled INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (debtId) REFERENCES debts (id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE attachments (
        id TEXT PRIMARY KEY,
        debtId TEXT NOT NULL,
        fileName TEXT NOT NULL,
        filePath TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (debtId) REFERENCES debts (id) ON DELETE CASCADE
      );
    ''');

    await db.execute('CREATE INDEX idx_debts_personId ON debts(personId);');
    await db.execute('CREATE INDEX idx_payments_debtId ON payments(debtId);');
    await db.execute('CREATE INDEX idx_reminders_debtId ON reminders(debtId);');
  }

  Future<void> deleteAllRows() async {
    final db = await database;
    await db.delete('attachments');
    await db.delete('reminders');
    await db.delete('payments');
    await db.delete('debts');
    await db.delete('persons');
  }
}
