import 'package:flutter_test/flutter_test.dart';
import 'package:local_cat/controllers/category_controller.dart';
import 'package:local_cat/core/errors/app_exception.dart';
import 'package:local_cat/data/models/category_model.dart';
import 'package:local_cat/data/models/category_search_item.dart';
import 'package:local_cat/data/models/category_tree_node.dart';
import 'package:local_cat/data/models/paginated_result.dart';
import 'package:local_cat/data/repositories/category_repository.dart';

class FakeCategoryRepository implements CategoryRepository {
  final List<CategoryModel> categories = [];
  bool shouldThrow = false;
  AppException? exceptionToThrow;

  @override
  Future<CategoryModel> createCategory({
    required String name,
    int? parentId,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const DuplicateCategoryException('Test');
    }

    // Check duplicate
    for (final c in categories) {
      if (c.parentId == parentId &&
          c.name.toLowerCase() == name.toLowerCase()) {
        throw DuplicateCategoryException(name, parentId);
      }
    }

    final newCat = CategoryModel(
      id: categories.length + 1,
      name: name,
      parentId: parentId,
      createdAt: DateTime.now(),
    );
    categories.add(newCat);
    return newCat;
  }

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const DatabaseAppException('DB Error');
    }
    return List.from(categories);
  }

  @override
  Future<CategoryModel?> getCategoryById(int id) async {
    return categories.where((c) => c.id == id).firstOrNull;
  }

  @override
  Future<List<CategoryTreeNode>> getCategoryTree() async {
    return CategoryTreeHelper.buildTree(categories);
  }

  @override
  Future<PaginatedResult<CategorySearchItem>> searchCategories({
    required String query,
    int page = 1,
    int pageSize = 10,
    int? limit,
  }) async {
    final trimmed = query.toLowerCase();
    final matching = categories
        .where((c) => c.name.toLowerCase().contains(trimmed))
        .toList();
    final categoryMap = {for (final c in categories) c.id: c};

    final items = matching.map((c) {
      final path = CategoryTreeHelper.buildPath(categoryMap, c.id);
      return CategorySearchItem(
        category: c,
        path: path,
        pathString: path.map((e) => e.name).join(' → '),
        parent: c.parentId != null ? categoryMap[c.parentId!] : null,
        directChildren: categories
            .where((child) => child.parentId == c.id)
            .toList(),
      );
    }).toList();

    return PaginatedResult.fromAll(
      allItems: items,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<PaginatedResult<CategoryModel>> getPaginatedCategories({
    int page = 1,
    int pageSize = 10,
    int? parentId,
  }) async {
    return PaginatedResult.fromAll(
      allItems: categories.where((c) => c.parentId == parentId).toList(),
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<void> deleteCategory(int id) async {
    categories.removeWhere((c) => c.id == id);
  }
}

void main() {
  group('CategoryController', () {
    late FakeCategoryRepository fakeRepo;
    late CategoryController controller;

    setUp(() {
      fakeRepo = FakeCategoryRepository();
      controller = CategoryController(categoryRepository: fakeRepo);
    });

    test('initial state is empty and not loading', () {
      expect(controller.allCategories, isEmpty);
      expect(controller.treeRoots, isEmpty);
      expect(controller.isLoading, isFalse);
      expect(controller.isEmpty, isTrue);
      expect(controller.errorMessage, isNull);
    });

    test('loadCategories populates categories and treeRoots', () async {
      fakeRepo.categories.addAll([
        CategoryModel(
          id: 1,
          name: 'Electronics',
          parentId: null,
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          id: 2,
          name: 'Mobile',
          parentId: 1,
          createdAt: DateTime.now(),
        ),
      ]);

      await controller.loadCategories();

      expect(controller.allCategories.length, 2);
      expect(controller.treeRoots.length, 1);
      expect(controller.treeRoots.first.name, 'Electronics');
      expect(controller.treeRoots.first.children.length, 1);
      expect(controller.isEmpty, isFalse);
      expect(controller.isLoading, isFalse);
    });

    test('createCategory adds category and auto-expands parent', () async {
      fakeRepo.categories.add(
        CategoryModel(
          id: 1,
          name: 'Electronics',
          parentId: null,
          createdAt: DateTime.now(),
        ),
      );
      await controller.loadCategories();

      final success = await controller.createCategory(
        name: 'Laptops',
        parentId: 1,
      );

      expect(success, isTrue);
      expect(controller.allCategories.length, 2);
      expect(controller.isExpanded(1), isTrue); // Auto-expanded
      expect(controller.isSaving, isFalse);
    });

    test('createCategory fails when duplicate and sets errorMessage', () async {
      fakeRepo.categories.add(
        CategoryModel(
          id: 1,
          name: 'Electronics',
          parentId: null,
          createdAt: DateTime.now(),
        ),
      );
      await controller.loadCategories();

      final success = await controller.createCategory(
        name: 'electronics', // duplicate root
        parentId: null,
      );

      expect(success, isFalse);
      expect(controller.errorMessage, contains('already exists'));
      expect(controller.isSaving, isFalse);
    });

    test('toggleExpanded, expandAll, collapseAll manage tree state', () async {
      fakeRepo.categories.addAll([
        CategoryModel(
          id: 1,
          name: 'Root1',
          parentId: null,
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          id: 2,
          name: 'Root2',
          parentId: null,
          createdAt: DateTime.now(),
        ),
      ]);
      await controller.loadCategories();

      expect(controller.isExpanded(1), isFalse);
      controller.toggleExpanded(1);
      expect(controller.isExpanded(1), isTrue);
      controller.toggleExpanded(1);
      expect(controller.isExpanded(1), isFalse);

      controller.expandAll();
      expect(controller.isExpanded(1), isTrue);
      expect(controller.isExpanded(2), isTrue);

      controller.collapseAll();
      expect(controller.isExpanded(1), isFalse);
      expect(controller.isExpanded(2), isFalse);
    });

    test('search updates searchResults with correct hierarchy', () async {
      fakeRepo.categories.addAll([
        CategoryModel(
          id: 1,
          name: 'Electronics',
          parentId: null,
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          id: 2,
          name: 'Mobile',
          parentId: 1,
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          id: 3,
          name: 'Samsung',
          parentId: 2,
          createdAt: DateTime.now(),
        ),
      ]);
      await controller.loadCategories();

      await controller.search('samsung');

      expect(controller.searchResults, isNotNull);
      expect(controller.searchResults!.items.length, 1);
      final item = controller.searchResults!.items.first;
      expect(item.category.name, 'Samsung');
      expect(item.pathString, 'Electronics → Mobile → Samsung');
      expect(item.parent!.name, 'Mobile');

      controller.clearSearch();
      expect(controller.searchResults, isNull);
      expect(controller.searchQuery, isEmpty);
    });

    test(
      'navigateToCategoryInTree auto-expands ancestors and clears search',
      () async {
        fakeRepo.categories.addAll([
          CategoryModel(
            id: 1,
            name: 'Electronics',
            parentId: null,
            createdAt: DateTime.now(),
          ),
          CategoryModel(
            id: 2,
            name: 'Mobile',
            parentId: 1,
            createdAt: DateTime.now(),
          ),
          CategoryModel(
            id: 3,
            name: 'Samsung',
            parentId: 2,
            createdAt: DateTime.now(),
          ),
        ]);
        await controller.loadCategories();
        await controller.search('samsung');

        controller.navigateToCategoryInTree(3);

        expect(controller.searchResults, isNull);
        expect(controller.isExpanded(1), isTrue); // Root expanded
        expect(controller.isExpanded(2), isTrue); // Mobile expanded
        expect(controller.highlightedCategoryId, 3);
      },
    );
  });
}
