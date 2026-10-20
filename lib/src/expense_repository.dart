import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqlite_encrypted/sqlite_encrypted.dart';

import 'expense.dart';

class ExpenseRepository {
  static const _activationKey = String.fromEnvironment(
    'SQLITE_ENCRYPTED_ACTIVATION_KEY',
  );
  static const _databaseKeyStorageName = 'expense_tracker_database_key';
  static const _databaseFileName = 'expense_tracker.db';

  final FlutterSecureStorage _secureStorage = Platform.isMacOS
      ? const FlutterSecureStorage(
          mOptions: MacOsOptions(usesDataProtectionKeychain: false),
        )
      : const FlutterSecureStorage();
  Database? _database;

  Future<void> initialize() async {
    _validateActivationKey(_activationKey);

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      ffi.sqfliteFfiInit();
      databaseFactory = ffi.databaseFactoryFfi;
    }

    try {
      await activateSee(_activationKey);
      await _verifyActivation();
    } catch (error) {
      throw StateError(
        'SQLite.Encrypted could not activate SEE. Verify that '
        'SQLITE_ENCRYPTED_ACTIVATION_KEY contains a valid, unexpired '
        'activation key for this platform and SQLite version. Details: $error',
      );
    }

    final databaseKey = await _loadOrCreateDatabaseKey();
    final databaseDirectory = await getDatabasesPath();
    final databasePath = path.join(databaseDirectory, _databaseFileName);

    _database = await openDatabase(
      databasePath,
      key: databaseKey,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            merchant TEXT NOT NULL,
            category TEXT NOT NULL,
            amount_cents INTEGER NOT NULL,
            spent_at TEXT NOT NULL
          )
        ''');
        await database.execute(
          'CREATE INDEX expenses_spent_at ON expenses(spent_at DESC)',
        );
      },
    );
  }

  Future<List<Expense>> listExpenses({String? category}) async {
    final rows = await _requireDatabase().query(
      'expenses',
      where: category == null ? null : 'category = ?',
      whereArgs: category == null ? null : <Object?>[category],
      orderBy: 'spent_at DESC, id DESC',
    );
    return rows.map(Expense.fromRow).toList(growable: false);
  }

  Future<void> addExpense({
    required String merchant,
    required String category,
    required int amountCents,
    required DateTime spentAt,
  }) async {
    await _requireDatabase().insert('expenses', <String, Object?>{
      'merchant': merchant.trim(),
      'category': category,
      'amount_cents': amountCents,
      'spent_at': spentAt.toUtc().toIso8601String(),
    });
  }

  Future<void> deleteExpense(int id) async {
    await _requireDatabase().delete(
      'expenses',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<void> _verifyActivation() async {
    final probe = await openDatabase(
      inMemoryDatabasePath,
      key: 'sqlite-encrypted-activation-probe',
      singleInstance: false,
    );
    try {
      await probe.rawQuery('SELECT count(*) FROM sqlite_master');
    } finally {
      await probe.close();
    }
  }

  Future<String> _loadOrCreateDatabaseKey() async {
    final existing = await _secureStorage.read(key: _databaseKeyStorageName);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final random = Random.secure();
    final generated = List<int>.generate(
      32,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    await _secureStorage.write(key: _databaseKeyStorageName, value: generated);
    return generated;
  }

  Database _requireDatabase() {
    final database = _database;
    if (database == null) {
      throw StateError('The expense database has not been initialized.');
    }
    return database;
  }

  static void _validateActivationKey(String activationKey) {
    if (activationKey.trim().isEmpty) {
      throw StateError(
        'SQLITE_ENCRYPTED_ACTIVATION_KEY is missing. Start Flutter with '
        '--dart-define=SQLITE_ENCRYPTED_ACTIVATION_KEY=<your-key>.',
      );
    }
    if (activationKey.startsWith('see-')) {
      throw StateError(
        'SQLITE_ENCRYPTED_ACTIVATION_KEY must contain the activation hex '
        'string without the see- prefix.',
      );
    }
  }
}
