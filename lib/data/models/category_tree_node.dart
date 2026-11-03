import 'category_model.dart';
import '../../core/utils/validators.dart';

/// Represents a hierarchical node in the category tree for presentation and traversal.
class CategoryTreeNode {
  CategoryTreeNode({
    required this.category,
    List<CategoryTreeNode>? children,
    this.depth = 0,
    this.parent,
  }) : children = children ?? [];

  final CategoryModel category;
  final List<CategoryTreeNode> children;
  final int depth;
  final CategoryTreeNode? parent;

  int get id => category.id;
  String get name => category.name;
  int? get parentId => category.parentId;
  bool get hasChildren => children.isNotEmpty;

  /// Full path from root node down to this node.
  List<CategoryModel> get path {
    final result = <CategoryModel>[];
    CategoryTreeNode? current = this;
    while (current != null) {
      result.insert(0, current.category);
      current = current.parent;
    }
    return result;
  }

  /// Formatted path string, e.g. "Electronics → Mobile → Android → Samsung".
  String get pathString => path.map((c) => c.name).join(' → ');

  /// Recursively searches for a node by ID.
  CategoryTreeNode? findById(int targetId) {
    if (category.id == targetId) return this;
    for (final child in children) {
      final found = child.findById(targetId);
      if (found != null) return found;
    }
    return null;
  }

  /// Collects all descendant IDs.
  Set<int> get descendantIds {
    final ids = <int>{};
    for (final child in children) {
      ids.add(child.id);
      ids.addAll(child.descendantIds);
    }
    return ids;
  }
}

/// Helper utilities for tree building and hierarchy algorithms.
class CategoryTreeHelper {
  const CategoryTreeHelper._();

  /// Converts a flat list of category records into a hierarchical forest of root nodes.
  static List<CategoryTreeNode> buildTree(List<CategoryModel> categories) {
    final Map<int, List<CategoryModel>> childrenMap = {};
    final List<CategoryModel> rootCategories = [];

    for (final category in categories) {
      if (category.parentId == null) {
        rootCategories.add(category);
      } else {
        childrenMap.putIfAbsent(category.parentId!, () => []).add(category);
      }
    }

    // Sort roots alphabetically by name
    rootCategories.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    List<CategoryTreeNode> buildSubtree(
      CategoryModel model,
      int depth,
      CategoryTreeNode? parentNode,
    ) {
      final node = CategoryTreeNode(
        category: model,
        depth: depth,
        parent: parentNode,
      );

      final children = childrenMap[model.id] ?? [];
      // Sort children alphabetically
      children.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      for (final child in children) {
        node.children.addAll(buildSubtree(child, depth + 1, node));
      }

      return [node];
    }

    final tree = <CategoryTreeNode>[];
    for (final root in rootCategories) {
      tree.addAll(buildSubtree(root, 0, null));
    }
    return tree;
  }

  /// Builds the full ancestor path (from root to target) using a map of category models.
  static List<CategoryModel> buildPath(
    Map<int, CategoryModel> categoryMap,
    int categoryId,
  ) {
    final path = <CategoryModel>[];
    final visited = <int>{};
    int? currentId = categoryId;

    while (currentId != null) {
      if (visited.contains(currentId)) {
        // Prevent infinite loop if circular relationship exists
        break;
      }
      visited.add(currentId);

      final cat = categoryMap[currentId];
      if (cat == null) break;

      path.insert(0, cat);
      currentId = cat.parentId;
    }

    return path;
  }

  /// Formats path to string, e.g. "Electronics → Mobile → Android → Samsung".
  static String formatPath(
    Map<int, CategoryModel> categoryMap,
    int categoryId, {
    String separator = ' → ',
  }) {
    final path = buildPath(categoryMap, categoryId);
    return path.map((c) => c.name).join(separator);
  }

  /// Checks if setting [newParentId] as parent of [categoryId] would create a cycle.
  static bool wouldCreateCycle(
    Map<int, CategoryModel> categoryMap,
    int categoryId,
    int newParentId,
  ) {
    if (categoryId == newParentId) return true;

    int? currentId = newParentId;
    final visited = <int>{};

    while (currentId != null) {
      if (currentId == categoryId) return true;
      if (visited.contains(currentId)) break;
      visited.add(currentId);
      currentId = categoryMap[currentId]?.parentId;
    }

    return false;
  }

  /// Checks if a category name already exists among siblings (same parent).
  static bool isDuplicateName({
    required List<CategoryModel> allCategories,
    required String name,
    int? parentId,
    int? excludeId,
  }) {
    final normalized = Validators.normalizeCategoryName(name);

    for (final cat in allCategories) {
      if (excludeId != null && cat.id == excludeId) continue;
      if (cat.parentId == parentId) {
        if (Validators.normalizeCategoryName(cat.name) == normalized) {
          return true;
        }
      }
    }
    return false;
  }
}
