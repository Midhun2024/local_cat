import 'package:flutter_test/flutter_test.dart';
import 'package:local_cat/data/models/category_model.dart';
import 'package:local_cat/data/models/category_tree_node.dart';

void main() {
  group('CategoryTreeHelper & CategoryTreeNode', () {
    final now = DateTime(2026, 11, 3);

    final sampleCategories = [
      CategoryModel(id: 1, name: 'Electronics', parentId: null, createdAt: now),
      CategoryModel(id: 2, name: 'Mobile', parentId: 1, createdAt: now),
      CategoryModel(id: 3, name: 'Android', parentId: 2, createdAt: now),
      CategoryModel(id: 4, name: 'Samsung', parentId: 3, createdAt: now),
      CategoryModel(id: 5, name: 'OnePlus', parentId: 3, createdAt: now),
      CategoryModel(id: 6, name: 'Laptop', parentId: 1, createdAt: now),
      CategoryModel(id: 7, name: 'Gaming', parentId: 6, createdAt: now),
      CategoryModel(id: 8, name: 'Fashion', parentId: null, createdAt: now),
      CategoryModel(
        id: 9,
        name: 'Mobile',
        parentId: 8,
        createdAt: now,
      ), // Same name under different parent
    ];

    test('builds recursive tree with correct nesting and depth', () {
      final tree = CategoryTreeHelper.buildTree(sampleCategories);

      // Roots should be Electronics and Fashion (sorted alphabetically)
      expect(tree.length, 2);
      expect(tree[0].name, 'Electronics');
      expect(tree[0].depth, 0);
      expect(tree[1].name, 'Fashion');
      expect(tree[1].depth, 0);

      // Electronics children: Laptop, Mobile (alphabetical)
      final electronics = tree[0];
      expect(electronics.children.length, 2);
      expect(electronics.children[0].name, 'Laptop');
      expect(electronics.children[0].depth, 1);
      expect(electronics.children[1].name, 'Mobile');
      expect(electronics.children[1].depth, 1);

      // Mobile children: Android
      final mobile = electronics.children[1];
      expect(mobile.children.length, 1);
      expect(mobile.children[0].name, 'Android');
      expect(mobile.children[0].depth, 2);

      // Android children: OnePlus, Samsung
      final android = mobile.children[0];
      expect(android.children.length, 2);
      expect(android.children[0].name, 'OnePlus');
      expect(android.children[1].name, 'Samsung');
      expect(android.children[1].depth, 3);
    });

    test('generates full root-to-category path breadcrumbs accurately', () {
      final categoryMap = {for (final c in sampleCategories) c.id: c};

      final path = CategoryTreeHelper.buildPath(categoryMap, 4); // Samsung
      expect(path.map((c) => c.name).toList(), [
        'Electronics',
        'Mobile',
        'Android',
        'Samsung',
      ]);

      final pathString = CategoryTreeHelper.formatPath(categoryMap, 4);
      expect(pathString, 'Electronics → Mobile → Android → Samsung');
    });

    test('finds node by ID recursively', () {
      final tree = CategoryTreeHelper.buildTree(sampleCategories);
      final found = tree[0].findById(4); // Samsung

      expect(found, isNotNull);
      expect(found!.name, 'Samsung');
      expect(found.depth, 3);
      expect(found.pathString, 'Electronics → Mobile → Android → Samsung');
    });

    test('detects duplicate name under same parent', () {
      // Adding "mobile" under root 1 (Electronics) should be duplicate
      final isDup1 = CategoryTreeHelper.isDuplicateName(
        allCategories: sampleCategories,
        name: 'mobile', // case-insensitive
        parentId: 1,
      );
      expect(isDup1, isTrue);

      // Adding "Mobile" under root (parentId == null) where none exists yet
      final isDup2 = CategoryTreeHelper.isDuplicateName(
        allCategories: sampleCategories,
        name: 'Mobile',
        parentId: null,
      );
      expect(isDup2, isFalse);
    });

    test('allows same name under different parent', () {
      // Fashion (id: 8) already has 'Mobile', but adding 'Mobile' under Laptop (id: 6) is allowed
      final isDup = CategoryTreeHelper.isDuplicateName(
        allCategories: sampleCategories,
        name: 'Mobile',
        parentId: 6,
      );
      expect(isDup, isFalse);
    });

    test('cycle detection prevents circular ancestry', () {
      final categoryMap = {for (final c in sampleCategories) c.id: c};

      // Self parent
      expect(CategoryTreeHelper.wouldCreateCycle(categoryMap, 1, 1), isTrue);

      // Setting Electronics (1) parent to Samsung (4) would create cycle
      expect(CategoryTreeHelper.wouldCreateCycle(categoryMap, 1, 4), isTrue);

      // Setting Samsung (4) parent to Fashion (8) is safe (no cycle)
      expect(CategoryTreeHelper.wouldCreateCycle(categoryMap, 4, 8), isFalse);
    });

    test('collects descendant IDs correctly', () {
      final tree = CategoryTreeHelper.buildTree(sampleCategories);
      final electronics = tree[0];

      // Descendants of Electronics (1): Laptop (6), Gaming (7), Mobile (2), Android (3), Samsung (4), OnePlus (5)
      expect(electronics.descendantIds, {2, 3, 4, 5, 6, 7});
    });
  });
}
