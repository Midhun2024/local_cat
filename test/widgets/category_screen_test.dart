import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_cat/controllers/category_controller.dart';
import 'package:local_cat/data/models/category_model.dart';
import 'package:local_cat/data/models/category_search_item.dart';
import 'package:local_cat/data/models/category_tree_node.dart';
import 'package:local_cat/data/models/paginated_result.dart';
import 'package:local_cat/data/repositories/category_repository.dart';
import 'package:local_cat/views/categories/category_screen.dart';
import 'package:local_cat/views/categories/widgets/category_tree_item.dart';
import 'package:provider/provider.dart';

class MockCategoryRepository implements CategoryRepository {
  List<CategoryModel> categories = [];

  @override
  Future<CategoryModel> createCategory({
    required String name,
    int? parentId,
  }) async {
    final cat = CategoryModel(
      id: categories.length + 1,
      name: name,
      parentId: parentId,
      createdAt: DateTime.now(),
    );
    categories.add(cat);
    return cat;
  }

  @override
  Future<List<CategoryModel>> getAllCategories() async => List.from(categories);

  @override
  Future<CategoryModel?> getCategoryById(int id) async =>
      categories.where((c) => c.id == id).firstOrNull;

  @override
  Future<List<CategoryTreeNode>> getCategoryTree() async =>
      CategoryTreeHelper.buildTree(categories);

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
    final map = {for (final c in categories) c.id: c};

    final items = matching.map((c) {
      final path = CategoryTreeHelper.buildPath(map, c.id);
      return CategorySearchItem(
        category: c,
        path: path,
        pathString: path.map((e) => e.name).join(' → '),
        parent: c.parentId != null ? map[c.parentId!] : null,
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
  }) async => PaginatedResult.empty();

  @override
  Future<void> deleteCategory(int id) async {
    categories.removeWhere((c) => c.id == id);
  }
}

void main() {
  Widget createWidgetUnderTest(CategoryController controller) {
    return ChangeNotifierProvider<CategoryController>.value(
      value: controller,
      child: const MaterialApp(home: CategoryScreen()),
    );
  }

  group('CategoryScreen Widget Tests', () {
    late MockCategoryRepository mockRepo;
    late CategoryController controller;

    setUp(() {
      mockRepo = MockCategoryRepository();
      controller = CategoryController(categoryRepository: mockRepo);
    });

    testWidgets('shows empty view when no categories exist', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(controller));
      await tester.pumpAndSettle();

      expect(find.text('No Categories Yet'), findsOneWidget);
      expect(find.text('Add Root Category'), findsWidgets);
    });

    testWidgets('renders category tree and handles expand/collapse', (
      tester,
    ) async {
      mockRepo.categories.addAll([
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

      await tester.pumpWidget(createWidgetUnderTest(controller));
      await tester.pumpAndSettle();

      // Root category 'Electronics' should be displayed
      expect(find.text('Electronics'), findsOneWidget);
      expect(find.byType(CategoryTreeItem), findsOneWidget);

      // Child 'Mobile' is initially collapsed
      expect(find.text('Mobile'), findsNothing);

      // Tap expansion icon
      await tester.tap(find.byIcon(Icons.arrow_right));
      await tester.pumpAndSettle();

      // Now Mobile is visible
      expect(find.text('Mobile'), findsOneWidget);
      expect(find.byType(CategoryTreeItem), findsNWidgets(2));
    });

    testWidgets('searches hierarchy and displays breadcrumbs', (tester) async {
      mockRepo.categories.addAll([
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

      await tester.pumpWidget(createWidgetUnderTest(controller));
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'samsung');
      // Wait for debounce timer (300ms)
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Samsung'), findsOneWidget);
      expect(find.text('Electronics → Mobile → Samsung'), findsOneWidget);
      expect(find.text('Parent: Mobile'), findsOneWidget);
      expect(find.text('View in Tree'), findsOneWidget);
    });

    testWidgets('shows empty search state when no match is found', (
      tester,
    ) async {
      mockRepo.categories.addAll([
        CategoryModel(
          id: 1,
          name: 'Electronics',
          parentId: null,
          createdAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(createWidgetUnderTest(controller));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'NonExistentProduct');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('No Categories Found'), findsOneWidget);
      expect(find.text('Clear Search'), findsOneWidget);
    });
  });
}
