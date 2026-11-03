import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/constants/database_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/date_time_utils.dart';
import '../models/category_model.dart';
import '../models/paginated_result.dart';

class DatabaseService {
  DatabaseService({this.customPath, Database? database}) : _db = database;

  final String? customPath;
  Database? _db;

  /// Returns the active SQLite database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_db != null && _db!.isOpen) {
      return _db!;
    }
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final String path;
    if (customPath != null) {
      path = customPath!;
    } else {
      final databasesPath = await getDatabasesPath();
      path = p.join(databasesPath, DatabaseConstants.databaseName);
    }

    return openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Explicitly enforce foreign keys in SQLite
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Create categories table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableCategories} (
        ${DatabaseConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.columnName} TEXT NOT NULL,
        ${DatabaseConstants.columnParentId} INTEGER NULL,
        ${DatabaseConstants.columnCreatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DatabaseConstants.columnParentId})
          REFERENCES ${DatabaseConstants.tableCategories} (${DatabaseConstants.columnId})
          ON DELETE CASCADE
      );
    ''');

    // 2. Index for fast child-to-parent and parent-to-children queries
    await db.execute('''
      CREATE INDEX idx_categories_parent_id
      ON ${DatabaseConstants.tableCategories} (${DatabaseConstants.columnParentId});
    ''');

    // 3. Partial unique index for ROOT categories (case-insensitive & trimmed)
    await db.execute('''
      CREATE UNIQUE INDEX idx_categories_root_unique
      ON ${DatabaseConstants.tableCategories} (LOWER(TRIM(${DatabaseConstants.columnName})))
      WHERE ${DatabaseConstants.columnParentId} IS NULL;
    ''');

    // 4. Partial unique index for CHILD categories under the same parent (case-insensitive & trimmed)
    await db.execute('''
      CREATE UNIQUE INDEX idx_categories_child_unique
      ON ${DatabaseConstants.tableCategories} (${DatabaseConstants.columnParentId}, LOWER(TRIM(${DatabaseConstants.columnName})))
      WHERE ${DatabaseConstants.columnParentId} IS NOT NULL;
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Reserved for safe database schema migrations in future versions
  }

  /// Inserts a new category with parameterized query and unique constraint handling.
  Future<CategoryModel> insertCategory({
    required String name,
    int? parentId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const ValidationException('Category name cannot be empty.');
    }

    final db = await database;
    final now = DateTime.now();

    try {
      final id = await db.insert(
        DatabaseConstants.tableCategories,
        {
          DatabaseConstants.columnName: trimmedName,
          DatabaseConstants.columnParentId: parentId,
          DatabaseConstants.columnCreatedAt: DateTimeUtils.toIso8601(now),
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return CategoryModel(
        id: id,
        name: trimmedName,
        parentId: parentId,
        createdAt: now,
      );
    } catch (e) {
      if (_isUniqueConstraintError(e)) {
        throw DuplicateCategoryException(trimmedName, parentId);
      }
      throw DatabaseAppException('Failed to insert category: $e', e);
    }
  }

  /// Retrieves all categories ordered by parent_id and name.
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      final db = await database;
      final results = await db.query(
        DatabaseConstants.tableCategories,
        orderBy:
            '${DatabaseConstants.columnParentId} ASC, LOWER(${DatabaseConstants.columnName}) ASC',
      );

      return results.map((row) => CategoryModel.fromMap(row)).toList();
    } catch (e) {
      throw DatabaseAppException('Failed to fetch categories: $e', e);
    }
  }

  /// Retrieves a category by its ID.
  Future<CategoryModel?> getCategoryById(int id) async {
    try {
      final db = await database;
      final results = await db.query(
        DatabaseConstants.tableCategories,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return CategoryModel.fromMap(results.first);
    } catch (e) {
      throw DatabaseAppException('Failed to fetch category with ID $id: $e', e);
    }
  }

  /// Retrieves categories under a specific parent (or root categories if parentId is null).
  Future<List<CategoryModel>> getCategoriesByParent(int? parentId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> results;

      if (parentId == null) {
        results = await db.query(
          DatabaseConstants.tableCategories,
          where: '${DatabaseConstants.columnParentId} IS NULL',
          orderBy: 'LOWER(${DatabaseConstants.columnName}) ASC',
        );
      } else {
        results = await db.query(
          DatabaseConstants.tableCategories,
          where: '${DatabaseConstants.columnParentId} = ?',
          whereArgs: [parentId],
          orderBy: 'LOWER(${DatabaseConstants.columnName}) ASC',
        );
      }

      return results.map((row) => CategoryModel.fromMap(row)).toList();
    } catch (e) {
      throw DatabaseAppException('Failed to fetch child categories: $e', e);
    }
  }

  /// Retrieves categories with optional parent filtering and SQLite LIMIT and OFFSET pagination.
  Future<PaginatedResult<CategoryModel>> getPaginatedCategories({
    int page = 1,
    int pageSize = 10,
    int? parentId,
  }) async {
    if (page < 1) {
      throw const ValidationException('Page number must be 1 or greater.');
    }
    if (pageSize < 1) {
      throw const ValidationException('Page size must be 1 or greater.');
    }

    try {
      final db = await database;
      final String whereClause;
      final List<Object?> whereArgs;

      if (parentId == null) {
        whereClause = '${DatabaseConstants.columnParentId} IS NULL';
        whereArgs = [];
      } else {
        whereClause = '${DatabaseConstants.columnParentId} = ?';
        whereArgs = [parentId];
      }

      // Count total matching rows
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseConstants.tableCategories} WHERE $whereClause',
        whereArgs,
      );
      final totalCount = Sqflite.firstIntValue(countResult) ?? 0;

      final offset = (page - 1) * pageSize;
      final results = await db.query(
        DatabaseConstants.tableCategories,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'LOWER(${DatabaseConstants.columnName}) ASC',
        limit: pageSize,
        offset: offset,
      );

      final items = results.map((row) => CategoryModel.fromMap(row)).toList();

      return PaginatedResult(
        items: items,
        page: page,
        pageSize: pageSize,
        totalCount: totalCount,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseAppException('Failed to paginate categories: $e', e);
    }
  }

  /// Inserts multiple categories inside a single transaction.
  Future<void> insertCategoriesBatch(
    List<({String name, int? parentId})> items,
  ) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        for (final item in items) {
          final trimmed = item.name.trim();
          await txn.insert(
            DatabaseConstants.tableCategories,
            {
              DatabaseConstants.columnName: trimmed,
              DatabaseConstants.columnParentId: item.parentId,
              DatabaseConstants.columnCreatedAt: DateTimeUtils.toIso8601(
                DateTime.now(),
              ),
            },
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
      });
    } catch (e) {
      if (_isUniqueConstraintError(e)) {
        throw const DuplicateCategoryException('Duplicate category in batch');
      }
      throw DatabaseAppException('Batch insertion failed: $e', e);
    }
  }

  /// Deletes a category and its cascading children.
  Future<int> deleteCategory(int id) async {
    try {
      final db = await database;
      return await db.delete(
        DatabaseConstants.tableCategories,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseAppException('Failed to delete category $id: $e', e);
    }
  }

  /// Checks if an error is a SQLite unique constraint violation.
  bool _isUniqueConstraintError(Object error) {
    final str = error.toString().toUpperCase();
    if (str.contains('UNIQUE') ||
        str.contains('2067') ||
        str.contains('1555')) {
      return true;
    }
    if (error is DatabaseException && error.isUniqueConstraintError()) {
      return true;
    }
    return false;
  }

  /// Closes database connection cleanly.
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
