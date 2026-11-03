import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_cat/core/errors/app_exception.dart';
import 'package:local_cat/data/services/database_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseService', () {
    late DatabaseService dbService;

    setUp(() async {
      // In-memory SQLite database for isolated unit test runs
      dbService = DatabaseService(customPath: inMemoryDatabasePath);
    });

    tearDown(() async {
      await dbService.close();
    });

    test('initializes schema and inserts root category successfully', () async {
      final root = await dbService.insertCategory(name: 'Electronics');

      expect(root.id, greaterThan(0));
      expect(root.name, 'Electronics');
      expect(root.parentId, isNull);

      final retrieved = await dbService.getCategoryById(root.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Electronics');
    });

    test('inserts subcategory under parent successfully', () async {
      final root = await dbService.insertCategory(name: 'Electronics');
      final child = await dbService.insertCategory(
        name: 'Mobile',
        parentId: root.id,
      );

      expect(child.id, greaterThan(0));
      expect(child.parentId, root.id);

      final children = await dbService.getCategoriesByParent(root.id);
      expect(children.length, 1);
      expect(children.first.name, 'Mobile');
    });

    test(
      'enforces uniqueness for root categories case-insensitively',
      () async {
        await dbService.insertCategory(name: 'Electronics');

        // Exact case duplicate
        expect(
          () => dbService.insertCategory(name: 'Electronics'),
          throwsA(isA<DuplicateCategoryException>()),
        );

        // Case-insensitive and trimmed duplicate
        expect(
          () => dbService.insertCategory(name: '  electronics  '),
          throwsA(isA<DuplicateCategoryException>()),
        );
      },
    );

    test(
      'enforces uniqueness for child categories under same parent',
      () async {
        final root = await dbService.insertCategory(name: 'Electronics');
        await dbService.insertCategory(name: 'Mobile', parentId: root.id);

        // Duplicate child under same parent
        expect(
          () => dbService.insertCategory(name: 'mobile', parentId: root.id),
          throwsA(isA<DuplicateCategoryException>()),
        );
      },
    );

    test('allows identical names under different parents', () async {
      final root1 = await dbService.insertCategory(name: 'Electronics');
      final root2 = await dbService.insertCategory(name: 'Fashion');

      final child1 = await dbService.insertCategory(
        name: 'Accessories',
        parentId: root1.id,
      );
      final child2 = await dbService.insertCategory(
        name: 'Accessories',
        parentId: root2.id,
      );

      expect(child1.id, isNot(equals(child2.id)));
      expect(child1.name, 'Accessories');
      expect(child2.name, 'Accessories');
    });

    test('enforces foreign key constraints', () async {
      // Inserting with non-existent parentId should fail SQLite foreign key check
      expect(
        () => dbService.insertCategory(name: 'Orphan', parentId: 9999),
        throwsA(isA<DatabaseAppException>()),
      );
    });

    test('batch inserts categories in a transaction', () async {
      await dbService.insertCategoriesBatch([
        (name: 'Hardware', parentId: null),
        (name: 'Software', parentId: null),
        (name: 'Networking', parentId: null),
      ]);

      final all = await dbService.getAllCategories();
      expect(all.length, 3);
    });

    test('paginates categories with limit and offset', () async {
      for (int i = 1; i <= 15; i++) {
        await dbService.insertCategory(
          name: 'Category ${i.toString().padLeft(2, '0')}',
        );
      }

      final page1 = await dbService.getPaginatedCategories(
        page: 1,
        pageSize: 10,
      );
      expect(page1.items.length, 10);
      expect(page1.totalCount, 15);
      expect(page1.totalPages, 2);
      expect(page1.hasNextPage, isTrue);

      final page2 = await dbService.getPaginatedCategories(
        page: 2,
        pageSize: 10,
      );
      expect(page2.items.length, 5);
      expect(page2.hasNextPage, isFalse);
    });

    test('persists data across database close and reopen', () async {
      final tempDir = Directory.systemTemp.createTempSync('local_cat_test_');
      final dbFilePath = p.join(tempDir.path, 'reopen_test.db');

      try {
        final service1 = DatabaseService(customPath: dbFilePath);
        await service1.insertCategory(name: 'Persisted Root');
        await service1.close();

        // Reopen database from same file path
        final service2 = DatabaseService(customPath: dbFilePath);
        final categories = await service2.getAllCategories();

        expect(categories.length, 1);
        expect(categories.first.name, 'Persisted Root');
        await service2.close();
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });
  });
}
