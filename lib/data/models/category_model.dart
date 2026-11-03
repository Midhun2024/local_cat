import '../../core/constants/database_constants.dart';
import '../../core/utils/date_time_utils.dart';

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.parentId,
    required this.createdAt,
  });

  final int id;
  final String name;
  final int? parentId;
  final DateTime createdAt;

  bool get isRoot => parentId == null;

  CategoryModel copyWith({
    int? id,
    String? name,
    int? parentId,
    bool clearParent = false,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: clearParent ? null : (parentId ?? this.parentId),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map[DatabaseConstants.columnId] as int,
      name: map[DatabaseConstants.columnName] as String,
      parentId: map[DatabaseConstants.columnParentId] as int?,
      createdAt: DateTimeUtils.parseIso8601(
        map[DatabaseConstants.columnCreatedAt] as String?,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id > 0) DatabaseConstants.columnId: id,
      DatabaseConstants.columnName: name,
      DatabaseConstants.columnParentId: parentId,
      DatabaseConstants.columnCreatedAt: DateTimeUtils.toIso8601(createdAt),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          parentId == other.parentId &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, name, parentId, createdAt);

  @override
  String toString() =>
      'CategoryModel(id: $id, name: "$name", parentId: $parentId, createdAt: $createdAt)';
}
