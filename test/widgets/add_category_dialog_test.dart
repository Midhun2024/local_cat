import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_cat/controllers/category_controller.dart';
import 'package:local_cat/data/models/category_model.dart';
import 'package:local_cat/data/models/category_search_item.dart';
import 'package:local_cat/data/models/category_tree_node.dart';
import 'package:local_cat/data/models/paginated_result.dart';
import 'package:local_cat/data/repositories/category_repository.dart';
import 'package:local_cat/views/categories/widgets/add_category_dialog.dart';
import 'package:provider/provider.dart';

class MockCategoryRepository implements CategoryRepository {
  String? lastCreatedName;
  int? lastCreatedParentId;

  @override
  Future<CategoryModel> createCategory({
    required String name,
    int? parentId,
  }) async {
    lastCreatedName = name;
    lastCreatedParentId = parentId;
    return CategoryModel(
      id: 10,
      name: name,
      parentId: parentId,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<CategoryModel>> getAllCategories() async => [];

  @override
  Future<CategoryModel?> getCategoryById(int id) async => null;

  @override
  Future<List<CategoryTreeNode>> getCategoryTree() async => [];

  @override
  Future<PaginatedResult<CategorySearchItem>> searchCategories({
    required String query,
    int page = 1,
    int pageSize = 10,
    int? limit,
  }) async => PaginatedResult.empty();

  @override
  Future<PaginatedResult<CategoryModel>> getPaginatedCategories({
    int page = 1,
    int pageSize = 10,
    int? parentId,
  }) async => PaginatedResult.empty();

  @override
  Future<void> deleteCategory(int id) async {}
}

void main() {
  Widget createWidgetUnderTest(
    CategoryController controller, {
    CategoryModel? parent,
  }) {
    return ChangeNotifierProvider<CategoryController>.value(
      value: controller,
      child: MaterialApp(
        home: Scaffold(body: AddCategoryDialog(parentCategory: parent)),
      ),
    );
  }

  group('AddCategoryDialog Widget Tests', () {
    late MockCategoryRepository mockRepo;
    late CategoryController controller;

    setUp(() {
      mockRepo = MockCategoryRepository();
      controller = CategoryController(categoryRepository: mockRepo);
    });

    testWidgets('renders Root Category dialog correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(controller));

      expect(find.text('Add Root Category'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('validates empty input on submit', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(controller));

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Category name cannot be empty.'), findsOneWidget);
      expect(mockRepo.lastCreatedName, isNull);
    });

    testWidgets('submits root category successfully', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(controller));

      await tester.enterText(find.byType(TextFormField), '  Electronics  ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(mockRepo.lastCreatedName, 'Electronics');
      expect(mockRepo.lastCreatedParentId, isNull);
    });

    testWidgets('renders Subcategory dialog with parent name', (tester) async {
      final parent = CategoryModel(
        id: 1,
        name: 'Electronics',
        parentId: null,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(controller, parent: parent),
      );

      expect(find.text('Add Subcategory'), findsOneWidget);
      expect(find.text('Parent: Electronics'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Mobile');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(mockRepo.lastCreatedName, 'Mobile');
      expect(mockRepo.lastCreatedParentId, 1);
    });
  });
}
