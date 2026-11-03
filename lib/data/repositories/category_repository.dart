import '../../core/errors/app_exception.dart';
import '../../core/utils/validators.dart';
import '../models/category_model.dart';
import '../models/category_search_item.dart';
import '../models/category_tree_node.dart';
import '../models/paginated_result.dart';
import '../services/database_service.dart';

abstract class CategoryRepository {
  Future<CategoryModel> createCategory({required String name, int? parentId});
  Future<List<CategoryModel>> getAllCategories();
  Future<CategoryModel?> getCategoryById(int id);
  Future<List<CategoryTreeNode>> getCategoryTree();
  Future<PaginatedResult<CategorySearchItem>> searchCategories({
    required String query,
    int page = 1,
    int pageSize = 10,
    int? limit,
  });
  Future<PaginatedResult<CategoryModel>> getPaginatedCategories({
    int page = 1,
    int pageSize = 10,
    int? parentId,
  });
  Future<void> deleteCategory(int id);
}

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl({required this.databaseService});

  final DatabaseService databaseService;

  @override
  Future<CategoryModel> createCategory({
    required String name,
    int? parentId,
  }) async {
    final trimmedName = name.trim();
    final validationError = Validators.validateCategoryName(trimmedName);
    if (validationError != null) {
      throw ValidationException(validationError);
    }

    // Verify parent exists if parentId provided
    if (parentId != null) {
      final parent = await databaseService.getCategoryById(parentId);
      if (parent == null) {
        throw CategoryNotFoundException(parentId);
      }
    }

    // Insert into database (database unique indexes will enforce uniqueness atomically)
    return databaseService.insertCategory(
      name: trimmedName,
      parentId: parentId,
    );
  }

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    return databaseService.getAllCategories();
  }

  @override
  Future<CategoryModel?> getCategoryById(int id) async {
    return databaseService.getCategoryById(id);
  }

  @override
  Future<List<CategoryTreeNode>> getCategoryTree() async {
    final all = await databaseService.getAllCategories();
    return CategoryTreeHelper.buildTree(all);
  }

  @override
  Future<PaginatedResult<CategorySearchItem>> searchCategories({
    required String query,
    int page = 1,
    int pageSize = 10,
    int? limit,
  }) async {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) {
      return PaginatedResult.empty(page: page, pageSize: pageSize);
    }

    final all = await databaseService.getAllCategories();
    final categoryMap = {for (final c in all) c.id: c};

    // Group direct children by parentId
    final childrenMap = <int, List<CategoryModel>>{};
    for (final c in all) {
      if (c.parentId != null) {
        childrenMap.putIfAbsent(c.parentId!, () => []).add(c);
      }
    }

    // Match all categories containing query (case-insensitive)
    final matchingCategories = all.where((c) {
      return c.name.toLowerCase().contains(trimmedQuery);
    }).toList();

    // Build rich search result items
    final searchItems = matchingCategories.map((cat) {
      final path = CategoryTreeHelper.buildPath(categoryMap, cat.id);
      final pathString = path.map((c) => c.name).join(' → ');
      final parent = cat.parentId != null ? categoryMap[cat.parentId!] : null;
      final directChildren = childrenMap[cat.id] ?? const [];

      return CategorySearchItem(
        category: cat,
        path: path,
        pathString: pathString,
        parent: parent,
        directChildren: directChildren,
      );
    }).toList();

    // If an explicit limit is provided, restrict the full result set
    final effectiveItems = limit != null && limit < searchItems.length
        ? searchItems.sublist(0, limit)
        : searchItems;

    return PaginatedResult.fromAll(
      allItems: effectiveItems,
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
    return databaseService.getPaginatedCategories(
      page: page,
      pageSize: pageSize,
      parentId: parentId,
    );
  }

  @override
  Future<void> deleteCategory(int id) async {
    await databaseService.deleteCategory(id);
  }
}
