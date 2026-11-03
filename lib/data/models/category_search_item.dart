import 'category_model.dart';

class CategorySearchItem {
  const CategorySearchItem({
    required this.category,
    required this.path,
    required this.pathString,
    this.parent,
    required this.directChildren,
  });

  final CategoryModel category;
  final List<CategoryModel> path;
  final String pathString;
  final CategoryModel? parent;
  final List<CategoryModel> directChildren;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategorySearchItem &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          pathString == other.pathString;

  @override
  int get hashCode => Object.hash(category, pathString);
}
